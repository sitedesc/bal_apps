import ballerina/sql;
import ballerinax/postgresql;
import ballerina/time;


public type Offre record {
    int objectID;
    int id;
    boolean isOccasion;
    boolean isUtilitaire;
    string? disponibiliteForFO;
    string? segmentEliteGroup;
    string marque;
    int marqueId;
    int modelId;
    string? modelNormalized;
    string? motorisation;
    string? finition;
    decimal? remise;
    decimal? priceForFront;
    decimal? rent;
    json equipments;
    string? transmissionNormalized;
    int? nbPorte;
    string? frontPicture;
    json ColorsImages;
    json OffreImages;
    int? nbCouleurs;
    boolean isReserved;
    boolean isSpecial;
    int? co2;
    boolean loa;
    decimal? avantageFinalWithADiscretion;
    string? normalizedType;
    string? marqueModelNormalizedAutoComplete;
    decimal? offerAdvantageTI;
    decimal? priceForFrontLoa;
    decimal? offerAdvantageTiLoa;
    decimal? avantageFinalElastic;
    string? brandsWithLowDiscountAllowed;
    decimal? maxMontantReprise;
    string? typeForRecherche;
    string? hashKeyVersion;
    int? disponibiliteForSort;
    string? marqueModeleAutoComplete;
    string? motorisationForElastic;
    string? finitionForElastic;
    int? nbSiege;
    json couleurExterieurNormalized;
    int? puissanceFiscaleNormalized;
    string? energieNormalized;
    int? offreEurotax;
    string? referenceEurotax;
    boolean flashSale;
    boolean isIndexableElastica;
    decimal? prixCatalogueForLease;
    string? vignette;
    boolean isVo;
    int? kilometrage;
    int? anneeMiseEnCirculation;
    string? modelGroupeNiveau1;
    int? marqueEurotax;
    boolean eaOccasion;
    boolean IsEnabledOrReservedClient;
    string? modelNomCompl;
    int sortOccasion;
    int? saleSatus;
    string? dateMiseEnCirculation;
    string? energie;
    int nature;
    string? categoryNormalized;
    string? marqueSlug;
    string? modeleSlug;
    int? eurotaxId;
    int? eurotaxModeleId;
    int? typeVehicule;
    string? transmission;
    boolean isNouveaute;
    string? label;
    int? sortAlgolia;
    string? createdAt;
    string? dateArrivee;
    boolean isFrenchDaysPromo;
    json loyers;
};

public type Loyer record {
    int objectID;
    int id;
    int euroTax;
    int apport;
    int kilometres;
    int nbLoyer;
    decimal premierLoyer;
    decimal loyerMensuel;
    decimal valeurRachat;
    decimal coutTotal;
    decimal adiit;
    decimal perteTotale;
    string market;
    int version;
    int offreInit;
    int offreId;
    int nature;
    string marque;
    string? modelGroupeNiveau1;
    string? modelNomCompl;
    string? finition;
    string? energieNormalized;
    int? kilometrage;
    int? anneeMiseEnCirculation;
    string? disponibiliteForFO;
    decimal? avantageFinalWithADiscretion;
    string? segmentEliteGroup;
    string? motorisation;
    string? transmissionNormalized;
    int? nbPorte;
    int? nbSiege;
    json couleurExterieurNormalized;
    int? puissanceFiscaleNormalized;
    int? co2;
    decimal? priceForFront;
    decimal? remise;
    string? modelNormalized;
    string? marqueModeleAutoComplete;
    string? marqueModelNormalizedAutoComplete;
    decimal? prixCatalogueForLease;
    string? vignette;
    string? energie;
    boolean flashSale;
    json offreImages;
    boolean isReserved;
    string? frontPicture;
    json colorsImages;
    boolean isOccasion;
    boolean isSpecial;
    json equipments;
    int? nbCouleurs;
    decimal? maxMontantReprise;
    decimal? offerAdvantageTiLoa;
    string? brandsWithLowDiscountAllowed;
    decimal? avantageFinalElastic;
    decimal? rent;
    boolean loa;
    boolean isVo;
    string? marqueSlug;
    string? modeleSlug;
    int? eurotaxId;
    int? eurotaxModeleId;
    string? normalizedType;
    boolean isUtilitaire;
    string? typeForRecherche;
    int? disponibiliteForSort;
    string? finitionForElastic;
    string? motorisationForElastic;
    boolean isNouveaute;
    string? label;
    int? sortAlgolia;
    string? createdAt;
    string? dateArrivee;
    boolean isFrenchDaysPromo;
};

public type Conf record {
    string host;
    int port = 3306;
    string user;
    string password;
    string database;
};

public configurable Conf conf = ?;
final postgresql:Client dbClient = check new (conf.host, conf.user, conf.password, conf.database, conf.port);

# Description.
# + return - return value description
public function getOffres() returns stream<Offre, sql:Error?> {
    // Requête SQL avec mapping des colonnes
sql:ParameterizedQuery query = `
    SELECT
        id as "objectID",
        id as "id",
        is_occasion as "isOccasion",
        is_utilitaire as "isUtilitaire",
        disponibilite_for_fo as "disponibiliteForFO",
        segment_elite_group as "segmentEliteGroup",
        marque as "marque",
        marque_id as "marqueId",
        model_id as "modelId",
        model_normalized as "modelNormalized",
        motorisation as "motorisation",
        finition as "finition",
        ROUND(remise::numeric, 2) as "remise",
        ROUND(price_for_front::numeric, 2) as "priceForFront",
        ROUND(rent::numeric, 2) as "rent",
        equipments as "equipments",
        transmission_normalized as "transmissionNormalized",
        nb_porte as "nbPorte",
        front_picture as "frontPicture",
        colors_images as "ColorsImages",
        offre_images as "OffreImages",
        nb_couleurs as "nbCouleurs",
        is_reserved as "isReserved",
        is_special as "isSpecial",
        co2 as "co2",
        loa as "loa",
        ROUND(avantage_final_with_adiscretion::numeric, 2) as "avantageFinalWithADiscretion",
        normalized_type as "normalizedType",
        marque_model_normalized_auto_complete as "marqueModelNormalizedAutoComplete",
        ROUND(offer_advantage_ti::numeric, 2) as "offerAdvantageTI",
        ROUND(price_for_front_loa::numeric, 2) as "priceForFrontLoa",
        ROUND(offer_advantage_ti_loa::numeric, 2) as "offerAdvantageTiLoa",
        ROUND(avantage_final_elastic::numeric, 2) as "avantageFinalElastic",
        brands_with_low_discount_allowed as "brandsWithLowDiscountAllowed",
        ROUND(max_montant_reprise::numeric, 2) as "maxMontantReprise",
        type_for_recherche as "typeForRecherche",
        hash_key_version as "hashKeyVersion",
        disponibilite_for_sort as "disponibiliteForSort",
        marque_modele_auto_complete as "marqueModeleAutoComplete",
        motorisation_for_elastic as "motorisationForElastic",
        finition_for_elastic as "finitionForElastic",
        nb_siege as "nbSiege",
        couleur_exterieur_normalized as "couleurExterieurNormalized",
        puissance_fiscale_normalized as "puissanceFiscaleNormalized",
        energie_normalized as "energieNormalized",
        offre_eurotax as "offreEurotax",
        reference_eurotax as "referenceEurotax",
        COALESCE ((flash_sale > 0), false) AS "flashSale",
        is_indexable_elastica as "isIndexableElastica",
        ROUND(prix_catalogue_for_lease::numeric, 2) as "prixCatalogueForLease",
        vignette as "vignette",
        is_vo as "isVo",
        kilometrage as "kilometrage",
        annee_mise_en_circulation as "anneeMiseEnCirculation",
        model_groupe_niveau1 as "modelGroupeNiveau1",
        marque_eurotax as "marqueEurotax",
        ea_occasion as "eaOccasion",
        is_enabled_or_reserved_client as "IsEnabledOrReservedClient",
        model_nom_compl as "modelNomCompl",
        sort_occasion as "sortOccasion",
        sale_satus as "saleSatus",
        date_mise_en_circulation as "dateMiseEnCirculation",
        energie as "energie",
        nature as "nature",
        marque_slug as "marqueSlug",
        modele_slug as "modeleSlug",
        eurotax_id as "eurotaxId",
        eurotax_modele_id as "eurotaxModeleId",
        type_vehicule as "typeVehicule",
        transmission as "transmission",
        is_nouveaute as "isNouveaute",
        label as "label",
        sort_algolia as "sortAlgolia",
        created_at as "createdAt",
        date_arrivee as "dateArrivee",
            CASE
                WHEN minj.loyer_id IS NULL THEN '[]'::json
                WHEN maxj.loyer_id IS NULL OR minj.loyer_id = maxj.loyer_id THEN json_build_array(minj.loyer_obj)
                ELSE json_build_array(maxj.loyer_obj, minj.loyer_obj)
            END AS loyers
    FROM offre
     LEFT JOIN LATERAL (
        SELECT l.id AS loyer_id,
               json_build_object(
                       'id', l.id,
                       'nb_loyer', l.nb_loyer,
                       'apport', l.apport,
                       'kilometres', l.kilometres,
                       'loyer_mensuel', ROUND(l.loyer_mensuel::numeric, 2)
               ) AS loyer_obj,
               l.loyer_mensuel
        FROM loyer l
        WHERE l.offre_id = offre.id
        ORDER BY l.loyer_mensuel ASC, l.id ASC
        LIMIT 1
    ) AS minj ON TRUE
     LEFT JOIN LATERAL (
        SELECT l.id AS loyer_id,
               json_build_object(
                       'id', l.id,
                       'nb_loyer', l.nb_loyer,
                       'apport', l.apport,
                       'kilometres', l.kilometres,
                       'loyer_mensuel', ROUND(l.loyer_mensuel::numeric, 2)
               ) AS loyer_obj,
               l.loyer_mensuel
        FROM loyer l
        WHERE l.offre_id = offre.id
        ORDER BY l.loyer_mensuel DESC, l.id ASC
        LIMIT 1
    ) AS maxj ON TRUE
    -- for test: WHERE offre.id=87770
`;

    // Exécution de la requête en mode stream
    return dbClient->query(query);
}

public function getLoyers() returns stream<Loyer, sql:Error?> {
    // Requête SQL avec jointure et mapping des colonnes
sql:ParameterizedQuery query = `
    SELECT
        l.id as "objectID",
        l.id as "id",
        l.euro_tax as "euroTax",
        l.apport as "apport",
        l.kilometres as "kilometres",
        l.nb_loyer as "nbLoyer",
        ROUND(l.premier_loyer::numeric, 2) as "premierLoyer",
        ROUND(l.loyer_mensuel::numeric, 2) as "loyerMensuel",
        ROUND(l.valeur_rachat::numeric, 2) as "valeurRachat",
        ROUND(l.cout_total::numeric, 2) as "coutTotal",
        ROUND(l.adiit::numeric, 2) as "adiit",
        ROUND(l.perte_totale::numeric, 2) as "perteTotale",
        l.market as "market",
        l.version as "version",
        l.offre_init as "offreInit",
        l.offre_id as "offreId",

        -- Champs de la table offre
        o.nature as "nature",
        o.marque as "marque",
        o.model_groupe_niveau1 as "modelGroupeNiveau1",
        o.model_nom_compl as "modelNomCompl",
        o.finition as "finition",
        o.energie_normalized as "energieNormalized",
        o.kilometrage as "kilometrage",
        o.annee_mise_en_circulation as "anneeMiseEnCirculation",
        o.disponibilite_for_fo as "disponibiliteForFO",
        ROUND(o.avantage_final_with_adiscretion::numeric, 2) as "avantageFinalWithADiscretion",
        o.segment_elite_group as "segmentEliteGroup",
        o.motorisation as "motorisation",
        o.transmission_normalized as "transmissionNormalized",
        o.nb_porte as "nbPorte",
        o.nb_siege as "nbSiege",
        o.couleur_exterieur_normalized as "couleurExterieurNormalized",
        o.puissance_fiscale_normalized as "puissanceFiscaleNormalized",
        o.co2 as "co2",
        ROUND(o.price_for_front::numeric, 2) as "priceForFront",
        ROUND(o.remise::numeric, 2) as "remise",
        o.model_normalized as "modelNormalized",
        o.marque_modele_auto_complete as "marqueModeleAutoComplete",
        o.marque_model_normalized_auto_complete as "marqueModelNormalizedAutoComplete",
        ROUND(o.prix_catalogue_for_lease::numeric, 2) as "prixCatalogueForLease",
        o.vignette as "vignette",
        o.energie as "energie",
        COALESCE ((o.flash_sale > 0), false) AS "flashSale",
        o.offre_images as "offreImages",
        o.is_reserved as "isReserved",
        o.front_picture as "frontPicture",
        o.colors_images as "colorsImages",
        o.is_occasion as "isOccasion",
        o.is_special as "isSpecial",
        o.equipments as "equipments",
        o.nb_couleurs as "nbCouleurs",
        ROUND(o.max_montant_reprise::numeric, 2) as "maxMontantReprise",
        ROUND(o.offer_advantage_ti_loa::numeric, 2) as "offerAdvantageTiLoa",
        o.brands_with_low_discount_allowed as "brandsWithLowDiscountAllowed",
        ROUND(o.avantage_final_elastic::numeric, 2) as "avantageFinalElastic",
        ROUND(o.rent::numeric, 2) as "rent",
        o.loa as "loa",
        o.is_vo as "isVo",
        o.marque_slug as "marqueSlug",
        o.modele_slug as "modeleSlug",
        o.eurotax_id as "eurotaxId",
        o.eurotax_modele_id as "eurotaxModeleId",
        o.normalized_type as "normalizedType",
        o.is_utilitaire as "isUtilitaire",
        o.type_for_recherche as "typeForRecherche",
        o.disponibilite_for_sort as "disponibiliteForSort",
        o.finition_for_elastic as "finitionForElastic",
        o.motorisation_for_elastic as "motorisationForElastic",
        o.is_nouveaute as "isNouveaute",
        o.label as "label",
        o.sort_algolia as "sortAlgolia",
        o.created_at as "createdAt",
        o.date_arrivee as "dateArrivee"
    FROM loyer l
    JOIN offre o ON l.offre_id = o.id
    -- for test : WHERE o.id=87770
`;

    // Exécution de la requête en mode stream
    return dbClient->query(query);
}

public type JobDates record {|
    time:Utc? last_db_refresh;
    time:Utc? last_indexation;
|};

public function getJobDates() returns JobDates|error {
    JobDates jd = check dbClient->queryRow(
        `SELECT last_db_refresh, last_indexation 
         FROM job_dates 
         LIMIT 1`
    );
    return jd;
}

public function updateLastIndexation(time:Utc? ts = time:utcNow()) returns error? {
    _ = check dbClient->execute(
        `UPDATE job_dates SET last_indexation = ${ts}`
    );
}

public function isDbRefreshMoreRecent() returns boolean|error {
    JobDates jd = check getJobDates();
    if jd.last_db_refresh is () {
        // Pas de last_db_refresh -> toujours false
        return false;
    }
    if jd.last_indexation is () {
        // last_indexation null -> toujours true
        return true;
    }
    return jd.last_db_refresh > jd.last_indexation;
}