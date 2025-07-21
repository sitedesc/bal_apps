import ballerina/log;
import ballerina/os;

public type DbCredentials record {
    string host;
    int port = 3306;
    string user;
    string password;
    string database;
};

public configurable DbCredentials credentials = ?;

public type Quotation record {
    int id;
    string content;
};

public record {
    0 TODO;
    1 DONE;
    2 ERROR;
} SYNC_STATE = {TODO: 0, DONE: 1, ERROR: 2};

public isolated function getQuotationMsgs() returns xml|error {

    //mysql standard version
    //Quotation[] quotations = [];
    // stream<Quotation, error?> resultStream = (dbClient->query(
    //     `SELECT id, CAST(message AS JSON) as content FROM itn_bo_message WHERE etat=0`
    // ));
    //     _ = check from Quotation quotation in resultStream
    //     do {
    //         quotations.push(quotation);
    //     };
    // _ = check resultStream.close();

    //mysql 5.1 version using fosql mariadb client alias with credentials and 
    //sp_get_quotations stored procedure returning results in json
    os:Process process = check os:exec({
                                           value: "call_procedure.sh",
                                           arguments: [credentials.user, credentials.password, credentials.host, 
                                                       credentials.database, "sp_get_quotations()"]
                                       });
    _ = check process.waitForExit();
    string stdout = check string:fromBytes(check process.output());
    log:printDebug(stdout);
    xml quotationMsgs = check xml:fromString(stdout.trim());
    return quotationMsgs;
}

public isolated function setQuotationMsgState(int quotationMsgId, int state) returns error? {
        string query = string `UPDATE itn_bo_message SET etat = ${state} WHERE id = ${quotationMsgId}`;
        log:printDebug(query);
        os:Process process = check os:exec({
                                           value: "exec_sql.sh",
                                           arguments: [credentials.user, credentials.password, credentials.host, 
                                                       credentials.database, query]
                                       });
    _ = check process.waitForExit();
}
