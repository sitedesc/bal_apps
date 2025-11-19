import ballerina/test;
import ballerina/os;

@test:Config {
    after: afterTest
}
function testSendTeamsNotification() returns error? {
    error fixture = error("fixture d'erreur pour test du maodule teams");

    string msg = "❌ scheduledRun() a échoué : " + fixture.message();
    var notif = sendTeamsNotification("Erreur exécution job sync_fo_quotation", msg, [{"Type d'exécution": "Tâche planifiée"}]);
    test:assertFalse(notif is error);

    check os:setEnv("TEAMS_AUTH", os:getEnv("TEST_MS_TEAMS_AUTH"));
    check init();

    string summary = "TEST D'ALERTE DU SERVICE OPPORTUNITY";
    string text = "... encore une simulation d'alerte d'erreur sur opportunité avec le lien vers l'opportunité... c'est pas une vraie erreur of course...";
    TMIncomingWebhookFact[] facts = [
                {name: "", value: ""},
                {"name": "Opportunité Salesforce", "value": "**[006Jv00000ajAMgIAM](https://bymycar.lightning.force.com/lightning/r/Opportunity/006Jv00000ajAMgIAM/view)**"},
                {"name": "HTTP STATUS", "value": "**500**"},
                {"name": "message", "value": "Les données transmises sont incorrectes."},
                {"name": "description", "value": "Ce véhicule ne peut pas être mis en vente."},
                {"name": "ID error openflex", "value": "68f5da9f404134.70959213"}
            ];
    notif = sendTeamsNotification(summary,
            text,
            facts ,
            "TMMessageCard");
    test:assertFalse(notif is error);

    MessageCard messageCard = {
        summary: summary,
        title: summary,
        sections: [
            {
                text: text
            },
                {
                    title: "Détail",
                    facts: facts,
                    markdown: true
                }
        ]
    };
    json|error? response = sendTeamsNotif(messageCard);
    test:assertFalse(response is error);



}

function afterTest() returns error? {
    check os:unsetEnv("TEAMS_AUTH");
}