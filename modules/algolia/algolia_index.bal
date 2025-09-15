import ballerina/http;
import ballerina/log;
import ballerina/task;
import ballerina/uuid;

import cosmobilis/postgres_db as db;
import cosmobilis/teams;
import cosmobilis/time as c_time;

type Conf record {
    string appId;
    string apiKey;
    map<string> indexNames;
    int hour;
    int minutes;
    int seconds;
    # for test: if dryRun then temporary index is created but does not replace the master index.
    boolean dryRun = true;
};

configurable Conf conf = ?;

public function createAlgoliaIndexJob() returns task:JobId|error {
    AlgoliaIndexJob myJob = new;
    if (conf.hour < 0) {
        return task:scheduleJobRecurByFrequency(myJob, 2 * 60 * 60);
    } else {
        return task:scheduleJobRecurByFrequency(myJob, 2 * 60 * 60, -1, check c_time:at(conf.hour, conf.minutes, conf.seconds));
    }
}

class AlgoliaIndexJob {
    *task:Job;

    public function execute() {
        lock {
            do {

                if conf.dryRun {
                    log:printInfo("Mode DRY RUN activé - L'index temporaire ne remplacera PAS l'index master.");
                }

                //Indexation start notification
                string startMsg = string `${<string>conf.indexNames["offres"]} and ${<string>conf.indexNames["loyers"]}`;
                if teams:sendTeamsNotification(startMsg, "indexes update started...", [{"Type d'exécution": "Tâche planifiée"}]) is error {
                    log:printError(string `Teams indexation start notification failed.`);
                } else {
                    log:printInfo(startMsg);
                }

                // Indexation des Offres dans nouvel index temporaire
                string tmpOfferIndex = check self.indexEntity("offres", conf.indexNames["offres"]);
                // Indexation des Loyers dans nouvel index temporaire
                string tmpLoyerIndex = check self.indexEntity("loyers", conf.indexNames["loyers"]);
                // Remplacement des index master par les nouveaux index temporaires
                check self.moveIndex(tmpOfferIndex, <string> conf.indexNames["offres"]);
                check self.moveIndex(tmpLoyerIndex, <string> conf.indexNames["loyers"]);

                //Indexation end notification
                string endMsg = string `${<string>conf.indexNames["offres"]} and ${<string>conf.indexNames["loyers"]}`;
                if teams:sendTeamsNotification(endMsg, "indexes update completed.", [{"Type d'exécution": "Tâche planifiée"}]) is error {
                    log:printError(string `Teams indexation completion notification failed.`);
                } else {
                    log:printInfo(endMsg);
                }

            } on fail var failure {
                log:printError("Unmanaged error", failure);
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
        http:Client algoliaClient = check new ("https://" + conf.appId + "-dsn.algolia.net");
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
        http:Client algoliaClient = check new ("https://" + conf.appId + "-dsn.algolia.net");
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
            http:Client algoliaClient = check new ("https://" + conf.appId + "-dsn.algolia.net");
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
