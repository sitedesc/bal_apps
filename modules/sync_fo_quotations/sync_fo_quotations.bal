import ballerina/data.jsondata;
import ballerina/http;
//import ballerina/io;
import ballerina/log;
//import ballerina/os;
import ballerina/task;

import cosmobilis/bo_db as bodb;
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

type BoApiErrorDetail record {
    int code;
    string message;
};

type BoApiError record {
    BoApiErrorDetail 'error;
};

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
        string id = "";
        while (messageList/*).length() > 0 {
            foreach xml msgElem in messageList/* {
                do {
                    log:printDebug(msgElem.toString());
                    id = (msgElem/<id>[0]/*[0]).toString();
                    if id.length() <= 0 {
                        continue;
                    }
                    log:printDebug(string `${id}`);
                    string msgJson = (msgElem/<message>[0]/*[0]).toString();
                    json msg = check jsondata:parseString(msgJson);
                    string numero = (check jsondata:read(msg, `$.reference`)).toString();
                    if numero is "" {
                        string description = string `cannot process a quotation : ID ${id} because it has no reference.`;
                        _ = check self.sendTeamsNotification(
                                        "Erreur exécution job sync_fo_quotation for a quotation",
                                        description,
                                        [{"Type d'exécution": "Tâche planifiée"}]);
                        log:printError(description);
                        check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.ERROR, description);
                        id = "";
                        continue;
                    }
                    bodb:QuotationCriterias criterias = {numero: numero};
                    if check bodb:existQuotations(criterias) {
                        check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.DONE, "a quotation with numero equal to the message reference already exists.");
                        id = "";
                        continue;
                    }

                    // Envoi du POST vers /notify
                    http:Response response = check self.boClient->post("/api/v1/devis/notify", msg);
                    string body = check response.getTextPayload();
                    json|error converted = body.fromJsonString();
                    if (converted is error) {
                        
                        if containsKeywords(body, "504", "Time-out") {
                            if check bodb:existQuotations(criterias) {
                                check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.DONE, "couldn't retrieve quotation number because of quotation upload timeout.");
                                id = "";
                                continue;
                            }
                        }

                        string description = string `The upload of the quotation message : ID ${id}, did not return the id of the created quotation, but returned: ${body}
                                        `;
                        var notif = self.sendTeamsNotification(
                                        "Erreur exécution job sync_fo_quotation for a quotation",
                                        description,
                                        [{"Type d'exécution": "Tâche planifiée"}]);
                        log:printError(description);
                        check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.ERROR, body);
                        if notif is error {
                            log:printError("Échec d'envoi Teams", notif);
                        }
                        id = "";
                        continue;
                    } else {
                        int|error intValue = converted.cloneWithType();
                        BoApiError|error errorValue = converted.cloneWithType();
                        if !(intValue is error) {
                            log:printInfo("Quotation submission response:" + body);
                            check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.DONE, body);
                            log:printInfo(string `quotation message ID ${id} sent to BO.`);
                            id = "";
                        } else if !(errorValue is error) && errorValue.'error.code == 504 {
                            if check bodb:existQuotations(criterias) {
                                check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.DONE, "couldn't retrieve quotation number because of quotation upload timeout.");
                                id = "";
                                continue;
                            }
                        } else {
                            string description = string `The upload of the quotation message : ID ${id}, did not return the id of the created quotation, but returned: ${body}
                                        `;
                            var notif = self.sendTeamsNotification(
                                        "Erreur exécution job sync_fo_quotation for a quotation",
                                        description,
                                        [{"Type d'exécution": "Tâche planifiée"}]);
                            log:printError(description);
                            check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.ERROR, body);
                            if notif is error {
                                log:printError("Échec d'envoi Teams", notif);
                            }
                            id = "";
                            continue;
                        }
                    }

                    // Envoi du POST vers /notify
                    //                     _ = check io:fileWriteString("/tmp/quotation.json", msgJson);
                    //                     // Envoyer le JSON comme corps HTTP, etc.
                    //                     log:printDebug(msgJson);

                    //                     string curlCmd = string `curl -X POST ${conf.boApiUrl}/api/v1/devis/notify \
                    //   -u ${conf.boApiSecret} \
                    //   -H "Content-Type: application/json" \
                    //   --data @/tmp/quotation.json`;
                    //                     _ = check io:fileWriteString("/tmp/curl_post_quotation", curlCmd);
                    //                     os:Process process = check os:exec({
                    //                                                            value: "runSh.sh",
                    //                                                            arguments: ["/tmp/curl_post_quotation"]
                    //                                                        });
                    //                     _ = check process.waitForExit();

                    //                     string stdout = check string:fromBytes(check process.output());

                    //                     int|error devisId = error("No devisId retrieved");
                    //                     if containsKeywords(stdout, "504", "Time-out") {
                    //                         if check bodb:existQuotations(criterias) {
                    //                             check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.DONE, "couldn't retrieve quotation number because of quotation upload timeout.");
                    //                             id = "";
                    //                             continue;
                    //                         }
                    //                     }
                    //                     devisId = int:fromString(stdout);
                    //                     if devisId is error {
                    //                         string description = string `The upload of the quotation message : ID ${id}, did not return the id of the created quotation, but returned: ${stdout}
                    //                                         `;
                    //                         var notif = self.sendTeamsNotification(
                    //                                         "Erreur exécution job sync_fo_quotation for a quotation",
                    //                                         description,
                    //                                         [{"Type d'exécution": "Tâche planifiée"}]);
                    //                         log:printError(description);
                    //                         check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.ERROR, stdout);
                    //                         if notif is error {
                    //                             log:printError("Échec d'envoi Teams", notif);
                    //                         }
                    //                         id = "";
                    //                         continue;
                    //                     }

                    //                     log:printInfo("Quotation submission response:" + stdout);

                    //                     check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.DONE, stdout);
                    //                     log:printInfo(string `quotation message ID ${id} sent to BO.`);
                    //                     id = "";

                } on fail var failure {
                    string title = id.length() > 0 ? string `Erreur exécution job sync_fo_quotation for quotation : ID ${id}`
                        : "Erreur exécution job sync_fo_quotation for a quotation";
                    if id.length() > 0 {
                        check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.ERROR, failure.toString());
                    }
                    var notif = self.sendTeamsNotification(
                                        title,
                                        string `${failure.toString()}
                                        devis:
                                        ${msgElem.toString()}`,
                                        [{"Type d'exécution": "Tâche planifiée"}]);
                    log:printError("Erreur exécution job sync_fo_quotation for quotation:" + msgElem.toString(), failure);
                    if notif is error {
                        log:printError(`Teams notification send error:
                        ${notif.toString()}
                        while trying to send message: 
                        ${failure.toString()}`);
                    }
                    if id.length() <= 0 {
                        continue;
                    } else {
                        id = "";
                    }
                }
            }
            id = "";
            messageList = check fodb:getQuotationMsgs();
        }

        messageList = check fodb:getQuotationMsgsInError();
        id = "";
        while (messageList/*).length() > 0 {
            foreach xml msgElem in messageList/* {
                do {
                    log:printDebug(msgElem.toString());
                    id = (msgElem/<id>[0]/*[0]).toString();
                    if id.length() <= 0 {
                        continue;
                    }
                    log:printDebug(string `${id}`);
                    string msgJson = (msgElem/<message>[0]/*[0]).toString();
                    json msg = check jsondata:parseString(msgJson);
                    string numero = (check jsondata:read(msg, `$.reference`)).toString();
                    if numero is "" {
                        string description = string `cannot process a quotation in error: ID ${id} because it has no reference.`;
                        log:printError(description);
                        id = "";
                        continue;
                    }
                    bodb:QuotationCriterias criterias = {numero: numero};
                    if check bodb:existQuotations(criterias) {
                        check fodb:setQuotationMsgState(id, fodb:SYNC_STATE.DONE, "a quotation with numero equal to the message reference already exists.");
                        id = "";
                        continue;
                    }
                } on fail var failure {
                    log:printError("Erreur job sync_fo_quotation for quotation in error:" + msgElem.toString(), failure);
                    check fodb:setQuotationMsgState(id, 3, failure.toString());
                    id = "";
                }
            }
            id = "";
            messageList = check fodb:getQuotationMsgsInError();
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

isolated function containsKeywords(string input, string keyword1, string keyword2) returns boolean {
    string lowerInput = string:toLowerAscii(input);
    string lowerKeyword1 = string:toLowerAscii(keyword1);
    string lowerKeyword2 = string:toLowerAscii(keyword2);

    boolean hasKeyword1 = string:includes(lowerInput, lowerKeyword1);
    boolean hasKeyword2 = string:includes(lowerInput, lowerKeyword2);

    return hasKeyword1 && hasKeyword2;
}
