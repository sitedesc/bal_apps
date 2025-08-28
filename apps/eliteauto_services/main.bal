import ballerina/task;
import cosmobilis/job_patch;
import cosmobilis/update_customer_dispo as ucd;
// zero km job is not requested in prod yet: uncomment it to test it
//import cosmobilis/zero_km as zk;
import cosmobilis/sync_fo_quotations as sfq;
import cosmobilis/check_disk_space as cds;
import cosmobilis/check_funding_offers as cfo;

type Conf record {
string[] disabledJobs;
};
configurable Conf conf = {disabledJobs: []};

public function main() returns error? {
    job_patch:runJobPatch();
    map<task:JobId|()> _ = {
        // zero km job is not requested in prod yet: uncomment it to test it
        //"ZeroKmJob": conf.disabledJobs.indexOf("ZeroKmJob") is () ? check zk:createZeroKmJob() : (),
        "UpdateCustomerDispoJob": conf.disabledJobs.indexOf("UpdateCustomerDispoJob") is () ? check ucd:createCustomerDispoJob() : (),
        "SyncFoQuotationJob": conf.disabledJobs.indexOf("SyncFoQuotationJob") is () ? check sfq:createSyncFoQuotationJob() : (),
        "CheckDiskSpaceJob": conf.disabledJobs.indexOf("CheckDiskSpaceJob") is () ? check cds:createCheckDiskSpaceJob() : (),
        "CheckFundingOffersJob": conf.disabledJobs.indexOf("CheckFundingOffersJob") is () ? check cfo:createCheckFundingOffersJob() : ()
    };
}
