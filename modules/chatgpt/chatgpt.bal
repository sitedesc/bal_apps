import ballerina/http;
import ballerina/io;
import ballerina/data.jsondata;

public type Conf record {
    string secretKey;
};

public configurable Conf conf = ?;


public function main(string rulesFile, string cvTextFile) returns error? {

    // read rules
    string rules = check io:fileReadString(rulesFile);

    // read CV text
    string cvText = check io:fileReadString(cvTextFile);

    string prompt = rules + "\n\nCV texte brut :\n" + cvText + "\n\nGénère le CV XML complet maintenant et dans la  déduite des régles ci-avant.";
    string? answer = check processRequest("/chat/completions", prompt);
    io:println(answer);
}

public function processRequest(string route, string prompt) returns string?|error? {


    // Create HTTP client for OpenAI API
    http:Client 'client = check new ("https://api.openai.com/v1", config = {
        auth: {
            token : conf.secretKey
        },
        timeout: 300
    });

     json payload = {
        "model": "gpt-5.1",
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ],
        "temperature": 0,
        "seed": 42,
        "max_completion_tokens": 4000,
        "response_format": { "type": "text" }
    };

    http:Response response = check 'client->post(route, payload);
    json body = check response.getJsonPayload();

    string? answer = <string?> check jsondata:read(body, `$.choices[0].message.content`);

    return answer;
}
