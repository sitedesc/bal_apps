import ballerina/task;
import cosmobilis/job_patch;


public function main() returns error? {
    job_patch:runJobPatch();
    map<task:JobId> _ = {
        "SyncFoQuotationJob": check createSyncFoQuotationJob()
    };
}
