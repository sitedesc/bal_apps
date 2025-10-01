import ballerina/log;
import ballerina/time;
import cosmobilis/java_bindings.java.time as j_time;

//TimeSlot has six int values: hours start, minutes start, seconds start, hours end, minutes end, seconds end
public type TimeSlot int[6];

// s'il est 16:00:00 au moment de l'exécution de cette fonction et que l'heure passée en paramètre est 15:00:00,
// la fonction retourne la date civile de demain 15:00:00 sinon celle d'aujourd'hui 15:00:00.
// cette date est donnée dans la time zone configurée au niveau de l'OS executant cette fonction.
public function at(int hours, int minutes, int seconds) returns time:Civil|error {
    j_time:ZonedDateTime localNow = j_time:ZonedDateTime_now();
    j_time:ZonedDateTime targetSchedule;
    log:printDebug(`ISO local now time:
    ${localNow.toString()}`);

    if (hours < localNow.getHour()) ||
        (hours == localNow.getHour() && minutes < localNow.getMinute()) ||
        (hours == localNow.getHour() && minutes == localNow.getMinute() && seconds < localNow.getSecond()) {

        targetSchedule = localNow.plusDays(1);

    } else {

        targetSchedule = localNow;

    }
    targetSchedule = targetSchedule.withHour(hours).withMinute(minutes).withSecond(seconds).withNano(0);

    log:printInfo(targetSchedule.toString());

    time:Civil civilSchedule =  check time:civilFromString(targetSchedule.toString());
    log:printDebug(`civil time schedule:
    ${civilSchedule.toString()}`);
    return civilSchedule;
}

public function between(TimeSlot timeSlot, j_time:ZonedDateTime theTime = j_time:ZonedDateTime_now()) returns boolean {
    j_time:ZonedDateTime startTime = theTime.withHour(timeSlot[0]).withMinute(timeSlot[1]).withSecond(timeSlot[2]);
    j_time:ZonedDateTime endTime = theTime.withHour(timeSlot[3]).withMinute(timeSlot[4]).withSecond(timeSlot[5]);

    return (theTime.toEpochSecond() >= startTime.toEpochSecond() && theTime.toEpochSecond() <= endTime.toEpochSecond());
}
