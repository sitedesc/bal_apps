import ballerina/log;
import ballerina/http;
import ballerina/regex;

public type Conf record {
string webhookUrl;
string channelId;
string apiKey;
};

public configurable Conf conf = ?;

map<string> headersTeams = {
            "x-api-key": conf.apiKey
        };

public function sendTeamsNotification(string title, string description, string|map<string>[] list) returns error? {
    http:Client teamsClient = check new (conf.webhookUrl);
    json payload = {
        title: title,
        description: description,
        channel_id: conf.channelId,
        list: normalizeListParam(list)
    };

    // Envoi réel de la notification via POST
    http:Response response = check teamsClient->post("", payload, headersTeams);
    int statusCode = response.statusCode;
    if (statusCode != 200) {
        string content = check response.getTextPayload();
        log:printError("Échec de notification Teams. Code: " + statusCode.toString() + ", Message: " + content);
    } else {
        log:printInfo("Notification Teams envoyée avec succès.");
    }
}

function normalizeListParam(string|map<string>[] listParam) returns map<string>[] {
    if listParam is string {
        return getStringLines(listParam);
    }
    return listParam;
}
function getStringLines(string theString) returns map<string>[] {
        string[] splited = regex:split(theString, "\n");
        map<string>[] lines = [];
        int i = 1;
        foreach string line in splited {
            if line.trim().length() > 0 {
                string lineNumber = string `line ${i.toString()}`;
                lines.push({[lineNumber]: line});
                i = i+1;
            }
        }
        return lines;
}
