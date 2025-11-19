import ballerina/data.jsondata as jsondata;
import ballerina/http;
import ballerina/log;
import ballerina/os;
import ballerina/regex;

public type Conf record {
    string webhookUrl;
    string channelId;
    string apiKey;
};

public configurable Conf conf = ?;
public Conf config = conf;

map<string> headersTeams = {
    "x-api-key": config.apiKey
};

function init() returns error? {
    string envConfJson = os:getEnv("TEAMS_AUTH");
    log:printInfo("***********", envVal = envConfJson);
    Conf|error envConf = jsondata:parseString(envConfJson);
    log:printInfo("***********", channel = conf.channelId);
    if !(envConf is error) {
        log:printInfo("***********", channelenv = envConf.channelId);
        config = envConf;
    } else {
        log:printInfo("Teams env conf error:", envConf);
        log:printInfo("falling back to Config.toml conf");
    }
    log:printInfo("***********", hook = config.webhookUrl);
}

public function sendTeamsNotification(string title, string description, string|map<string>[]|TMIncomingWebhookFact[] list, string 'type = "AWMessageCard") returns error? {
    MessageCard messageCard = ('type == "AWMessageCard") ? {
            title: title,
            description: description,
            channel_id: config.channelId,
            list: <map<string>[]> normalizeListParam(list)
        } : {
            summary: title,
            title: title,
            sections: [
                {
                    text: description
                },
                {
                    title: "Détail",
                    facts: buildFacts(normalizeListParam(list)),
                    markdown: true
                }
            ]
        };
    _ = check sendTeamsNotif(messageCard);
}

public function buildFacts(map<string>[]|TMIncomingWebhookFact[] list) returns TMIncomingWebhookFact[] {
    if list is TMIncomingWebhookFact[] {
        return list;
    }

    TMIncomingWebhookFact[] facts = [];
    foreach map<string> item in <map<string>[]>list {
        foreach var [key, value] in item.entries() {
            facts.push({
                name: key,
                value: value
            });
        }
    }

    return facts;
}

public function sendTeamsNotif(MessageCard messageCard) returns json|error? {
    http:Client teamsClient = check new (config.webhookUrl,{timeout: 180, httpVersion: "1.1"});

    // Envoi réel de la notification via POST
    http:Response response = check teamsClient->post("", messageCard, headersTeams);
    int statusCode = response.statusCode;
    if (statusCode != 200) {
        string content = check response.getTextPayload();
        log:printError("Échec de notification Teams. Code: " + statusCode.toString() + ", Message: " + content);
    } else {
        log:printInfo("Notification Teams envoyée avec succès.");
    }
 
    return {"httpStatusCode": response.statusCode, "message": "teams error notif", "descr": check response.getTextPayload()};
}

function normalizeListParam(string|map<string>[]|TMIncomingWebhookFact[] listParam) returns map<string>[]|TMIncomingWebhookFact[] {
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
            i = i + 1;
        }
    }
    return lines;
}
