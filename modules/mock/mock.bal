import ballerina/http;
import ballerina/log;

type MockConf record {
    int port;
};

configurable MockConf mockConf = ?;
service http:Service / on new http:Listener(mockConf.port) {
    resource function post api/v1/devis/notify(map<json> pload) returns string {
        log:printInfo(`mock route /api/v1/devis/notify receives pload:
        ${pload}
        returns mock quotation id: 1234567`);
        return "1234567";
        // to test timeout error case:
//         return string `<html>
// <head><title>504 Gateway Time-out</title></head><body><center><h1>504 Gateway Time-out</h1></center></body></html>`;
    }
}
