import ballerina/task;

public function main() returns error? {
    map<task:JobId> _ = {
        "ZeroKmJob": check createZeroKmJob()
    };
}
