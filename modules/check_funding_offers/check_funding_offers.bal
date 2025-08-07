import ballerina/data.jsondata;
import ballerina/http;
import ballerina/log;
import ballerina/task;

import cosmobilis/bo_db as bodb;

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

// === SCHEDULER INITIALISATION ===
public function createCheckFundingOffersJob() returns task:JobId|error {
    CheckFundingOffersJob myJob = check new (teams);
    return task:scheduleJobRecurByFrequency(myJob, 60*60*24);
}

//TODO: refactor logging and teams notif code in this class: 
// - externalize teams code in a dedicated package
// - externalize logging code in a dedicated pkg integrating teams pkg.
class CheckFundingOffersJob {
    *task:Job;
    TeamsConf teams;
    map<string> headersTeams;

    function init(TeamsConf teamsConf) returns error? {
        self.teams = teamsConf;
        self.headersTeams = {
            "x-api-key": self.teams.apiKey
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
                    var notif = self.sendTeamsNotification("Erreur exécution job check_funding_offers", msg, [{"Type d'exécution": "Tâche planifiée"}]);
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
        json[] offers = check bodb:getPendingFundingOffers();

        if offers.length() == 0 {
            log:printInfo("Aucune offre bloquée à signaler.");
            return;
        }

        string title = "Offres en attente de financement détectées";
        string description = "Nombre d'offres : " + offers.length().toString();
        map<string>[] list = [];

        foreach var offer in offers {
            string idOffre = (check jsondata:read(offer, `$.id_offre`)).toString();
            string idCarshop = (check jsondata:read(offer, `$.id_carshop`)).toString();
            string nom = (check jsondata:read(offer, `$.nom`)).toString();
            string typee = (check jsondata:read(offer, `$.type`)).toString();
            string publiee = (check jsondata:read(offer, `$.publiee`)).toString();
            string dateCreation = (check jsondata:read(offer, `$.date_creation`)).toString();
            string dateMaj = (check jsondata:read(offer, `$.date_derniere_mise_a_jour`)).toString();
            string natureId = (check jsondata:read(offer, `$.id_nature`)).toString();
            string libelleNature = (check jsondata:read(offer, `$.libelle_nature`)).toString();
            string urlCarshop = (check jsondata:read(offer, `$.url_carshop`)).toString();
            string urlSite = (check jsondata:read(offer, `$.url_site`)).toString();
            string nbJoursAttente = (check jsondata:read(offer, `$.nb_jours_attente`)).toString();

            string cardJson = string `
            {
                "type": "AdaptiveCard",
                "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                "version": "1.6",
                "body": [
                    {
                        "type": "TextBlock",
                        "text": "Offre #${idOffre}",
                        "wrap": true,
                        "style": "heading"
                    },
                    {
                        "type": "FactSet",
                        "facts": [
                            { "title": "Offre:", "value": "${idOffre}" },
                            { "title": "ID Carshop:", "value": "${idCarshop}" },
                            { "title": "Nom:", "value": "${nom}" },
                            { "title": "Type:", "value": "${typee}" },
                            { "title": "Publiée:", "value": "${publiee}" },
                            { "title": "Créée:", "value": "${dateCreation}" },
                            { "title": "Mise à jour:", "value": "${dateMaj}" },
                            { "title": "Nature:", "value": "${natureId} (${libelleNature})" },
                            { "title": "URL Carshop:", "value": "${urlCarshop}" },
                            { "title": "URL Site:", "value": "${urlSite}" },
                            { "title": "Nb jours attente:", "value": "${nbJoursAttente}" }
                        ]
                    }
                ]
            }`;
            list.push({ [string `Offre #${idOffre}`]: cardJson });
        }

        check self.sendTeamsNotification(title, description, list);
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
