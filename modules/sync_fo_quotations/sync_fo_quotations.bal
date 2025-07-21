import ballerina/http;
import ballerina/log;
import ballerina/task;

import cosmobilis/fo_db as fodb;

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
    http:Client boClient;

    function init(TeamsConf teamsConf, string boApiUrl, string boApiSecret) returns error? {
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
        xml messageList = check fodb:getQuotationMsgs();
        foreach xml msgElem in messageList/* {
            do {
                log:printDebug(msgElem.toString());
                int id = check int:fromString((msgElem/<id>[0]/*[0]).toString());
                log:printDebug(string `${id}`);
                string msgJson = (msgElem/<message>[0]/*[0]).toString();
                // Envoyer le JSON comme corps HTTP, etc.
                log:printDebug(msgJson);
                json response = check self.boClient->post("/api/v1/devis/notify", msgJson,self.headers);
                check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.DONE);
                log:printInfo(string `quotation message ID ${id} sent to BO.`);
            } on fail var failure {
                var notif = self.sendTeamsNotification(
                                        "Erreur exécution job sync_fo_quotation for a quotation", 
                                        failure.toString() + "\n quotation: \n" + msgElem.toString(), 
                                        [{"Type d'exécution": "Tâche planifiée"}]);
                check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.ERROR);
                log:printError("Erreur exécution job sync_fo_quotation for quotation:\n" + msgElem.toString(), failure);
                if notif is error {
                    log:printError("Échec d'envoi Teams", notif);
                }
            }
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
