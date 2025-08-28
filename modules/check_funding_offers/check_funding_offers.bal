import ballerina/data.jsondata;
import ballerina/log;
import ballerina/task;
import cosmobilis/teams;

import cosmobilis/bo_db as bodb;


// === SCHEDULER INITIALISATION ===
public function createCheckFundingOffersJob() returns task:JobId|error {
    CheckFundingOffersJob myJob = new;
    return task:scheduleJobRecurByFrequency(myJob, 60*60*24);
}

//TODO: refactor logging and teams notif code in this class: 
// - externalize teams code in a dedicated package
// - externalize logging code in a dedicated pkg integrating teams pkg.
class CheckFundingOffersJob {
    *task:Job;

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
                    var notif = teams:sendTeamsNotification("Erreur exécution job check_funding_offers", msg, [{"Type d'exécution": "Tâche planifiée"}]);
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

        string title = "🚨 Offres en attente de financement détectées";
        int totalOffers = offers.length();
        int chunkSize = 10; // taille de lot

        json[][] chunks = self.chunkOffers(offers, chunkSize);
        int totalChunks = chunks.length();
        int batchIndex = 1;
        foreach json[] chunk in chunks {
            string description = string `${totalOffers} offre(s) bloquée(s) nécessitent une attention — lot ${batchIndex.toString()}/${totalChunks.toString()}`;
            string detailsMessage = self.buildDetailsMessage(chunk);
            check teams:sendTeamsNotification(title, description, detailsMessage);
            batchIndex = batchIndex + 1;
        }

        // Logs locaux désactivés
        // log:printInfo("[LOCAL TEST] Titre: " + title);
        // log:printInfo("[LOCAL TEST] Description: " + description);
        // log:printInfo("[LOCAL TEST] Message:\n" + fullMessage);
    }
    
    // Construire le message détaillé
    private function buildDetailsMessage(json[] offers) returns string {
        string detailsMessage = "📋 **DÉTAILS DES OFFRES BLOQUÉES**\n\n";
        
        foreach var offer in offers {

            var vIdOffre = jsondata:read(offer, `$.id_offre`);
            string idOffre = vIdOffre is error ? "" : vIdOffre.toString();
            var vIdCarshop = jsondata:read(offer, `$.id_carshop`);
            string idCarshop = vIdCarshop is error ? "" : vIdCarshop.toString();
            var vNom = jsondata:read(offer, `$.nom`);
            string nom = vNom is error ? "" : vNom.toString();
            var vType = jsondata:read(offer, `$.type`);
            string typee = vType is error ? "" : vType.toString();
            var vPubliee = jsondata:read(offer, `$.publiee`);
            string publiee = vPubliee is error ? "" : vPubliee.toString();
            var vDateCreation = jsondata:read(offer, `$.date_creation`);
            string dateCreation = vDateCreation is error ? "" : vDateCreation.toString();
            var vDateMaj = jsondata:read(offer, `$.date_derniere_mise_a_jour`);
            string dateMaj = vDateMaj is error ? "" : vDateMaj.toString();
            var vNatureId = jsondata:read(offer, `$.id_nature`);
            string natureId = vNatureId is error ? "" : vNatureId.toString();
            var vLibelleNature = jsondata:read(offer, `$.libelle_nature`);
            string libelleNature = vLibelleNature is error ? "" : vLibelleNature.toString();
            var vUrlCarshop = jsondata:read(offer, `$.url_carshop`);
            string urlCarshop = vUrlCarshop is error ? "" : vUrlCarshop.toString();
            var vUrlSite = jsondata:read(offer, `$.url_site`);
            string urlSite = vUrlSite is error ? "" : vUrlSite.toString();
            var vNbJoursAttente = jsondata:read(offer, `$.nb_jours_attente`);
            string nbJoursAttente = vNbJoursAttente is error ? "0" : vNbJoursAttente.toString();
            var vIdVehJsonPartenaire = jsondata:read(offer, `$.id_veh_json_partenaire`);
            string idVehJsonPartenaire = vIdVehJsonPartenaire is error ? "" : vIdVehJsonPartenaire.toString();
            
            // Déterminer le niveau de priorité
            string priority = "";
            var parsedJours = int:fromString(nbJoursAttente);
            int jours = parsedJours is int ? parsedJours : 0;
            if (jours > 7) {
                priority = "🔴 **CRITIQUE**";
            } else if (jours > 3) {
                priority = "🟡 **ATTENTION**";
            } else {
                priority = "🟢 **NORMAL**";
            }

            detailsMessage += string `
            ${priority} **OFFRE #${idOffre}** (ID VJP: ${idVehJsonPartenaire})
            • **Jours d'attente :** ${nbJoursAttente} jours
            • **ID Carshop :** ${idCarshop}
            • **Nom :** ${nom}
            • **Type :** ${typee}
            • **Publiée :** ${publiee}
            • **Date création :** ${dateCreation}
            • **Dernière MAJ :** ${dateMaj}
            • **Nature :** ${natureId} (${libelleNature})
            • **URL Carshop :** ${urlCarshop}
            • **URL Site :** ${urlSite}

            -------------------------
            `;
        }
             
        return detailsMessage;
    }

    // Découper la liste d'offres en lots de taille fixe
    private function chunkOffers(json[] offers, int size) returns json[][] {
        json[][] result = [];
        json[] current = [];
        int count = 0;
        foreach var offer in offers {
            current.push(offer);
            count = count + 1;
            if (count == size) {
                result.push(current);
                current = [];
                count = 0;
            }
        }
        if (current.length() > 0) {
            result.push(current);
        }
        return result;
    }
}