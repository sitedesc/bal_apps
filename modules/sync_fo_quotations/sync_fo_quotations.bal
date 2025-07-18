import ballerina/http;
import ballerina/log;
import ballerina/task;
import cosmobilis/fo_db as fodb;
import ballerinax/mysql;


type TeamsConf record {
    string webhookUrl;
    string channelId;
    string apiKey;
};



configurable TeamsConf teams = ?;
configurable string boApiUrl = ?;
configurable string boApiSecret = ?;

// === SCHEDULER INITIALISATION ===
public function createSyncFoQuotationJob() returns task:JobId|error {
    SyncFoQuotationJob myJob = check new (teams, boApiUrl, boApiSecret);
    return task:scheduleJobRecurByFrequency(myJob, 300);
}

class SyncFoQuotationJob {
    *task:Job;
    TeamsConf teams;
    map<string> headers;
    map<string> headersTeams;
    mysql:Client foDb;
    http:Client boClient;

    function init(TeamsConf teamsConf, string boApiUrl, string boApiSecret) returns error? {
        self.foDb = check fodb:getDbClient();
        self.teams = teamsConf;
        byte[] boApiSecretBytes = boApiSecret.toBytes();
        self.headers = {
            "Authorization": boApiSecretBytes.toBase64(),
            "Content-Type": "application/json"
        };
        self.headersTeams = {
            "x-api-key": self.teams.apiKey
        };
        self.boClient = check new (boApiUrl, {timeout: 180});
    }

    // === SCHEDULED EXECUTION FUNCTIONS ===
    public function execute() {
        do {
            log:printInfo("⏱️ Job planifié : exécution de scheduledRun()");
            var result = self.scheduledRun();
            if result is error {
                string msg = "❌ scheduledRun() a échoué : " + result.message();
                log:printError(msg, result);
                // Envoi d'une notification Teams en cas d'erreur
                var notif = self.sendTeamsNotification("Erreur exécution job sync_fo_quotation", msg, [{"Type d'exécution": "Tâche planifiée"}]);
                if notif is error {
                    log:printError("Échec d'envoi Teams", notif);
                }
            }
        } on fail var failure {
            log:printError("Unmanaged error", failure);
        }
    }

    function scheduledRun() returns error? {
        fodb:Quotation[] quotations = check fodb:getQuotations(self.foDb);
        foreach fodb:Quotation quotation in quotations {
            log:printDebug(quotation.toString());
            json response = check self.boClient->post("/api/v1/devis/notify", quotation.content,self.headers);
            _ = check fodb:setQuotationState(self.foDb, quotation, fodb:SYNC_STATE.DONE);
        }
    }


    // === TEAMS NOTIF ===
    function sendTeamsNotification(string title, string description, map<string>[] list) returns error? {
        http:Client teamsClient = check new (self.teams.webhookUrl);
        json payload = {
            title: title,
            description: description,
            channel_id: self.teams.channelId,
            list: []
        };

        // Envoi réel de la notification via POST
        http:Response response = check teamsClient->post("", payload, self.headersTeams);
        int statusCode = response.statusCode;
        if (statusCode != 200) {
            string content = check response.getTextPayload();
            log:printError("Échec de notification Teams. Code: " + statusCode.toString() + ", Message: " + content);
        } else {
            log:printInfo("Notification Teams envoyée avec succès.");
        }
    }

}

// === WORKAROUND SERVICE (WILL BECOME A JOBS ADMIN SERVICE) ===
service http:Service / on new http:Listener(9876) {
resource function get health() returns string {
       return "this is a workaround to keep the script live sothat the scheduled job can run...";
    }
}