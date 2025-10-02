import ballerina/data.jsondata;
import ballerina/log;
import ballerina/task;
import ballerina/time as time;
import cosmobilis/teams;
import cosmobilis/bo_db as bodb;
import cosmobilis/time as c_time;

// === SCHEDULER INITIALISATION ===
public type Conf record {
    int hour; 
    int minutes; 
    int seconds;
};

public configurable Conf conf = ?;

public function createOfferTrackingJob() returns task:JobId|error {

    OfferTrackingJob myJob = new;

    return task:scheduleJobRecurByFrequency(myJob, 24 * 60 * 60, -1, check c_time:at(conf.hour, conf.minutes, conf.seconds));
}

class OfferTrackingJob {
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
                // Notification Teams en cas d'erreur
                var notif = teams:sendTeamsNotification("Erreur exécution job offer_tracking", msg, "Type d'exécution: Tâche planifiée");
                if notif is error {
                    log:printError("Échec d'envoi Teams", notif);
                }
                    log:printError("=== ERREUR JOB OFFER_TRACKING ===");
                    log:printError("Type d'exécution: Tâche planifiée");
                    log:printError("Message d'erreur: " + msg);
                }
            } on fail var failure {
                log:printError("Unmanaged error", failure);
            }
        }
    }

    function scheduledRun() returns error? {
        log:printInfo("🚀 Début du suivi des offres - " + time:utcNow().toString());
        
        // 1. Récupérer les nouvelles offres des partenaires (ELITE / BMC / PROXAUTO )
        json[] nouvellesOffresPartenaires = check self.getNewOffersFromPartenaires();
        
        // 2. Récupérer les mises à jour des partenaires
        json[] misesAJourPartenaires = check self.getUpdatedOffersFromPartenaires();
        
        // 3. Récupérer les nouvelles offres de Starterre
        json[] nouvellesOffresStarterre = check self.getNewOffersFromStarterre();
        
        // 4. Récupérer les offres publiées aujourd'hui
        json[] offresPublieesAuj = check self.getPublishedOffersToday();

        // 5. Récupérer les offres vendues aujourd'hui
        json[] offresVenduesAuj = check self.getSoldOffersToday();

        // 6. Récupérer les offres en quarantaine aujourd'hui
        json[] offresQuarantaineAuj = check self.getQuarantinedOffersToday();

        // 7. Combiner tous les résultats
        json[] toutesNouvellesOffres = [...nouvellesOffresPartenaires, ...nouvellesOffresStarterre];
        json[] toutesMisesAJour = [...misesAJourPartenaires];

        // 8. Sauvegarde de l'instantané quotidien (historisation)
        time:Utc aujourdhui = time:utcNow();
        string dateAujourdhui = time:utcToString(aujourdhui).substring(0, 10);
        check bodb:saveOfferPublicationSnapshot(
            dateAujourdhui,
            toutesNouvellesOffres,
            toutesMisesAJour,
            offresPublieesAuj,
            offresVenduesAuj,
            offresQuarantaineAuj
        );

        // 9. Générer et envoyer le rapport journalier (listings par lot)
        check self.generateAndSendReportExtended(toutesNouvellesOffres, toutesMisesAJour, offresPublieesAuj, offresVenduesAuj, offresQuarantaineAuj);
        
        log:printInfo("✅ Suivi des offres terminé");
        return;
    }

    // Récupérer les nouvelles offres des partenaires
    function getNewOffersFromPartenaires() returns json[]|error {
        time:Utc aujourdhui = time:utcNow();
        string dateAujourdhui = time:utcToString(aujourdhui).substring(0, 10);

        json[] offres = check bodb:getNewOffersFromPartenaires(dateAujourdhui);
        return offres;
    }

    // Identifier les offres publiées aujourd'hui
    function getPublishedOffersToday() returns json[]|error {
        time:Utc aujourdhui = time:utcNow();
        string dateAujourdhui = time:utcToString(aujourdhui).substring(0, 10);
        json[] offres = check bodb:getPublishedOffersForDate(dateAujourdhui);
        
        return offres;
    }

    // Identifier les offres vendues aujourd'hui
    function getSoldOffersToday() returns json[]|error {
        time:Utc aujourdhui = time:utcNow();
        string dateAujourdhui = time:utcToString(aujourdhui).substring(0, 10);
        json[] offres = check bodb:getSoldOffersForDate(dateAujourdhui);
        return offres;
    }

    // Identifier les offres en quarantaine aujourd'hui
    function getQuarantinedOffersToday() returns json[]|error {
        time:Utc aujourdhui = time:utcNow();
        string dateAujourdhui = time:utcToString(aujourdhui).substring(0, 10);
        json[] offres = check bodb:getQuarantinedOffersForDate(dateAujourdhui);
        return offres;
    }

    // Récupérer les mises à jour des partenaires
    function getUpdatedOffersFromPartenaires() returns json[]|error {
        log:printInfo("📊 Récupération des mises à jour des partenaires...");
        
        time:Utc aujourdhui = time:utcNow();
        string dateAujourdhui = time:utcToString(aujourdhui).substring(0, 10);
        
        json[] offres = check bodb:getUpdatedOffersFromPartenaires(dateAujourdhui);
        
        log:printInfo("✅ Trouvé " + offres.length().toString() + " mises à jour des partenaires");
        return offres;
    }

    // Récupérer les nouvelles offres de Starterre
    function getNewOffersFromStarterre() returns json[]|error {
        time:Utc aujourdhui = time:utcNow();
        string dateAujourdhui = time:utcToString(aujourdhui).substring(0, 10);
        
        json[] offres = check bodb:getNewOffersFromStarterre(dateAujourdhui);
        return offres;
    }


    // Générer et envoyer le rapport 
    // Format de listing par lot : découpage en chunks de 20 éléments
    function generateAndSendReportExtended(json[] nouvellesOffres, json[] misesAJour, json[] publieesAuj, json[] venduesAuj, json[] quarantaineAuj) returns error? {
        int totalNouvelles = nouvellesOffres.length();
        int totalMisesAJour = misesAJour.length();
        int totalPubliees = publieesAuj.length();
        int totalVendues = venduesAuj.length();
        int totalQuarantaine = quarantaineAuj.length();
        
        if totalNouvelles == 0 && totalMisesAJour == 0 && totalPubliees == 0 && totalVendues == 0 && totalQuarantaine == 0 {
            log:printInfo("ℹ️ Aucune nouvelle offre ou mise à jour à signaler.");
            return;
        }

        string title = "📈 Rapport de suivi des offres";
        int totalOffres = totalNouvelles + totalMisesAJour + totalPubliees + totalVendues + totalQuarantaine;
        int chunkSize = 20; // taille de lot

        // Séparer les nouvelles offres et mises à jour en lots
        json[][] nouvellesChunks = self.chunkOffers(nouvellesOffres, chunkSize);
        json[][] misesAJourChunks = self.chunkOffers(misesAJour, chunkSize);
        json[][] publieesChunks = self.chunkOffers(publieesAuj, chunkSize);
        json[][] venduesChunks = self.chunkOffers(venduesAuj, chunkSize);
        json[][] quarantaineChunks = self.chunkOffers(quarantaineAuj, chunkSize);
        
        // Calculer le nombre total de lots
        int totalChunks = nouvellesChunks.length() + misesAJourChunks.length() + publieesChunks.length() + venduesChunks.length() + quarantaineChunks.length();
        int batchIndex = 1;

        // Traiter les lots de nouvelles offres (envoi Teams)
        foreach json[] chunk in nouvellesChunks {
            string description = string `${totalOffres} offre(s) à signaler — lot ${batchIndex.toString()}/${totalChunks.toString()}`;
            string detailsMessage = self.buildDetailsMessageForChunk(chunk, "nouvelles");
            check teams:sendTeamsNotification(title, description, detailsMessage);
            
            batchIndex = batchIndex + 1;
        }

        // Traiter les lots de mises à jour 
        foreach json[] chunk in misesAJourChunks {
            string description = string `${totalOffres} offre(s) à signaler — lot ${batchIndex.toString()}/${totalChunks.toString()}`;
            string detailsMessage = self.buildDetailsMessageForChunk(chunk, "mises à jour");
            check teams:sendTeamsNotification(title, description, detailsMessage);
            
            batchIndex = batchIndex + 1;
        }

        // Traiter les lots d'offres publiées aujourd'hui
        foreach json[] chunk in publieesChunks {
            string description = string `${totalOffres} offre(s) à signaler — lot ${batchIndex.toString()}/${totalChunks.toString()}`;
            string detailsMessage = self.buildDetailsMessageForChunk(chunk, "publiées aujourd'hui");
            check teams:sendTeamsNotification(title, description, detailsMessage);
            
            batchIndex = batchIndex + 1;
        }

        // Traiter les lots d'offres vendues aujourd'hui
        foreach json[] chunk in venduesChunks {
            string description = string `${totalOffres} offre(s) à signaler — lot ${batchIndex.toString()}/${totalChunks.toString()}`;
            string detailsMessage = self.buildDetailsMessageForChunk(chunk, "vendues aujourd'hui");
            check teams:sendTeamsNotification(title, description, detailsMessage);
            
            batchIndex = batchIndex + 1;
        }

        // Traiter les lots d'offres en quarantaine aujourd'hui
        foreach json[] chunk in quarantaineChunks {
            string description = string `${totalOffres} offre(s) à signaler — lot ${batchIndex.toString()}/${totalChunks.toString()}`;
            string detailsMessage = self.buildDetailsMessageForChunk(chunk, "quarantaine aujourd'hui");
            check teams:sendTeamsNotification(title, description, detailsMessage);
            
            batchIndex = batchIndex + 1;
        }
    }
    

    // Construire le message détaillé pour un lot d'offres
    function buildDetailsMessageForChunk(json[] offres, string offreType) returns string {
        string detailsMessage = "📋 **RAPPORT DE SUIVI DES OFFRES**\n\n";
        
        // Ajouter un en-tête selon le type d'offres
        if offreType == "nouvelles" {
            detailsMessage += "🆕 **NOUVELLES OFFRES** (" + offres.length().toString() + ")\n\n";
        } else if offreType == "mises à jour" {
            detailsMessage += "🔄 **MISES À JOUR** (" + offres.length().toString() + ")\n\n";
        } else if offreType == "publiées aujourd'hui" {
            detailsMessage += "📢 **OFFRES PUBLIÉES AUJOURD'HUI** (" + offres.length().toString() + ")\n\n";
        } else if offreType == "vendues aujourd'hui" {
            detailsMessage += "💰 **OFFRES VENDUES AUJOURD'HUI** (" + offres.length().toString() + ")\n\n";
        } else if offreType == "quarantaine aujourd'hui" {
            detailsMessage += "🚫 **OFFRES EN QUARANTAINE AUJOURD'HUI** (" + offres.length().toString() + ")\n\n";
        }
        
        int count = 0;
        foreach var offre in offres {
            count = count + 1;
            if count > 20 { // Limiter à 20 offres par section
                detailsMessage += "... et " + (offres.length() - 20).toString() + " autres\n";
                break;
            }

            var vId = jsondata:read(offre, `$.id`);
            string idVehJson = vId is error ? "null" : vId.toString();
            var vIdOffre = jsondata:read(offre, `$.id_offre`);
            string idOffre = vIdOffre is error ? "NULL" : vIdOffre.toString();
            if (idOffre == "" || idOffre == "null") {
                idOffre = "NULL";
            }
            var vSource = jsondata:read(offre, `$.source`);
            string sourceValue = vSource is error ? "" : vSource.toString();
            var vType = jsondata:read(offre, `$.type`);
            string typeValue = vType is error ? "" : vType.toString();
            if (typeValue == "") {
                var vTypeStr = jsondata:read(offre, `$.type_str`);
                typeValue = vTypeStr is error ? "" : vTypeStr.toString();
            }
            var vTypeId = jsondata:read(offre, `$.type_id`);
            string typeId = vTypeId is error ? "" : vTypeId.toString();
            var vFournisseur = jsondata:read(offre, `$.fournisseur`);
            string fournisseur = vFournisseur is error ? "" : vFournisseur.toString();
            var vEtat = jsondata:read(offre, `$.etat`);
            string etat = vEtat is error ? "" : vEtat.toString();
            var vEtatId = jsondata:read(offre, `$.etat_id`);
            string etatId = vEtatId is error ? "" : vEtatId.toString();
            var vDateCreation = jsondata:read(offre, `$.date_creation`);
            string dateCreation = vDateCreation is error ? "" : vDateCreation.toString();
            var vDateMaj = jsondata:read(offre, `$.date_mise_a_jour`);
            string dateMaj = vDateMaj is error ? "" : vDateMaj.toString();
            var vNumeroDossier = jsondata:read(offre, `$.numero_dossier`);
            string numeroDossier = vNumeroDossier is error ? "" : vNumeroDossier.toString();

            // Adapter l'affichage selon la source
            string identifiant = "";
            if sourceValue == "starterre" && numeroDossier != "" {
                identifiant = "**ID:" + idVehJson + " OFFRE #" + idOffre + " DOSSIER #" + numeroDossier + "** (" + sourceValue + ")";
            } else {
                identifiant = "**ID:" + idVehJson + " OFFRE #" + idOffre + "** (" + sourceValue + ")";
            }

            detailsMessage += string `
            ${identifiant}
            • **Type :** ${typeValue} (ID: ${typeId})
            • **Fournisseur :** ${fournisseur}
            • **État :** ${etat} (ID: ${etatId})
            • **Date création :** ${dateCreation}
            • **Date MAJ :** ${dateMaj}

            -------------------------
            `;
        }
        
        return detailsMessage;
    }

    // Découper la liste d'offres en lots de taille fixe
    function chunkOffers(json[] offres, int size) returns json[][] {
        json[][] result = [];
        json[] current = [];
        int count = 0;
        foreach var offre in offres {
            current.push(offre);
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