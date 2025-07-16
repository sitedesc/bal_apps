import ballerina/io;
import ballerina/data.jsondata;
import ballerina/toml;
import ballerina/log;

public function main(string file, string jsonpath) returns error? {
    io:println("Hello, World from schemd_content_connector!");
    map<json> tomlFile = check toml:readFile(file);
    json result = check jsondata:read(tomlFile, `${jsonpath}`);
    log:printDebug(result.toString());
    io:print(result.toString());
}