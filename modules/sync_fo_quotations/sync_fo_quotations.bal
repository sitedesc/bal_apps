import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/os;
import ballerina/task;

import cosmobilis/fo_db as fodb;

type TeamsConf record {
    string webhookUrl;
    string channelId;
    string apiKey;
};

type Conf record {
string boApiUrl;
string boApiSecret;
};

configurable TeamsConf teams = ?;
configurable Conf conf = ?;


// === SCHEDULER INITIALISATION ===
public function createSyncFoQuotationJob() returns task:JobId|error {
    SyncFoQuotationJob myJob = check new (teams, conf.boApiUrl, conf.boApiSecret);
    return task:scheduleJobRecurByFrequency(myJob, 180);
}

//TODO: refactor logging and teams notif code in this class: 
// - externalize teams code in a dedicated package
// - externalize logging code in a dedicated pkg integrating teams pkg.
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
        lock {
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
    }

    function scheduledRun() returns error? {
        xml messageList = check fodb:getQuotationMsgs();
        while (messageList/*).length() > 0 {
            foreach xml msgElem in messageList/* {
                do {
                    log:printDebug(msgElem.toString());
                    string id = check (msgElem/<id>[0]/*[0]).toString();
                    if id.length() <= 0 {
                        continue;
                    }
                    log:printDebug(string `${id}`);
                    string msgJson = (msgElem/<message>[0]/*[0]).toString();
                    _ = check io:fileWriteString("/tmp/quotation.json", msgJson);
                    // Envoyer le JSON comme corps HTTP, etc.
                    log:printDebug(msgJson);

                    string curlCmd = string `curl -X POST ${conf.boApiUrl}/api/v1/devis/notify \
  -u ${conf.boApiSecret} \
  -H "Content-Type: application/json" \
  --data @/tmp/quotation.json`;
                    _ = check io:fileWriteString("/tmp/curl_post_quotation", curlCmd);
                    os:Process process = check os:exec({
                                                           value: "runSh.sh",
                                                           arguments: ["/tmp/curl_post_quotation"]
                                                       });
                    _ = check process.waitForExit();

                    string stdout = check string:fromBytes(check process.output());
                    int|error devisId = int:fromString(stdout);
                    if devisId is error {
                        var notif = self.sendTeamsNotification(
                                        "Erreur exécution job sync_fo_quotation for a quotation",
                                        string `The upload of the quotation message : ID " + id + ", did not return the id of the created quotation, but returned: ${stdout}
                                        `,
                                        [{"Type d'exécution": "Tâche planifiée"}]);
                        log:printError("The upload of the quotation message : ID " + id + ", did not return the id of the created quotation, but returned:" + stdout);
                        check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.ERROR, stdout);
                        if notif is error {
                            log:printError("Échec d'envoi Teams", notif);
                        }

                        continue;
                    }

                    log:printInfo("Quotation submission response:" + stdout);

                    check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.DONE, stdout);
                    log:printInfo(string `quotation message ID ${id} sent to BO.`);
                } on fail var failure {
                    var notif = self.sendTeamsNotification(
                                        "Erreur exécution job sync_fo_quotation for a quotation",
                                        string `${failure.toString()}
                                        devis:
                                        ${msgElem.toString()}`,
                                        [{"Type d'exécution": "Tâche planifiée"}]);
                    log:printError("Erreur exécution job sync_fo_quotation for quotation:" + msgElem.toString(), failure);
                    if notif is error {
                        log:printError("Échec d'envoi Teams", notif);
                    }
                }
            }
            messageList = check fodb:getQuotationMsgs();
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
