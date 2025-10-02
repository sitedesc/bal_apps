import ballerina/log;

public function main() returns error? {

    //between time slot test/example
    TimeSlot timeSlot = [11,25,0,11,30,0];  
    if (between(timeSlot))  {
        log:printInfo("now is between time slot: " + timeSlot.toString());
    } else {
        log:printInfo("now is NOT between time slot: " + timeSlot.toString());
    }

}