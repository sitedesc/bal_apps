import ballerina/http;
import ballerina/log;
import ballerina/task;
import ballerina/time;
import ballerina/uuid;

import cosmobilis/postgres_db as db;
import cosmobilis/teams;

type Conf record {
    string appId;
    string apiKey;
    map<string> indexNames;
    # for test: if dryRun then temporary index is created but does not replace the master index.
    boolean dryRun = true;
};

configurable Conf conf = ?;

public function createAlgoliaIndexJob() returns task:JobId|error {
    AlgoliaIndexJob myJob = new;
    return task:scheduleJobRecurByFrequency(myJob, 15 * 60);
}

class AlgoliaIndexJob {
    *task:Job;

    public function execute() {
        lock {
            db:JobDates|error jobDates = db:getJobDates();
            if jobDates is error {
                var notif = teams:sendTeamsNotification("INDEXATION JOB DATES ERROR", jobDates.message(), [{"Type d'exécution": "Tâche planifiée"}]);
                if notif is error {
                    log:printError(`Teams INDEXATION JOB DATES notification ERROR: ${notif.message()}`);
                }
                log:printError("INDEXATION JOB DATES ERROR", jobDates);
                return;
            }
            time:Utc? lastIndexation = (<db:JobDates>jobDates).last_indexation;
            do {

                if conf.dryRun {
                    log:printInfo("Mode DRY RUN activé - L'index temporaire ne remplacera PAS l'index master.");
                }
                if (check db:isDbRefreshMoreRecent()) {
                    _ = check db:updateLastIndexation();

                    //Indexation start notification
                    string startMsg = string `${<string>conf.indexNames["offres"]} and ${<string>conf.indexNames["loyers"]}`;
                    if teams:sendTeamsNotification(startMsg, "indexes update started...", [{"Type d'exécution": "Tâche planifiée"}]) is error {
                        log:printError(string `Teams indexation start notification failed.`);
                    } else {
                        log:printInfo(startMsg + ": indexes update started...");
                    }

                    // Indexation des Offres dans nouvel index temporaire
                    string tmpOfferIndex = check self.indexEntity("offres", conf.indexNames["offres"]);
                    // Indexation des Loyers dans nouvel index temporaire
                    string tmpLoyerIndex = check self.indexEntity("loyers", conf.indexNames["loyers"]);
                    // Remplacement des index master par les nouveaux index temporaires
                    check self.moveIndex(tmpOfferIndex, <string>conf.indexNames["offres"]);
                    check self.moveIndex(tmpLoyerIndex, <string>conf.indexNames["loyers"]);

                    //Indexation end notification
                    string endMsg = string `${<string>conf.indexNames["offres"]} and ${<string>conf.indexNames["loyers"]}`;
                    if teams:sendTeamsNotification(endMsg, "indexes update completed.", [{"Type d'exécution": "Tâche planifiée"}]) is error {
                        log:printError(string `Teams indexation completion notification failed.`);
                    } else {
                        log:printInfo(endMsg + ": indexes update completed.");
                    }
                }
            } on fail var failure {
                log:printError("Unmanaged error", failure);
                any|error status = db:updateLastIndexation(lastIndexation);
                if status is error {
                    log:printError("couldn't rollback lastIndex date: ", status);
                }
            }
        }
    }

    // Fonction pour indexer une entité avec pagination par lots de 1000 records
    function indexEntity(string entityName, string? srcIndex) returns string|error {
        log:printDebug(`indexEntity params: ${entityName}, ${srcIndex}`);
        if srcIndex is () {
            return error(string `No target index given to index ${entityName}`);
        }
        // Création d'un index temporaire
        string tmpIndex = srcIndex + "_tmp_" + uuid:createType1AsString();

        // Copie des paramètres depuis l'index source
        check self.copySettingsAndRules(srcIndex, tmpIndex);

        // Récupération du stream depuis la DB
        stream<db:Offre|db:Loyer, error?> resultStream;
        if entityName == "offres" {
            log:printDebug(`getting offres stream...`);
            resultStream = <stream<db:Offre|db:Loyer, error?>>db:getOffres();
        } else if entityName == "loyers" {
            resultStream = <stream<db:Offre|db:Loyer, error?>>db:getLoyers();
        } else {
            return error("Entité inconnue : " + entityName);
        }

        // Tableau pour stocker les lots de 1000 records
        json[] batch = [];
        int batchSize = 1000;
        int batchCount = 0;

        // Itération sur le stream et gestion des lots
        check from db:Offre|db:Loyer row in resultStream
            do {
                // Conversion de la ligne en JSON
                db:Offre|db:Loyer 'record = check row.toJson().cloneWithType();
                //ajout de champ calculés
                self.addCalculatedFields('record);
                log:printDebug(`pushing in batch record: ${'record.toJsonString()}`);
                json addObject = {
                    action: "addObject",
                    body: 'record.toJson()
                };

                batch.push(addObject);

                // Si le lot atteint 1000 records, on l'envoie à Algolia
                if batch.length() == batchSize {
                    check self.saveObjects(tmpIndex, batch);
                    log:printInfo(string `Indexed batch ${batchCount + 1} (${batchSize} records) into ${tmpIndex}`);
                    batch = [];
                    batchCount += 1;
                }
            };

        // Envoi du dernier lot si nécessaire
        if batch.length() > 0 {
            check self.saveObjects(tmpIndex, batch);
            log:printInfo(string `Indexed batch ${batchCount + 1} (${batch.length()} records) into ${tmpIndex}`);
        }
        return tmpIndex;
    }

    function copySettingsAndRules(string srcIndex, string tmpIndex) returns error? {
        log:printInfo(`in copySettingsAndRules with params ${srcIndex}, ${tmpIndex}`);
        http:FailoverClient algoliaClient = check self.getAlgoliaClient();
        map<string> headers = {
            "X-Algolia-API-Key": conf.apiKey,
            "X-Algolia-Application-Id": conf.appId
        };
        log:printInfo(`running post route /1/indexes/${srcIndex}/operation ...`);
        json body = {
            "operation": "copy",
            "destination": tmpIndex,
            "scope": [
                "settings",
                "rules"
            ]
        };
        http:Response resp = check algoliaClient->post("/1/indexes/" + srcIndex + "/operation", body, headers);
        log:printInfo(`in copySettingsAndRules response of post route /1/indexes/${srcIndex}/operation: status: ${resp.statusCode}, body: ${check resp.getTextPayload()}`);

    }

    function saveObjects(string index, json[] objects) returns error? {
        log:printInfo(`in saveObjects...`);
        http:FailoverClient algoliaClient = check self.getAlgoliaClient();
        map<string> headers = {
            "X-Algolia-API-Key": conf.apiKey,
            "X-Algolia-Application-Id": conf.appId,
            "Content-Type": "application/json"
        };
        json batchPayload = {requests: objects};
        http:Response resp = check algoliaClient->post("/1/indexes/" + index + "/batch", batchPayload, headers);
        log:printInfo(`response of post route /1/indexes/${index}/batch: status: ${resp.statusCode}`);
    }

    function moveIndex(string tmpIndex, string srcIndex) returns error? {
        log:printInfo(`in moveIndex with params ${tmpIndex}, ${srcIndex}`);
        if !conf.dryRun {
            http:FailoverClient algoliaClient = check self.getAlgoliaClient();
            map<string> headers = {
                "X-Algolia-API-Key": conf.apiKey,
                "X-Algolia-Application-Id": conf.appId
            };
            map<string> payload = {
                "operation": "move",
                "destination": srcIndex
            };
            http:Response resp = check algoliaClient->post("/1/indexes/" + tmpIndex + "/operation", payload, headers);
            log:printInfo(`in moveIndex response of post route /1/indexes/${tmpIndex}/batch: status: ${resp.statusCode}, body: ${check resp.getTextPayload()}`);
        }
    }

    function getAlgoliaClient() returns http:FailoverClient|error {
        return new ({
            timeout: 180,
            // d'après la litterature ballerina, ce qui est retryé via cette conf:
            //Timeout, Connexion refusée, Autres erreurs de transport, erreurs status code 5xx
            retryConfig: {
                interval: 5, // délai en secondes entre 2 tentatives
                count: 4, // nombre d’essais total max (incluant donc la tentative initiale)
                backOffFactor: 2.0 // backoff exponentiel qui multiplie le délai à chaque tentative, donc 5s pour la 1ere, puis 2x5s pour la seonde, puis 2x2X5s pour la 3eme
            },
            failoverCodes: [400, 500, 502, 503, 504], // codes qui déclenchent failover, pas le retry
            interval: 3, // délai entre 2 endpoints si failover
            targets: [
                {url: "https://" + conf.appId + "-dsn.algolia.net"},
                {url: "https://" + conf.appId + "-1.algolianet.com"},
                {url: "https://" + conf.appId + "-2.algolianet.com"},
                {url: "https://" + conf.appId + "-3.algolianet.com"}
            ]
        });
    }

    function addCalculatedFields(db:Offre|db:Loyer 'record) {

        'record["proxautoLabel"] =
            'record.nature == 5 && ('record.priceForFront == () || (<float>('record.priceForFront)) < 30000.0)
            ?
            "Prix malin"
            :
            ()
        ;

        'record["category"] =
            'record.isOccasion ?
            1
            :
                [0, 3].indexOf('record.nature) != () ?
                3
                :
                4
        ;

        'record["customerDispo"] =
            ('record.nature != 1 && 'record.nature != 5 && 'record.disponibiliteForFO == "en stock") ?
            "disponible"
            :
                'record.disponibiliteForFO is () || 'record.disponibiliteForFO == "" ? "error" : <string>'record.disponibiliteForFO
        ;

        'record["isFrenchDaysPromo"] =
            [1, 4].indexOf(<int>'record["category"]) != () && 'record.typeForRecherche == "Particulier" &&
            (["CITROEN", "PEUGEOT", "RENAULT", "DACIA"].indexOf('record["marque"]) != ())
            ?
            true
            :
            false
        ;

        if 'record is db:Offre {
            'record["categoryNormalized"] =
                'record["category"] == 1 ?
                "Occasion"
                :
                    'record["category"] == 3 ?
                    "Neuf à la commande"
                    :
                        'record["category"] == 4 ?
                        "0Km"
                        :
                        ()
            ;
        }

        //duplicated loyer fields:
        if 'record is db:Loyer {
            'record["euro_tax"] = 'record.euroTax;
            'record["premier_loyer"] = 'record.premierLoyer;
            'record["loyer_mensuel"] = 'record.loyerMensuel;
            'record["valeur_rachat"] = 'record.valeurRachat;
            'record["cout_total"] = 'record.coutTotal;
            'record["perte_totale"] = 'record.perteTotale;
            'record["offre_init"] = 'record.offreInit;
            'record["offre_id"] = 'record.offreId;
            //offre fields duplicated in loyer
            'record["OffreImages"] = 'record.offreImages;
            'record["ColorsImages"] = 'record.colorsImages;
        }
    }
}
