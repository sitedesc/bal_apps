import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerinax/mysql;
import ballerina/data.jsondata;

public type Conf record {
    string host;
    int port = 3306;
    string user;
    string password;
    string database;
};

public type QuotationCriterias record {
    string numero?;
};

type VehJsonPartenaireRow record {
        int id?;
        int offre?;
        int etat?;
};

// Nouveau type pour la table de suivi des offres bloquées
public type BlockedOfferRow record {
    int id?;
    int id_veh_json_partenaire?;
    int id_offre?;
    int nb_jours_attente?;
    string date_creation?;
    string date_maj?;
};

public configurable Conf conf = ?;

final mysql:Client dbClient = check new (conf.host, conf.user, conf.password, conf.database, conf.port);

public isolated function getCountQuotations(QuotationCriterias criterias) returns int|error {
    sql:ParameterizedQuery queryTemplate = `SELECT count(1) FROM devis `;
    if criterias.numero != "" {
            queryTemplate = sql:queryConcat(queryTemplate, `WHERE numero = ${criterias.numero} `);
    }

    log:printDebug(queryTemplate.strings.toString());
    log:printDebug(queryTemplate.insertions.toString());

    return check dbClient->queryRow(queryTemplate);
}

public isolated function existQuotations(QuotationCriterias criterias) returns boolean|error {
    return check getCountQuotations(criterias) > 0 ? true : false;
}

public isolated function getPendingFundingOffers() returns json[]|error {
    // Synchroniser d'abord la table de suivi
    check syncBlockedOffersTracking();
    
    sql:ParameterizedQuery query = `
    SELECT
        sq.id_offre,
        sq.id_carshop,
        sq.url_carshop,
        sq.url_site,
        sq.nom,
        sq.type,
        IF (
                sq.etat = 'active' AND (NOT sq.c_est_du_stock OR sq.etape_vente = 'dispo'),
                'oui',
                'non'
        ) AS publiee,
        sq.date_creation,
        sq.date_derniere_mise_a_jour,
        sq.id_nature,
        sq.libelle_nature,
        sq.nb_jours_attente,
        sq.id_veh_json_partenaire
    FROM (
            SELECT
                v.offre AS id_offre,
                v.id AS id_veh_json_partenaire,
                o.nom,
                o.is_stock AS c_est_du_stock,
                o.nature AS id_nature,
                IF (
                        o.etat = 1, 'active', 'inactive'
                )  AS etat,

                CASE o.etat_vente
                    WHEN 0 THEN 'dispo'
                    WHEN 1 THEN 'reservée'
                    WHEN 2 THEN 'validation financement'
                    WHEN 3 THEN 'vendue'
                    WHEN 4 THEN 'reservée client'
                    WHEN 5 THEN 'dossier vente incomplet'
                    ELSE o.etat_vente
                    END AS etape_vente,

                CASE o.nature
                    WHEN 0 THEN 'EUROTAX'
                    WHEN 1 THEN 'ELITE'
                    WHEN 2 THEN 'ELITE_VO'
                    WHEN 3 THEN 'BMC'
                    WHEN 4 THEN 'BMC_VO'
                    WHEN 5 THEN 'PROXAUTO_VO'
                    WHEN 6 THEN 'STARTERRE_VN'
                    WHEN 7 THEN 'STARTERRE_VO'
                    WHEN 8 THEN 'OKAZIUM_VO'
                    WHEN 9 THEN 'IMEXSO_VN'
                    WHEN 10 THEN 'IMEXSO_VO'
                    WHEN 11 THEN 'EDPAUTO_VN'
                    WHEN 12 THEN 'EDPAUTO_VO'
                    WHEN 99 THEN 'QUARANTAINE'
                    ELSE CAST(o.nature AS CHAR)
                    END AS libelle_nature,

                CASE o.nature
                    WHEN 0 THEN 'VN'
                    WHEN 1 THEN 'VN'
                    WHEN 3 THEN 'VN'
                    WHEN 6 THEN 'VN'
                    WHEN 9 THEN 'VN'
                    WHEN 11 THEN 'VN'
                    WHEN 2 THEN 'VO'
                    WHEN 4 THEN 'VO'
                    WHEN 5 THEN 'VO'
                    WHEN 7 THEN 'VO'
                    WHEN 8 THEN 'VO'
                    WHEN 10 THEN 'VO'
                    WHEN 12 THEN 'VO'
                    ELSE 'AUTRE'
                    END AS type,

                v.created_at AS date_creation,
                v.update_at AS date_derniere_mise_a_jour,
                JSON_UNQUOTE(JSON_EXTRACT(v.json, '$.sIDCrypte')) AS id_carshop,
                CONCAT('https://car-shop.webapp4you.eu/service/vo/visualisation?i_veh_id=',
                        JSON_UNQUOTE(JSON_EXTRACT(v.json, '$.sIDCrypte'))) AS url_carshop,
                CONCAT('https://www.elite-auto.fr/devis/',offre) as url_site,
                bot.nb_jours_attente

            FROM veh_json_partenaire v
                    JOIN offre o ON o.id = v.offre
                    JOIN blocked_offers_tracking bot ON bot.id_offre = v.offre
            WHERE v.etat = 12
        ) AS sq
    ORDER BY sq.nb_jours_attente DESC, sq.date_creation ASC;
    `;

    stream<VehJsonPartenaireRow, error?> resultStream = dbClient->query(query);
    json[] results = [];
    int count = 0;
    check from VehJsonPartenaireRow row in resultStream
        do {
            count += 1;
            results.push(row.toJson());
        };
    log:printInfo("Nombre total de lignes : " + count.toString());
    return results;
}

// Fonction principale pour synchroniser la table de suivi
isolated function syncBlockedOffersTracking() returns error? {
    // 1. Créer la table si elle n'existe pas
    check createBlockedOffersTrackingTable();
    
    // 2. Mettre à jour les jours d'attente pour celles toujours bloquées
    check updateBlockedOffersWaitingDays();

    // 3. Ajouter les nouvelles offres bloquées
    sql:ParameterizedQuery newBlockedOffersQuery = `
        SELECT v.id, v.offre
        FROM veh_json_partenaire v
        WHERE v.etat = 12
        AND v.offre NOT IN (SELECT id_offre FROM blocked_offers_tracking)
    `;

    stream<record {int id; int offre;}, error?> newOffersStream = dbClient->query(newBlockedOffersQuery);
    check from record {int id; int offre;} row in newOffersStream
        do {
            check addBlockedOfferToTracking(row.id, row.offre);
        };

    // 4. Supprimer les offres débloquées
    check removeUnblockedOffers();
    
    return;
}

// Créer la table de suivi si elle n'existe pas
isolated function createBlockedOffersTrackingTable() returns error? {
    sql:ParameterizedQuery createTableQuery = `
        CREATE TABLE IF NOT EXISTS blocked_offers_tracking (
            id INT AUTO_INCREMENT PRIMARY KEY,
            id_veh_json_partenaire INT NOT NULL,
            id_offre INT NOT NULL,
            nb_jours_attente INT DEFAULT 0,
            date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            date_maj TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY unique_offre (id_offre),
            INDEX idx_etat_12 (id_veh_json_partenaire, id_offre)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `;
    
    sql:ExecutionResult _ = check dbClient->execute(createTableQuery);
    return;
}

// Ajouter une nouvelle offre bloquée au suivi
isolated function addBlockedOfferToTracking(int idVehJsonPartenaire, int idOffre) returns error? {
    sql:ParameterizedQuery insertQuery = `
        INSERT INTO blocked_offers_tracking (id_veh_json_partenaire, id_offre, nb_jours_attente)
        VALUES (${idVehJsonPartenaire}, ${idOffre}, 0)
        ON DUPLICATE KEY UPDATE 
            id_veh_json_partenaire = VALUES(id_veh_json_partenaire),
            nb_jours_attente = 0,
            date_maj = CURRENT_TIMESTAMP
    `;
    
    sql:ExecutionResult _ = check dbClient->execute(insertQuery);
    return;
}

// Mettre à jour le nombre de jours d'attente pour toutes les offres suivies
isolated function updateBlockedOffersWaitingDays() returns error? {
    // Incrémentation quotidienne (+1 jour à chaque exécution)
    sql:ParameterizedQuery updateQuery = `
        UPDATE blocked_offers_tracking bot
        SET bot.nb_jours_attente = bot.nb_jours_attente + 1
        WHERE EXISTS (
            SELECT 1 FROM veh_json_partenaire v 
            WHERE v.id = bot.id_veh_json_partenaire 
            AND v.etat = 12
        )
    `;
    
    sql:ExecutionResult _ = check dbClient->execute(updateQuery);
    return;
}

// Supprimer les offres qui ne sont plus bloquées (état != 12)
isolated function removeUnblockedOffers() returns error? {
    sql:ParameterizedQuery deleteQuery = `
        DELETE bot FROM blocked_offers_tracking bot
        JOIN veh_json_partenaire v ON v.id = bot.id_veh_json_partenaire
        WHERE v.etat != 12
    `;
    
    sql:ExecutionResult _ = check dbClient->execute(deleteQuery);
    return;
}
// === FONCTIONS POUR LE SUIVI DES OFFRES ===

// Récupérer les nouvelles offres des partenaires
public isolated function getNewOffersFromPartenaires(string dateAujourdhui) returns json[]|error {
     log:printInfo("dateAujourdhui..."+ dateAujourdhui);
    sql:ParameterizedQuery query = `
        SELECT 
            v.id,
            v.offre AS id_offre,
            v.etat,
            v.created_at,
            v.update_at AS updated_at,
            'partenaire' AS source,
            v.type AS type_id,
                    CASE v.type
                        WHEN 0 THEN 'ELITE_VO'
                        WHEN 1 THEN 'BMC_VN'
                        WHEN 2 THEN 'BMC_VO'
                        WHEN 3 THEN 'PROXAUTO_VO'
                        WHEN 4 THEN 'STARTERRE_VO'
                        WHEN 5 THEN 'STARTERRE_VN'
                        WHEN 6 THEN 'OKAZIUM_VO'
                        WHEN 7 THEN 'IMEXSO_VN'
                        WHEN 8 THEN 'EDPAUTO_VN'
                        WHEN 9 THEN 'EDPAUTO_VO'
                        WHEN 10 THEN 'IMEXSO_VO'
                        WHEN 55 THEN 'PROXAUTO_KEPLER_VO'
                        WHEN 99 THEN 'QUARANTAINE_VO'
                        ELSE 'AUTRE'
                    END AS fournisseur,
                    CASE v.type
                        WHEN 0 THEN 'VO'
                        WHEN 1 THEN 'VN'
                        WHEN 2 THEN 'VO'
                        WHEN 3 THEN 'VO'
                        WHEN 4 THEN 'VO'
                        WHEN 5 THEN 'VN'
                        WHEN 6 THEN 'VO'
                        WHEN 7 THEN 'VN'
                        WHEN 8 THEN 'VN'
                        WHEN 9 THEN 'VO'
                        WHEN 10 THEN 'VO'
                        WHEN 55 THEN 'VO'
                        WHEN 99 THEN 'VO'
                        ELSE 'AUTRE'
                    END AS type,
                    CASE v.etat
                        WHEN -1 THEN 'etat à vérifier'
                        WHEN 0 THEN 'etat json'
                        WHEN 1 THEN 'json_elite_ok'
                        WHEN 2 THEN 'offre_initiale'
                        WHEN 3 THEN 'vehicule_a_creer'
                        WHEN 4 THEN 'vehicule_cree'
                        WHEN 5 THEN 'stock_maj_ok'
                        WHEN 6 THEN 'color_options_ok'
                        WHEN 7 THEN 'photos_ok'
                        WHEN 8 THEN 'stock_fin'
                        WHEN 9 THEN 'attente_activation'
                        WHEN 10 THEN 'stock_actif'
                        WHEN 12 THEN 'attente_offre_fo'
                        WHEN 15 THEN 'en_erreur'
                        WHEN 20 THEN 'pas_de_maj'
                        WHEN 25 THEN 'a_supprimer'
                        WHEN 26 THEN 'supprime'
                        WHEN 50 THEN 'meero'
                        WHEN 51 THEN 'meero_to_send'
                        WHEN 52 THEN 'meero_send'
                        WHEN 53 THEN 'meero_traitement_auto'
                        WHEN 54 THEN 'meero_traitement_final'
                        WHEN 55 THEN 'meero_ok'
                        WHEN 59 THEN 'meero_erreur'
                        WHEN 60 THEN 'attente_verif_meero_manuelle'
                        WHEN 65 THEN 'quarantaine_meero_photo_diff'
                        WHEN 69 THEN 'meero_stop_before_create'
                        WHEN 91 THEN 'quarantaine_meero_error'
                        WHEN 96 THEN 'quarantaine_meero_manuel'
                        WHEN 97 THEN 'quarantaine_meero'
                        WHEN 98 THEN 'quarantaine_after_publication'
                        WHEN 99 THEN 'quarantaine'
                        ELSE 'inconnu'
                    END AS etat_libelle
        FROM veh_json_partenaire v
        LEFT JOIN offre o ON o.id = v.offre
        WHERE v.created_at >= DATE(${dateAujourdhui})
        AND v.created_at < DATE_ADD(DATE(${dateAujourdhui}), INTERVAL 1 DAY)
    `;
    
    stream<record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string etat_libelle;
    }, error?> resultStream = dbClient->query(query);
    
    json[] results = [];
    check from record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string etat_libelle;
    } row in resultStream
        do {
            json offre = {
                id: row.id,
                id_offre: row.id_offre is int ? row.id_offre : null,
                "source": "partenaire",
                etat_id: row.etat,
                etat: row.etat_libelle,
                type_id: row.type_id,
                "type": row.fournisseur.includes("VO") ? "VO" : "VN",
                fournisseur: row.fournisseur,
                date_creation: time:utcToString(row.created_at),
                date_mise_a_jour: time:utcToString(row.updated_at)
            };
            results.push(offre);
        };
    
    return results;
}

// Récupérer les mises à jour des partenaires
public isolated function getUpdatedOffersFromPartenaires(string dateAujourdhui) returns json[]|error {
     log:printInfo("dateAujourdhui..."+ dateAujourdhui);
    sql:ParameterizedQuery query = `
        SELECT 
            v.id,
            v.offre AS id_offre,
            v.etat,
            v.created_at,
            v.update_at AS updated_at,
            'partenaire' AS source,
            v.type AS type_id,
                    CASE v.type
                        WHEN 0 THEN 'ELITE_VO'
                        WHEN 1 THEN 'BMC_VN'
                        WHEN 2 THEN 'BMC_VO'
                        WHEN 3 THEN 'PROXAUTO_VO'
                        WHEN 4 THEN 'STARTERRE_VO'
                        WHEN 5 THEN 'STARTERRE_VN'
                        WHEN 6 THEN 'OKAZIUM_VO'
                        WHEN 7 THEN 'IMEXSO_VN'
                        WHEN 8 THEN 'EDPAUTO_VN'
                        WHEN 9 THEN 'EDPAUTO_VO'
                        WHEN 10 THEN 'IMEXSO_VO'
                        WHEN 55 THEN 'PROXAUTO_KEPLER_VO'
                        WHEN 99 THEN 'QUARANTAINE_VO'
                        ELSE 'AUTRE'
                    END AS fournisseur,
                    CASE v.type
                        WHEN 0 THEN 'VO'
                        WHEN 1 THEN 'VN'
                        WHEN 2 THEN 'VO'
                        WHEN 3 THEN 'VO'
                        WHEN 4 THEN 'VO'
                        WHEN 5 THEN 'VN'
                        WHEN 6 THEN 'VO'
                        WHEN 7 THEN 'VN'
                        WHEN 8 THEN 'VN'
                        WHEN 9 THEN 'VO'
                        WHEN 10 THEN 'VO'
                        WHEN 55 THEN 'VO'
                        WHEN 99 THEN 'VO'
                        ELSE 'AUTRE'
                    END AS type,
                    CASE v.etat
                        WHEN -1 THEN 'etat à vérifier'
                        WHEN 0 THEN 'etat json'
                        WHEN 1 THEN 'json_elite_ok'
                        WHEN 2 THEN 'offre_initiale'
                        WHEN 3 THEN 'vehicule_a_creer'
                        WHEN 4 THEN 'vehicule_cree'
                        WHEN 5 THEN 'stock_maj_ok'
                        WHEN 6 THEN 'color_options_ok'
                        WHEN 7 THEN 'photos_ok'
                        WHEN 8 THEN 'stock_fin'
                        WHEN 9 THEN 'attente_activation'
                        WHEN 10 THEN 'stock_actif'
                        WHEN 12 THEN 'attente_offre_fo'
                        WHEN 15 THEN 'en_erreur'
                        WHEN 20 THEN 'pas_de_maj'
                        WHEN 25 THEN 'a_supprimer'
                        WHEN 26 THEN 'supprime'
                        WHEN 50 THEN 'meero'
                        WHEN 51 THEN 'meero_to_send'
                        WHEN 52 THEN 'meero_send'
                        WHEN 53 THEN 'meero_traitement_auto'
                        WHEN 54 THEN 'meero_traitement_final'
                        WHEN 55 THEN 'meero_ok'
                        WHEN 59 THEN 'meero_erreur'
                        WHEN 60 THEN 'attente_verif_meero_manuelle'
                        WHEN 65 THEN 'quarantaine_meero_photo_diff'
                        WHEN 69 THEN 'meero_stop_before_create'
                        WHEN 91 THEN 'quarantaine_meero_error'
                        WHEN 96 THEN 'quarantaine_meero_manuel'
                        WHEN 97 THEN 'quarantaine_meero'
                        WHEN 98 THEN 'quarantaine_after_publication'
                        WHEN 99 THEN 'quarantaine'
                        ELSE 'inconnu'
                    END AS etat_libelle
        FROM veh_json_partenaire v
        LEFT JOIN offre o ON o.id = v.offre
        WHERE v.update_at >= DATE(${dateAujourdhui})
        AND v.update_at < DATE_ADD(DATE(${dateAujourdhui}), INTERVAL 1 DAY)
        AND v.update_at > v.created_at
    `;
    
    stream<record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string etat_libelle;
    }, error?> resultStream = dbClient->query(query);
    
    json[] results = [];
    check from record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string etat_libelle;
    } row in resultStream
        do {
            json offre = {
                id: row.id,
                id_offre: row.id_offre is int ? row.id_offre : null,
                "source": "partenaire",
                etat_id: row.etat,
                etat: row.etat_libelle,
                type_id: row.type_id,
                "type": row.fournisseur.includes("VO") ? "VO" : "VN",
                fournisseur: row.fournisseur,
                date_creation: time:utcToString(row.created_at),
                date_mise_a_jour: time:utcToString(row.updated_at)
            };
            results.push(offre);
        };
    
    return results;
}

// Récupérer les nouvelles offres de Starterre
public isolated function getNewOffersFromStarterre(string dateAujourdhui) returns json[]|error {
    log:printInfo("🔍 Recherche des nouvelles offres Starterre pour la date: " + dateAujourdhui);
    sql:ParameterizedQuery query = `
        SELECT 
            v.id,
            v.offre AS id_offre,
            v.etat,
            v.created_at,
            v.update_at,
            v.numero_dossier,
            'starterre' AS source,
            v.type AS type_id,
            CASE v.type
                WHEN 1 THEN 'STARTERRE_VN'
                WHEN 2 THEN 'STARTERRE_VO'
                ELSE 'STARTERRE_AUTRE'
            END AS fournisseur,
            CASE v.type
                WHEN 1 THEN 'VN'
                WHEN 2 THEN 'VO'
                ELSE 'AUTRE'
            END AS type,
                    CASE v.etat
                        WHEN -1 THEN 'etat à vérifier'
                        WHEN 0 THEN 'etat json'
                        WHEN 1 THEN 'json_elite_ok'
                        WHEN 2 THEN 'offre_initiale'
                        WHEN 3 THEN 'color_trouve'
                        WHEN 4 THEN 'color_vide'
                        WHEN 5 THEN 'offre_stock_begin'
                        WHEN 6 THEN 'offre_stock_color'
                        WHEN 7 THEN 'offre_stock_equipement'
                        WHEN 8 THEN 'offre_stock_remise'
                        WHEN 9 THEN 'offre_stock'
                        WHEN 10 THEN 'offre_stock_publie'
                        WHEN 11 THEN 'vn_quarantaine'
                        WHEN 12 THEN 'vo_quarantaine'
                        WHEN 13 THEN 'no_mec'
                        WHEN 14 THEN 'vo_not_publie'
                        WHEN 15 THEN 'error'
                        WHEN 16 THEN 'quarantaine_sans_offre'
                        WHEN 17 THEN 'vo_non_dispo'
                        WHEN 20 THEN 'a_supprimer'
                        WHEN 25 THEN 'supprime'
                        ELSE 'inconnu'
                    END AS etat_libelle
        FROM veh_json_starterre v
        LEFT JOIN offre o ON o.id = v.offre
        WHERE v.created_at >= DATE(${dateAujourdhui})
        AND v.created_at < DATE_ADD(DATE(${dateAujourdhui}), INTERVAL 1 DAY)
    `;
    
    stream<record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc update_at;
        string numero_dossier;
        int type_id;
        string fournisseur;
        string etat_libelle;
    }, error?> resultStream = dbClient->query(query);
    
    json[] results = [];
    check from record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc update_at;
        string numero_dossier;
        int type_id;
        string fournisseur;
        string etat_libelle;
    } row in resultStream
        do {
            json offre = {
                id: row.id,
                id_offre: row.id_offre is int ? row.id_offre : null,
                "source": "starterre",
                etat_id: row.etat,
                etat: row.etat_libelle,
                type_id: row.type_id,
                "type": row.fournisseur.includes("VO") ? "VO" : "VN",
                fournisseur: row.fournisseur,
                date_creation: time:utcToString(row.created_at),
                date_mise_a_jour: time:utcToString(row.update_at),
                numero_dossier: row.numero_dossier
            };
            results.push(offre);
        };
    
    log:printInfo("🔍 Nombre total d'offres Starterre trouvées: " + results.length().toString());
    return results;
}

// Récupérer les offres "publiées" du jour (etat JSON = 10)
public isolated function getPublishedOffersForDate(string dateAujourdhui) returns json[]|error {

    json[] partenairesResults = check getPublishedPartenairesOffers(dateAujourdhui);
    json[] starterreResults = check getPublishedStarterreOffers(dateAujourdhui);
    
    // Combiner les résultats
    json[] allResults = [];
    allResults.push(...partenairesResults);
    allResults.push(...starterreResults);
    
    return allResults;
}

// fonction pour les offres partenaires publiées
isolated function getPublishedPartenairesOffers(string dateAujourdhui) returns json[]|error {
    sql:ParameterizedQuery query = `
        SELECT 
            v.id,
            v.offre AS id_offre,
            v.etat,
            v.created_at,
            v.update_at AS updated_at,
            v.type AS type_id,
            CASE v.type
                WHEN 0 THEN 'ELITE_VO'
                WHEN 1 THEN 'BMC_VN'
                WHEN 2 THEN 'BMC_VO'
                WHEN 3 THEN 'PROXAUTO_VO'
                WHEN 4 THEN 'STARTERRE_VO'
                WHEN 5 THEN 'STARTERRE_VN'
                WHEN 6 THEN 'OKAZIUM_VO'
                WHEN 7 THEN 'IMEXSO_VN'
                WHEN 8 THEN 'EDPAUTO_VN'
                WHEN 9 THEN 'EDPAUTO_VO'
                WHEN 10 THEN 'IMEXSO_VO'
                WHEN 55 THEN 'PROXAUTO_KEPLER_VO'
                WHEN 99 THEN 'QUARANTAINE_VO'
                ELSE 'AUTRE'
            END AS fournisseur,
            CASE v.type
                WHEN 0 THEN 'VO'
                WHEN 1 THEN 'VN'
                WHEN 2 THEN 'VO'
                WHEN 3 THEN 'VO'
                WHEN 4 THEN 'VO'
                WHEN 5 THEN 'VN'
                WHEN 6 THEN 'VO'
                WHEN 7 THEN 'VN'
                WHEN 8 THEN 'VN'
                WHEN 9 THEN 'VO'
                WHEN 10 THEN 'VO'
                WHEN 55 THEN 'VO'
                WHEN 99 THEN 'VO'
                ELSE 'AUTRE'
            END AS type_str
        FROM veh_json_partenaire v
        JOIN offre o ON o.id = v.offre
        WHERE v.etat = 10
          AND v.update_at >= DATE(${dateAujourdhui})
          AND v.update_at < DATE_ADD(DATE(${dateAujourdhui}), INTERVAL 1 DAY)
          AND o.etat = 1
          AND (o.is_stock = 0 OR o.etat_vente = 0)
    `;

    stream<record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string type_str;
    }, error?> resultStream = dbClient->query(query);

    json[] results = [];
    check from record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string type_str;
    } row in resultStream
        do {
            json offre = {
                id: row.id,
                id_offre: row.id_offre is int ? row.id_offre : null,
                "source": "partenaire",
                etat_id: row.etat,
                etat: "active",
                type_id: row.type_id,
                "type": row.type_str,
                fournisseur: row.fournisseur,
                date_creation: time:utcToString(row.created_at),
                date_mise_a_jour: time:utcToString(row.updated_at)
            };
            results.push(offre);
        };

    return results;
}

// fonction pour les offres starterre publiées
isolated function getPublishedStarterreOffers(string dateAujourdhui) returns json[]|error {
    sql:ParameterizedQuery query = `
        SELECT 
            v.id,
            v.offre AS id_offre,
            v.etat,
            v.created_at,
            v.update_at AS updated_at,
            v.type AS type_id,
            CASE v.type
                WHEN 1 THEN 'STARTERRE_VN'
                WHEN 2 THEN 'STARTERRE_VO'
                ELSE 'STARTERRE_AUTRE'
            END AS fournisseur,
            CASE v.type
                WHEN 1 THEN 'VN'
                WHEN 2 THEN 'VO'
                ELSE 'AUTRE'
            END AS type_str,
            v.numero_dossier
        FROM veh_json_starterre v
        JOIN offre o ON o.id = v.offre
        WHERE v.etat = 10
          AND v.update_at >= DATE(${dateAujourdhui})
          AND v.update_at < DATE_ADD(DATE(${dateAujourdhui}), INTERVAL 1 DAY)
          AND o.etat = 1
          AND (o.is_stock = 0 OR o.etat_vente = 0)
    `;

    stream<record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string type_str;
        string numero_dossier;
    }, error?> resultStream = dbClient->query(query);

    json[] results = [];
    check from record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string type_str;
        string numero_dossier;
    } row in resultStream
        do {
            json offre = {
                id: row.id,
                id_offre: row.id_offre is int ? row.id_offre : null,
                "source": "starterre",
                etat_id: row.etat,
                etat: "active",
                type_id: row.type_id,
                "type": row.type_str,
                fournisseur: row.fournisseur,
                date_creation: time:utcToString(row.created_at),
                date_mise_a_jour: time:utcToString(row.updated_at),
                numero_dossier: row.numero_dossier
            };
            results.push(offre);
        };

    return results;
}

// Récupérer les offres vendues du jour (offre.etat_vente = 3)
public isolated function getSoldOffersForDate(string dateAujourdhui) returns json[]|error {
    
    json[] partenairesResults = check getSoldPartenairesOffers(dateAujourdhui);
    json[] starterreResults = check getSoldStarterreOffers(dateAujourdhui);
    
    // Combiner les résultats
    json[] allResults = [];
    allResults.push(...partenairesResults);
    allResults.push(...starterreResults);
    
    return allResults;
}

// fonction pour les offres partenaires vendues
isolated function getSoldPartenairesOffers(string dateAujourdhui) returns json[]|error {
    sql:ParameterizedQuery query = `
        SELECT 
            v.id,
            v.offre AS id_offre,
            v.etat,
            v.created_at,
            v.update_at AS updated_at,
            v.type AS type_id,
            CASE v.type
                WHEN 0 THEN 'ELITE_VO'
                WHEN 1 THEN 'BMC_VN'
                WHEN 2 THEN 'BMC_VO'
                WHEN 3 THEN 'PROXAUTO_VO'
                WHEN 4 THEN 'STARTERRE_VO'
                WHEN 5 THEN 'STARTERRE_VN'
                WHEN 6 THEN 'OKAZIUM_VO'
                WHEN 7 THEN 'IMEXSO_VN'
                WHEN 8 THEN 'EDPAUTO_VN'
                WHEN 9 THEN 'EDPAUTO_VO'
                WHEN 10 THEN 'IMEXSO_VO'
                WHEN 55 THEN 'PROXAUTO_KEPLER_VO'
                WHEN 99 THEN 'QUARANTAINE_VO'
                ELSE 'AUTRE'
            END AS fournisseur,
            CASE v.type
                WHEN 0 THEN 'VO'
                WHEN 1 THEN 'VN'
                WHEN 2 THEN 'VO'
                WHEN 3 THEN 'VO'
                WHEN 4 THEN 'VO'
                WHEN 5 THEN 'VN'
                WHEN 6 THEN 'VO'
                WHEN 7 THEN 'VN'
                WHEN 8 THEN 'VN'
                WHEN 9 THEN 'VO'
                WHEN 10 THEN 'VO'
                WHEN 55 THEN 'VO'
                WHEN 99 THEN 'VO'
                ELSE 'AUTRE'
            END AS type_str
        FROM veh_json_partenaire v
        JOIN offre o ON o.id = v.offre
        WHERE o.etat_vente = 3
          AND v.update_at >= DATE(${dateAujourdhui})
          AND v.update_at < DATE_ADD(DATE(${dateAujourdhui}), INTERVAL 1 DAY)
    `;

    stream<record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string type_str;
    }, error?> resultStream = dbClient->query(query);

    json[] results = [];
    check from record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string type_str;
    } row in resultStream
        do {
            json offre = {
                id: row.id,
                id_offre: row.id_offre is int ? row.id_offre : null,
                "source": "partenaire",
                etat_id: row.etat,
                etat: "vendue",
                type_id: row.type_id,
                "type": row.type_str,
                fournisseur: row.fournisseur,
                date_creation: time:utcToString(row.created_at),
                date_mise_a_jour: time:utcToString(row.updated_at)
            };
            results.push(offre);
        };

    return results;
}

// fonction pour les offres starterre vendues
isolated function getSoldStarterreOffers(string dateAujourdhui) returns json[]|error {
    sql:ParameterizedQuery query = `
        SELECT 
            v.id,
            v.offre AS id_offre,
            v.etat,
            v.created_at,
            v.update_at AS updated_at,
            v.type AS type_id,
            CASE v.type
                WHEN 1 THEN 'STARTERRE_VN'
                WHEN 2 THEN 'STARTERRE_VO'
                ELSE 'STARTERRE_AUTRE'
            END AS fournisseur,
            CASE v.type
                WHEN 1 THEN 'VN'
                WHEN 2 THEN 'VO'
                ELSE 'AUTRE'
            END AS type_str,
            v.numero_dossier
        FROM veh_json_starterre v
        JOIN offre o ON o.id = v.offre
        WHERE o.etat_vente = 3
          AND v.update_at >= DATE(${dateAujourdhui})
          AND v.update_at < DATE_ADD(DATE(${dateAujourdhui}), INTERVAL 1 DAY)
    `;

    stream<record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string type_str;
        string numero_dossier;
    }, error?> resultStream = dbClient->query(query);

    json[] results = [];
    check from record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string type_str;
        string numero_dossier;
    } row in resultStream
        do {
            json offre = {
                id: row.id,
                id_offre: row.id_offre is int ? row.id_offre : null,
                "source": "starterre",
                etat_id: row.etat,
                etat: "vendue",
                type_id: row.type_id,
                "type": row.type_str,
                fournisseur: row.fournisseur,
                date_creation: time:utcToString(row.created_at),
                date_mise_a_jour: time:utcToString(row.updated_at),
                numero_dossier: row.numero_dossier
            };
            results.push(offre);
        };

    return results;
}

// Récupérer les offres en quarantaine du jour
public isolated function getQuarantinedOffersForDate(string dateAujourdhui) returns json[]|error {
    
    json[] partenairesResults = check getQuarantinedPartenairesOffers(dateAujourdhui);
    json[] starterreResults = check getQuarantinedStarterreOffers(dateAujourdhui);
    
    // Combiner les résultats
    json[] allResults = [];
    allResults.push(...partenairesResults);
    allResults.push(...starterreResults);
    
    return allResults;
}

// fonction pour les offres partenaires en quarantaine
isolated function getQuarantinedPartenairesOffers(string dateAujourdhui) returns json[]|error {
    sql:ParameterizedQuery query = `
        SELECT 
            v.id,
            v.offre AS id_offre,
            v.etat,
            v.created_at,
            v.update_at AS updated_at,
            v.type AS type_id,
            CASE v.type
                WHEN 0 THEN 'ELITE_VO'
                WHEN 1 THEN 'BMC_VN'
                WHEN 2 THEN 'BMC_VO'
                WHEN 3 THEN 'PROXAUTO_VO'
                WHEN 4 THEN 'STARTERRE_VO'
                WHEN 5 THEN 'STARTERRE_VN'
                WHEN 6 THEN 'OKAZIUM_VO'
                WHEN 7 THEN 'IMEXSO_VN'
                WHEN 8 THEN 'EDPAUTO_VN'
                WHEN 9 THEN 'EDPAUTO_VO'
                WHEN 10 THEN 'IMEXSO_VO'
                WHEN 55 THEN 'PROXAUTO_KEPLER_VO'
                WHEN 99 THEN 'QUARANTAINE_VO'
                ELSE 'AUTRE'
            END AS fournisseur,
            CASE v.type
                WHEN 0 THEN 'VO'
                WHEN 1 THEN 'VN'
                WHEN 2 THEN 'VO'
                WHEN 3 THEN 'VO'
                WHEN 4 THEN 'VO'
                WHEN 5 THEN 'VN'
                WHEN 6 THEN 'VO'
                WHEN 7 THEN 'VN'
                WHEN 8 THEN 'VN'
                WHEN 9 THEN 'VO'
                WHEN 10 THEN 'VO'
                WHEN 55 THEN 'VO'
                WHEN 99 THEN 'VO'
                ELSE 'AUTRE'
            END AS type_str,
            CASE v.etat
                WHEN 65 THEN 'Attente verif photo differente'
                WHEN 91 THEN 'url origin non trouve dans meero'
                WHEN 96 THEN 'mise en quarantaine meero'
                WHEN 97 THEN 'quarantaine meero'
                WHEN 98 THEN 'quarantaine avant activation'
                WHEN 99 THEN 'quarantaine'
                ELSE 'quarantaine'
            END AS etat_libelle
        FROM veh_json_partenaire v
        LEFT JOIN offre o ON o.id = v.offre
        WHERE v.etat IN (65, 91, 96, 97, 98, 99)
          AND v.update_at >= DATE(${dateAujourdhui})
          AND v.update_at < DATE_ADD(DATE(${dateAujourdhui}), INTERVAL 1 DAY)
    `;

    stream<record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string type_str;
        string etat_libelle;
    }, error?> resultStream = dbClient->query(query);

    json[] results = [];
    check from record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string type_str;
        string etat_libelle;
    } row in resultStream
        do {
            json offre = {
                id: row.id,
                id_offre: row.id_offre is int ? row.id_offre : null,
                "source": "partenaire",
                etat_id: row.etat,
                etat: row.etat_libelle,
                type_id: row.type_id,
                "type": row.type_str,
                fournisseur: row.fournisseur,
                date_creation: time:utcToString(row.created_at),
                date_mise_a_jour: time:utcToString(row.updated_at)
            };
            results.push(offre);
        };

    return results;
}

// fonction pour les offres starterre en quarantaine
isolated function getQuarantinedStarterreOffers(string dateAujourdhui) returns json[]|error {
    sql:ParameterizedQuery query = `
        SELECT 
            v.id,
            v.offre AS id_offre,
            v.etat,
            v.created_at,
            v.update_at AS updated_at,
            v.type AS type_id,
            CASE v.type
                WHEN 1 THEN 'STARTERRE_VN'
                WHEN 2 THEN 'STARTERRE_VO'
                ELSE 'STARTERRE_AUTRE'
            END AS fournisseur,
            CASE v.type
                WHEN 1 THEN 'VN'
                WHEN 2 THEN 'VO'
                ELSE 'AUTRE'
            END AS type_str,
            v.numero_dossier,
            CASE v.etat
                WHEN 11 THEN 'vn_quarantaine'
                WHEN 12 THEN 'vo_quarantaine'
                WHEN 16 THEN 'quarantaine_sans_offre'
                ELSE 'quarantaine'
            END AS etat_libelle
        FROM veh_json_starterre v
        LEFT JOIN offre o ON o.id = v.offre
        WHERE v.etat IN (11, 12, 16)
          AND v.update_at >= DATE(${dateAujourdhui})
          AND v.update_at < DATE_ADD(DATE(${dateAujourdhui}), INTERVAL 1 DAY)
    `;

    stream<record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string type_str;
        string etat_libelle;
        string numero_dossier;
    }, error?> resultStream = dbClient->query(query);

    json[] results = [];
    check from record {
        int id;
        int? id_offre;
        int etat;
        time:Utc created_at;
        time:Utc updated_at;
        int type_id;
        string fournisseur;
        string type_str;
        string etat_libelle;
        string numero_dossier;
    } row in resultStream
        do {
            json offre = {
                id: row.id,
                id_offre: row.id_offre is int ? row.id_offre : null,
                "source": "starterre",
                etat_id: row.etat,
                etat: row.etat_libelle,
                type_id: row.type_id,
                "type": row.type_str,
                fournisseur: row.fournisseur,
                date_creation: time:utcToString(row.created_at),
                date_mise_a_jour: time:utcToString(row.updated_at),
                numero_dossier: row.numero_dossier
            };
            results.push(offre);
        };

    return results;
}


// === HISTORISATION QUOTIDIENNE DU PROCESSUS DE PUBLICATION ===
// On historise, par exécution, les offres à des étapes clés: new, update, published, sold, quarantine.
// Ces données servent d'assise aux comparaisons jour/jour et aux indicateurs.
isolated function formatTimestampForMySQL(string isoTimestamp) returns string {
    // Format ISO: 2025-10-01T12:24:02Z ou 2025-10-01T12:24:02.123Z
    // Format cible: 2025-10-01 12:24:02
    if isoTimestamp.length() < 19 {
        return isoTimestamp; // retourner tel quel si trop court
    }
    string datePart = isoTimestamp.substring(0, 10); // YYYY-MM-DD
    string timePart = isoTimestamp.substring(11, 19); // HH:MM:SS
    return datePart + " " + timePart;
}

// Création de la table d'historique si non existante
// on stocke un instantané par exécution et par étape du process (new/update/published/sold/quarantine) pour chaque offre
isolated function createOfferPublicationHistoryTable() returns error? {
    sql:ParameterizedQuery createTableQuery = `
        CREATE TABLE IF NOT EXISTS offer_publication_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            snapshot_date DATETIME NOT NULL,
            process_stage ENUM('new','update','published','sold','quarantine') NOT NULL,
            source VARCHAR(32) NOT NULL,
            fournisseur VARCHAR(64) NOT NULL,
            type_str VARCHAR(8) NOT NULL,
            id_veh_json_partenaire INT NULL,
            id_offre INT NULL,
            numero_dossier VARCHAR(64) NULL,
            etat_id INT NULL,
            etat_libelle VARCHAR(128) NULL,
            date_creation DATETIME NULL,
            date_mise_a_jour DATETIME NULL,
            INDEX idx_snapshot_stage (snapshot_date, process_stage),
            INDEX idx_id_offre_stage (id_offre, process_stage, snapshot_date),
            INDEX idx_fournisseur_type (fournisseur, type_str),
            INDEX idx_source (source)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `;
    sql:ExecutionResult _ = check dbClient->execute(createTableQuery);
    return;
}

// Enregistrer une ligne d'historique
isolated function insertOfferPublicationHistoryRow(
    string snapshotDate,
    string processStage,
    json offre
) returns error? {
    var vId = jsondata:read(offre, `$.id`);
    int? idVehJsonPartenaire = vId is error ? () : <int?>vId;
    var vIdOffre = jsondata:read(offre, `$.id_offre`);
    int? idOffre = vIdOffre is error ? () : <int?>vIdOffre;
    var vSource = jsondata:read(offre, `$.source`);
    string sourceVal = vSource is error ? "" : vSource.toString();
    var vTypeStr = jsondata:read(offre, `$.type`);
    string typeStr = vTypeStr is error ? "" : vTypeStr.toString();
    var vFournisseur = jsondata:read(offre, `$.fournisseur`);
    string fournisseur = vFournisseur is error ? "" : vFournisseur.toString();
    var vEtatId = jsondata:read(offre, `$.etat_id`);
    int? etatId = vEtatId is error ? () : <int?>vEtatId;
    var vEtat = jsondata:read(offre, `$.etat`);
    string etatLibelle = vEtat is error ? "" : vEtat.toString();
    var vNumeroDossier = jsondata:read(offre, `$.numero_dossier`);
    string? numeroDossier = vNumeroDossier is error ? () : vNumeroDossier.toString();
    var vDateCreation = jsondata:read(offre, `$.date_creation`);
    string? dateCreation = vDateCreation is error ? () : formatTimestampForMySQL(vDateCreation.toString());
    var vDateMaj = jsondata:read(offre, `$.date_mise_a_jour`);
    string? dateMaj = vDateMaj is error ? () : formatTimestampForMySQL(vDateMaj.toString());

    sql:ParameterizedQuery insertQuery = `
        INSERT INTO offer_publication_history (
            snapshot_date, process_stage, source, fournisseur, type_str,
            id_veh_json_partenaire, id_offre, numero_dossier, etat_id, etat_libelle,
            date_creation, date_mise_a_jour
        ) VALUES (
            ${snapshotDate}, ${processStage}, ${sourceVal}, ${fournisseur}, ${typeStr},
            ${idVehJsonPartenaire}, ${idOffre}, ${numeroDossier}, ${etatId}, ${etatLibelle},
            ${dateCreation}, ${dateMaj}
        )
    `;
    sql:ExecutionResult _ = check dbClient->execute(insertQuery);
    return;
}

// Sauvegarder l'instantané quotidien
public isolated function saveOfferPublicationSnapshot(
    string snapshotDate,
    json[] nouvelles,
    json[] misesAJour,
    json[] publiees,
    json[] vendues,
    json[] quarantaine
) returns error? {
    // s'assurer que la table existe
    check createOfferPublicationHistoryTable();

    // Nouvelles
    foreach var offre in nouvelles {
        check insertOfferPublicationHistoryRow(snapshotDate, "new", offre);
    }
    // Mises à jour
    foreach var offre in misesAJour {
        check insertOfferPublicationHistoryRow(snapshotDate, "update", offre);
    }
    // Publiées
    foreach var offre in publiees {
        check insertOfferPublicationHistoryRow(snapshotDate, "published", offre);
    }
    // Vendues
    foreach var offre in vendues {
        check insertOfferPublicationHistoryRow(snapshotDate, "sold", offre);
    }
    // Quarantaine
    foreach var offre in quarantaine {
        check insertOfferPublicationHistoryRow(snapshotDate, "quarantine", offre);
    }

    return;
}
