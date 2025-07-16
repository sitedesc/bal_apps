import ballerina/task;
import cosmobilis/update_customer_dispo as ucd;
import cosmobilis/zero_km as zk;

public function main() returns error? {
    map<task:JobId> _ = {
        "ZeroKmJob": check zk:createZeroKmJob(),
        "CustomerDispoJob": check ucd:createCustomerDispoJob()
    };
}

