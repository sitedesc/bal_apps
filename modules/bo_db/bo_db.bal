import ballerina/log;
import ballerina/sql;
import ballerinax/mysql;

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