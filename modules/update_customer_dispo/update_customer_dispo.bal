import ballerina/file;
import ballerina/http;
import ballerina/io;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/task;

// === CONFIG STRUCTURES ===

type AlgoliaConf record {
    string appId;
    string apiKey;
    string[] indexNames;
};

type TeamsConf record {
    string webhookUrl;
    string channelId;
    string apiKey;
};

type CustomerDispoConf record {
    boolean dryRun;
    boolean dryRunNotify;
};

// === CONFIGURABLE VALUES ===

configurable AlgoliaConf algolia = ?;
configurable TeamsConf teams = ?;
configurable CustomerDispoConf customerDispo = ?;

const int BATCH_SIZE = 10000;
const string STATE_FILE_SUFFIX = "last_customerDispo_update.txt";

// === STATE FILE ===

function getLastRunTimestamp(string indexName) returns string?|error {
    boolean readable = false;
    string stateFile = indexName + "_" + STATE_FILE_SUFFIX;
    do {
        readable = check file:test(stateFile, file:EXISTS) && check file:test(stateFile, file:READABLE);
    } on fail {
        readable = false;
    }
    if readable {
        return check io:fileReadString(stateFile);
    }
    return ();
}

function saveTimestamp(string ts, string indexName) returns error? {
    string stateFile = indexName + "_" + STATE_FILE_SUFFIX;
    check io:fileWriteString(stateFile, ts);
}

// === SCHEDULER INITIALISATION ===
public function createCustomerDispoJob() returns task:JobId|error {
    CustomerDispoJob myJob = new (algolia, teams, customerDispo);
    return task:scheduleJobRecurByFrequency(myJob, 300);
}

class CustomerDispoJob {
    *task:Job;
    AlgoliaConf algolia;
    TeamsConf teams;
    CustomerDispoConf customerDispo;
    string algoliaUrl;
    map<string> headers;
    map<string> headersTeams;
    map<int?> loyers = {};

    function init(AlgoliaConf algoliaConf, TeamsConf teamsConf, CustomerDispoConf dispoConf) {
        self.algolia = algoliaConf;
        self.teams = teamsConf;
        self.customerDispo = dispoConf;
        self.algoliaUrl = "https://" + self.algolia.appId + "-dsn.algolia.net";
        self.headers = {
            "X-Algolia-API-Key": self.algolia.apiKey,
            "X-Algolia-Application-Id": self.algolia.appId,
            "Content-Type": "application/json"
        };
        self.headersTeams = {
            "x-api-key": self.teams.apiKey,
            "X-Algolia-Application-Id": self.algolia.appId
        };
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
                    var notif = self.sendTeamsNotification("Erreur exécution customerDispo", msg, [{"Type d'exécution": "Tâche planifiée"}]);
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
        http:Client algoliaClient = check new (self.algoliaUrl);

        foreach string indexName in self.algolia.indexNames {
            string? lastRun = check getLastRunTimestamp(indexName);
            log:printInfo("Last run timestamp of " + indexName + ": " + (lastRun ?: "none"));

            map<json> logData = check algoliaClient->get("/1/logs?length=" + BATCH_SIZE.toString() + "&type=update", self.headers);
            //map<json> logData = check (check logRes.getJsonPayload()).cloneWithType();
            json logsJson = logData["logs"];
            string? latestMoveTimestamp = ();
            if logsJson is json[] {
                map<json>[] logs = check logsJson.cloneWithType();
                foreach map<json> logEntry in logs {
                    (string|error)? queryString = logEntry["query_body"].cloneWithType();
                    (json|error)? query = ();
                    if queryString is string {
                        query = queryString.fromJsonString();
                    }
                    if query is map<json> && query["operation"] is string && query["operation"] == "move"
                    && query["destination"] is string && query["destination"] == indexName
                    {
                        string ts = "";
                        if logEntry["timestamp"] is string {
                            ts = check logEntry["timestamp"].cloneWithType();
                        }
                        if latestMoveTimestamp is () || ts > latestMoveTimestamp {
                            latestMoveTimestamp = ts;
                        }
                    }
                }

                if latestMoveTimestamp is () {
                    log:printInfo("No move detected for index " + indexName + ".");
                    return;
                }

                log:printInfo("Latest move detected  for index " + indexName + " at: " + latestMoveTimestamp);

                if lastRun is () || latestMoveTimestamp > lastRun {
                    log:printInfo("Triggering customerDispo update  for index " + indexName + " (dryRun=" + self.customerDispo.dryRun.toString() + ")...");
                    var result = self.updateCustomerDispo(algoliaClient, indexName);
                    if (result is error) {
                        string errMsg = "Erreur lors de l'update customerDispo: " + result.message() + "dans l'index " + indexName;
                        log:printError(errMsg);
                        // Envoi de notification Teams pour l'erreur
                        check self.sendTeamsNotification("Erreur Update customerDispo", errMsg, [{"Algolia index": indexName}]);
                    } else {
                        log:printInfo("Mise à jour customerDispo dans index " + indexName + " effectuée avec succès.");
                    }
                    if !self.customerDispo.dryRun {
                        check saveTimestamp(latestMoveTimestamp, indexName);
                    }
                } else {
                    log:printInfo("No update needed for index " + indexName + ".");
                }
            } else {
                return error("Expected logs to be an array");
            }
        }
    }

    // === CUSTOMER DISPO BUSNESS LOGIC FUNTION ===
    public function updateCustomerDispo(http:Client algoliaClient, string indexName) returns error? {
        string cursor = "";
        json browseBody = {};
        boolean hasMore = true;
        int totalUpdated = 0;
        while hasMore {
            string url = "/1/indexes/" + indexName + "/browse";
            if cursor != "" {
                browseBody = {
                    cursor: cursor
                };
            }

            int browseAttempts = 0;
            int maxBrowseRetries = 5;
            http:Response|error res = error("init");
            // Retry loop pour browse
            while browseAttempts < maxBrowseRetries {
                res = algoliaClient->post(url, browseBody, self.headers);
                if res is error || res.statusCode >= 400 {
                    browseAttempts += 1;
                    runtime:sleep(5);
                    continue;
                } else {
                    browseAttempts = maxBrowseRetries;
                }
            }
            if res is error {
                return error(res.message());
            }
            map<json> body = check (check res.getJsonPayload()).cloneWithType();

            json[] hits = [];
            if body["hits"] is json[] {
                hits = check body["hits"].cloneWithType();
                log:printInfo("retrieved " + hits.length().toString() + " offers in index " + indexName + "...");
            } else {
                log:printInfo("did no retrieve any hit int this reponse of index " + indexName + ":" + body.toString());
            }
            string cursorVal = "";
            if body["cursor"] is string {
                cursorVal = check body["cursor"].cloneWithType();
            }
            log:printInfo("cursor value is: " + cursorVal);
            cursor = cursorVal;
            hasMore = cursor != "null" && cursor.length() > 0;

            json[] updates = [];

            foreach json hit in hits {
                string id = "";
                int? nature = ();
                string dispo = "";

                if hit is map<json>
                {
                    if hit["objectID"] is string {
                        id = check hit["objectID"].cloneWithType();
                    }
                    if hit["nature"] is int {
                        nature = check hit["nature"].cloneWithType();
                    }
                    if hit["disponibiliteForFO"] is string {
                        dispo = check hit["disponibiliteForFO"].cloneWithType();
                    }
                    if hit["loyers"] is json[] && (<json[]>hit["loyers"]).length() > 0 {
                        foreach json item in <json[]>hit["loyers"] {
                            map<json> loyerDatas = check item.cloneWithType();
                            string idLoyer = (check loyerDatas["id"].cloneWithType(int)).toString();
                            self.loyers[idLoyer] = nature;
                        }
                    }
                }
                if id == "" || dispo == "" { // for update test on a single offre, add this condition with a proper offer id: || id != "240314"
                    continue;
                }

                // this gets nature of the offer from a previously processed index if not present in the currently processed index
                if indexName.indexOf("LOYERS") > 0 && nature is () && self.loyers[id] is int {
                    nature = self.loyers[id];
                }

                if nature is () {
                    log:printInfo(`no nature value for object ${id} of ${indexName}.`);
                } else {
                    log:printDebug(`nature value is ${nature} for object ${id} of ${indexName}.`);
                }

                string customerDispoValue = (nature != 1 && nature != 5 && dispo == "en stock") ? "disponible" : dispo;

                json update = {
                    action: "partialUpdateObject",
                    body: {
                        objectID: id,
                        customerDispo: customerDispoValue
                    }
                };
                updates.push(update);
            }

            if updates.length() > 0 {
                if !self.customerDispo.dryRun {
                    json batchPayload = {requests: updates};
                    http:Response|error response = algoliaClient->post("/1/indexes/" + indexName + "/batch", batchPayload, self.headers);
                    if response is error {
                        string errMsg = "Erreur lors de l'update customerDispo: " + response.message() + "dans l'index " + indexName;
                        log:printError(errMsg);
                        // Envoi de notification Teams pour l'erreur
                        check self.sendTeamsNotification("Erreur Update customerDispo", errMsg, [{"Algolia index": indexName}]);
                    }
                    log:printInfo("Updated " + updates.length().toString() + " records in index " + indexName + ".");
                } else {
                    log:printInfo("Dry-run: simulated update of " + updates.length().toString() + " records in index " + indexName + ".");
                }
                totalUpdated += updates.length();
            }

            runtime:sleep(1);
        }

        log:printInfo("customerDispo update finished for index " + indexName + ".");

        if self.customerDispo.dryRun && self.customerDispo.dryRunNotify {
            string msg = "**[Dry-run OK]** Mise à jour customerDispo simulée sur " + totalUpdated.toString() + " enregistrements.";
            check self.sendTeamsNotification("Update customer dispo dry-run", msg, [{"Algolia index": indexName}]);
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
