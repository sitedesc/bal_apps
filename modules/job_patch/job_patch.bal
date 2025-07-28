import ballerina/http;

type Conf record {
    int port;
};

configurable Conf conf = ?;
// === WORKAROUND SERVICE (WILL BECOME A JOBS ADMIN SERVICE) ===
service http:Service / on new http:Listener(conf.port) {
    resource function get health() returns string {
        return "this is a workaround to keep the script live sothat the scheduled job can run...";
    }
}

// WORKAROUND SERVICE: calling this function from another package run the service above, otherwise the package cannot run it...
public function runJobPatch() {}