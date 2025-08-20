import java_bindings.java.time as j_time;

import ballerina/log;
import ballerina/time;

public function main() returns error? {
    //cet exemple calcul et affiche la date civile de la prochaine horaire locale définies
    //par les valeur hours, minutes, seconds
    int hours = 15;
    int minutes = 0;
    int seconds = 0;

    j_time:ZonedDateTime localNow = j_time:ZonedDateTime_now();
    j_time:ZonedDateTime targetSchedule;
    log:printInfo(`ISO local now time:
    ${localNow.toString()}`);

    if (hours < localNow.getHour()) ||
        (hours == localNow.getHour() && minutes < localNow.getMinute()) ||
        (hours == localNow.getHour() && minutes == localNow.getMinute() && seconds < localNow.getSecond()) {

        targetSchedule = localNow.plusDays(1).withHour(hours).withMinute(minutes).withSecond(seconds);

    } else {

        targetSchedule = localNow.withHour(hours).withMinute(minutes).withSecond(seconds);

    }

    log:printInfo(targetSchedule.toString());

    time:Civil civilSchedule =  check time:civilFromString(targetSchedule.toString());
    log:printInfo(`civil time schedule:
    ${civilSchedule.toString()}`);
}
