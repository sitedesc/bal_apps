import ballerina/http;
import ballerina/io;
import thisarug/prettify;

public function errorSearch(string index, string requestId, int statusCode, string startDay, string endDay) returns error? {
    // URL du endpoint Kibana
    string url = "http://10.1.2.200:5601";

    // Corps JSON (identique à la version bash, mais avec les variables injectées)
    json body =   {
    batch: [
      {
        options: {
          strategy: "ese"
        },
        request: {
          params: {
            body: {
              _source: true,
              fields: [
                {
                  'field: "*",
                  include_unmapped: "true"
                },
                {
                  'field: "timestamp",
                  format: "date_time"
                }
              ],
              query: {
                bool: {
                  filter: [
                    {
                      range: {
                        timestamp: {
                          format: "strict_date_optional_time",
                          gte: startDay,
                          lte: endDay
                        }
                      }
                    },
                    {
                      match_phrase: {
                        request_id: requestId
                      }
                    },
                    {
                      match_phrase: {
                        status_code: statusCode
                      }
                    }
                  ],
                  must: [],
                  must_not: [],
                  should: []
                }
              },
              runtime_mappings: {},
              stored_fields: [
                "*"
              ],
              version: true
            },
            index: index
          }
        }
      }
    ]
  }
;




    io:println("----------- Création du Client HTTP : \n", "----------");
    http:Client kibanaClient = check new (url);

    map<string> headers ={
            "Host": "10.1.2.200:5601",
            "User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:144.0) Gecko/20100101 Firefox/144.0",
            "Accept": "*/*",
            "Accept-Language": "fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3",
            "Accept-Encoding": "deflate",
            "Referer": "http://10.1.2.200:5601/app/discover",
            "Content-Type": "application/json",
            "kbn-version": "7.16.2",
            "Origin": "http://10.1.2.200:5601",
            "Connection": "keep-alive",
            "Pragma": "no-cache",
            "Cache-Control": "no-cache"
        };

    io:println("----------- Envoi de la requête POST : \n", prettify:prettify(body), "----------");
    http:Response response = check kibanaClient->post("/internal/bsearch", body, headers);

    // Lecture de la réponse JSON
    json|error payload = response.getJsonPayload();

    if payload is json {
        io:println("----------- Réponse : \n", prettify:prettify(payload), "----------");
    } else {
        io:println("Erreur de décodage JSON : ", payload.toString());
        io:println("Réponse brute : ", check response.getTextPayload());
    }
}
