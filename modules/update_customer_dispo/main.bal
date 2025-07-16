import ballerina/task;

public function main() returns error? {
    map<task:JobId> _ = {
        "CustomerDispoJob": check createCustomerDispoJob()
    };
}
