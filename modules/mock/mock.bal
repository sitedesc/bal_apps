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

    // Mock de l'endpoint query Salesforce
    resource function get services/data/v58_0/query(string q) returns json {
        log:printInfo(`Mock GET /query called with q: ${q}`);
        // retourne un format similaire à Salesforce
        json resp = {
            "totalSize": 1,
            "done": true,
            "records": [
                {
                    "attributes": {
                        "type": "Opportunity",
                        "url": "/services/data/v58_0/sobjects/Opportunity/006XYZ"
                    },
                    "Commentaire_evendeur__c": "mock comment"
                }
            ]
        };
        return resp;
    }

    // Mock de l'endpoint PATCH Salesforce
    resource function patch services/data/v58_0/sobjects/Opportunity/[string opportunityId](map<json> payload) returns json {
        log:printInfo(`Mock PATCH /sobjects/Opportunity/${opportunityId} called with payload: ${payload}`);
        // retourne un 204 No Content en réalité, mais Ballerina ne peut pas renvoyer juste 204 facilement avec json
        return payload; 
    }

    // Mock GET sur une Opportunity spécifique
    resource function get services/data/v58_0/sobjects/Opportunity/[string opportunityId]() returns map<json> {
        log:printInfo(`Mock GET /sobjects/Opportunity/${opportunityId} called`);
        return {
                    "Id": opportunityId,
                    "Commentaire_evendeur__c": "mock comment",
                    "URL_Annonce__c" : "URL",
                    "Marque_interesse__c" : "Marque",
                    "Modele_interesse__c" : "Modele",
                    "Nom_Vendeur_Origine__c" : "Nom du qualifieur",
                    "Immatriculation_VEH_reprise__c" : "Immat demande reprise",
                    "Financement__c" : "Financement",
                    "Apport__c" : "Apport",
                    "Duree_du_pret__c" : "Duree",
                    "TAEG_fixe__c" : "TAEG",
                    "Mensualites_avec_assurances__c" : "Mensualites",
                    "Commentaire_Client__c" : "Commentaire client"
        };
    }

    // POST /services/oauth2/token
    resource function post services/oauth2/token(map<string> payload) returns map<string> {
        log:printInfo(`Mock POST /services/oauth2/token called with payload: ${payload}`);
        
        // Retourne toujours le même access_token
        map<string> resp = {
            "access_token": "123456"
        };
        return resp;
    }

}
