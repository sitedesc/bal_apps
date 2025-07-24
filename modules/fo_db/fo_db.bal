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
    string query = "SELECT CONCAT('<itn_bo_message><id>',id,'</id><message><![CDATA[', message,']]></message></itn_bo_message>') FROM itn_bo_message WHERE etat = 0 AND created_at >= '2025-07-10' limit 1";
    os:Process process = check os:exec({
                                           value: "exec_sql.sh",
                                           arguments: [credentials.user, credentials.password, credentials.host, 
                                                       credentials.database, query]
                                       });
    _ = check process.waitForExit();
    string stdout = check string:fromBytes(check process.output());
    string xmlDocStr = "<itn_bo_messages>" + stdout + "</itn_bo_messages>";
    string:RegExp r = re `\\\\u`;
    xmlDocStr = r.replaceAll(xmlDocStr,"\\u");
    string:RegExp r1 = re `\\\\"`;
    xmlDocStr = r1.replaceAll(xmlDocStr,"\\\"");
    log:printDebug(xmlDocStr);
    xml quotationMsgs = check xml:fromString(xmlDocStr);
    return quotationMsgs;
}

public isolated function setQuotationMsgState(string quotationMsgId, int state, string response) returns error? {
        string query = string `UPDATE itn_bo_message SET etat = ${state}, response = ${response} WHERE id = ${quotationMsgId}`;
        log:printDebug(query);
        os:Process process = check os:exec({
                                           value: "exec_sql.sh",
                                           arguments: [credentials.user, credentials.password, credentials.host, 
                                                       credentials.database, query]
                                       });
    _ = check process.waitForExit();
}
