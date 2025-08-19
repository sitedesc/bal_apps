import ballerina/io;
import ballerina/log;
import ballerina/os;
import ballerina/task;

import cosmobilis/teams;
import cosmobilis/time as c_time;

public type Conf record {
    string server;
    int hour;
    int minutes;
    int seconds;
};

public configurable Conf conf = ?;

// === SCHEDULER INITIALISATION ===
public function createCheckDiskSpaceJob() returns task:JobId|error {
    CheckDiskSpaceJob myJob = new;
    return task:scheduleJobRecurByFrequency(myJob, 24 * 60 * 60, -1, check c_time:at(conf.hour, conf.minutes, conf.seconds));
}

//TODO: refactor logging and teams notif code in this class: 
// - externalize logging code in a dedicated pkg integrating teams pkg.
class CheckDiskSpaceJob {
    *task:Job;

    // === SCHEDULED EXECUTION FUNCTIONS ===
    public function execute() {
        lock {
            do {
                log:printInfo("⏱️ Job planifié : exécution de scheduledRun()");
                var result = self.scheduledRun();
                if result is error {
                    string msg = "❌ scheduledRun() a échoué : " + result.message();
                    log:printError(msg, result);
                    // Envoi d'une notification Teams en cas d'erreur
                    var notif = teams:sendTeamsNotification("Erreur exécution job check_disk_space", msg, [{"Type d'exécution": "Tâche planifiée"}]);
                    if notif is error {
                        log:printError("Échec d'envoi Teams", notif);
                    }
                }
            } on fail var failure {
                log:printError("Unmanaged error", failure);
            }
        }
    }

    function scheduledRun() returns error? {
        os:Process process = check os:exec({
                                               value: "df",
                                               arguments: ["-h"]
                                           });
        _ = check process.waitForExit();

        string stdout = check string:fromBytes(check process.output());
        string stderr = check string:fromBytes(check process.output(io:stderr));
        log:printInfo(`${conf.server} server DISK SPACE
                    ----stdout----
                    ${stdout}
                    ----stderr----
                    ${stderr}`);
        _ = check teams:sendTeamsNotification(
                                                    string `${conf.server} server DISK SPACE`,
                string `returns standard out followed by standard error, of df -h command on ${conf.server} server`,
                string `${stdout}
                        ${stderr}`
             );

    }

}
