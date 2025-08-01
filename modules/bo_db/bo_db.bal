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
