import ballerina/sql;
import ballerinax/mysql;

public type DbCredentials record {
    string host;
    int port = 3306;
    string user;
    string password;
    string database;
};

public configurable DbCredentials credentials = ?;

public function getDbClient() returns mysql:Client|sql:Error {
    final mysql:Client|sql:Error dbClient = new (credentials.host, credentials.user, credentials.password, credentials.database, credentials.port);
    return dbClient;
}

public type Quotation record {
    int id;
    json content;
};

public record   {
    0 TODO;
    1 DONE;
    2 ERROR;
} SYNC_STATE = { TODO: 0, DONE: 1, ERROR: 2};

public isolated function getQuotations(mysql:Client dbClient) returns Quotation[]|error {
    Quotation[] quotations = [];
    stream<Quotation, error?> resultStream = (dbClient->query(
        `SELECT id, CAST(message AS JSON) as content FROM itn_bo_message WHERE etat=0`
    ));
    _ = check from Quotation quotation in resultStream
        do {
            quotations.push(quotation);
        };
    _ = check resultStream.close();
    return quotations;
}

public isolated function setQuotationState(mysql:Client dbClient, Quotation quotation, int state) returns error? {
    _ = check dbClient->execute(`UPDATE itn_bo_message SET etat = ${state} WHERE id = ${quotation.id}`);
}
