import java_bindings.java.lang as javalang;
import java_bindings.java.time.chrono as javatimechrono;
import java_bindings.java.time.format as javatimeformat;
import java_bindings.java.time.temporal as javatimetemporal;

import ballerina/jballerina.java;

# Ballerina class mapping for the Java `java.time.LocalDateTime` class.
@java:Binding {'class: "java.time.LocalDateTime"}
public distinct class LocalDateTime {

    *java:JObject;
    *javalang:Object;

    # The `handle` field that stores the reference to the `java.time.LocalDateTime` object.
    public handle jObj;

    # The init function of the Ballerina class mapping the `java.time.LocalDateTime` Java class.
    #
    # + obj - The `handle` value containing the Java reference of the object.
    public function init(handle obj) {
        self.jObj = obj;
    }

    # The function to retrieve the string representation of the Ballerina class mapping the `java.time.LocalDateTime` Java class.
    #
    # + return - The `string` form of the Java object instance.
    public function toString() returns string {
        return java:toString(self.jObj) ?: "";
    }

    # The function that maps to the `adjustInto` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimetemporal:Temporal` value required to map with the Java method parameter.
    # + return - The `javatimetemporal:Temporal` value returning from the Java mapping.
    public function adjustInto(javatimetemporal:Temporal arg0) returns javatimetemporal:Temporal {
        handle externalObj = java_time_LocalDateTime_adjustInto(self.jObj, arg0.jObj);
        javatimetemporal:Temporal newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `atOffset` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `ZoneOffset` value required to map with the Java method parameter.
    # + return - The `OffsetDateTime` value returning from the Java mapping.
    public function atOffset(ZoneOffset arg0) returns OffsetDateTime {
        handle externalObj = java_time_LocalDateTime_atOffset(self.jObj, arg0.jObj);
        OffsetDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `atZone` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `ZoneId` value required to map with the Java method parameter.
    # + return - The `ZonedDateTime` value returning from the Java mapping.
    public function atZone(ZoneId arg0) returns ZonedDateTime {
        handle externalObj = java_time_LocalDateTime_atZone(self.jObj, arg0.jObj);
        ZonedDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `compareTo` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimechrono:ChronoLocalDateTime` value required to map with the Java method parameter.
    # + return - The `int` value returning from the Java mapping.
    public function compareTo(javatimechrono:ChronoLocalDateTime arg0) returns int {
        return java_time_LocalDateTime_compareTo(self.jObj, arg0.jObj);
    }

    # The function that maps to the `equals` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javalang:Object` value required to map with the Java method parameter.
    # + return - The `boolean` value returning from the Java mapping.
    public function 'equals(javalang:Object arg0) returns boolean {
        return java_time_LocalDateTime_equals(self.jObj, arg0.jObj);
    }

    # The function that maps to the `format` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimeformat:DateTimeFormatter` value required to map with the Java method parameter.
    # + return - The `string` value returning from the Java mapping.
    public function format(javatimeformat:DateTimeFormatter arg0) returns string {
        return java:toString(java_time_LocalDateTime_format(self.jObj, arg0.jObj)) ?: "";
    }

    # The function that maps to the `get` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimetemporal:TemporalField` value required to map with the Java method parameter.
    # + return - The `int` value returning from the Java mapping.
    public function get(javatimetemporal:TemporalField arg0) returns int {
        return java_time_LocalDateTime_get(self.jObj, arg0.jObj);
    }

    # The function that maps to the `getChronology` method of `java.time.LocalDateTime`.
    #
    # + return - The `javatimechrono:Chronology` value returning from the Java mapping.
    public function getChronology() returns javatimechrono:Chronology {
        handle externalObj = java_time_LocalDateTime_getChronology(self.jObj);
        javatimechrono:Chronology newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `getClass` method of `java.time.LocalDateTime`.
    #
    # + return - The `javalang:Class` value returning from the Java mapping.
    public function getClass() returns javalang:Class {
        handle externalObj = java_time_LocalDateTime_getClass(self.jObj);
        javalang:Class newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `getDayOfMonth` method of `java.time.LocalDateTime`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function getDayOfMonth() returns int {
        return java_time_LocalDateTime_getDayOfMonth(self.jObj);
    }

    # The function that maps to the `getDayOfWeek` method of `java.time.LocalDateTime`.
    #
    # + return - The `DayOfWeek` value returning from the Java mapping.
    public function getDayOfWeek() returns DayOfWeek {
        handle externalObj = java_time_LocalDateTime_getDayOfWeek(self.jObj);
        DayOfWeek newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `getDayOfYear` method of `java.time.LocalDateTime`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function getDayOfYear() returns int {
        return java_time_LocalDateTime_getDayOfYear(self.jObj);
    }

    # The function that maps to the `getHour` method of `java.time.LocalDateTime`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function getHour() returns int {
        return java_time_LocalDateTime_getHour(self.jObj);
    }

    # The function that maps to the `getLong` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimetemporal:TemporalField` value required to map with the Java method parameter.
    # + return - The `int` value returning from the Java mapping.
    public function getLong(javatimetemporal:TemporalField arg0) returns int {
        return java_time_LocalDateTime_getLong(self.jObj, arg0.jObj);
    }

    # The function that maps to the `getMinute` method of `java.time.LocalDateTime`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function getMinute() returns int {
        return java_time_LocalDateTime_getMinute(self.jObj);
    }

    # The function that maps to the `getMonth` method of `java.time.LocalDateTime`.
    #
    # + return - The `Month` value returning from the Java mapping.
    public function getMonth() returns Month {
        handle externalObj = java_time_LocalDateTime_getMonth(self.jObj);
        Month newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `getMonthValue` method of `java.time.LocalDateTime`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function getMonthValue() returns int {
        return java_time_LocalDateTime_getMonthValue(self.jObj);
    }

    # The function that maps to the `getNano` method of `java.time.LocalDateTime`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function getNano() returns int {
        return java_time_LocalDateTime_getNano(self.jObj);
    }

    # The function that maps to the `getSecond` method of `java.time.LocalDateTime`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function getSecond() returns int {
        return java_time_LocalDateTime_getSecond(self.jObj);
    }

    # The function that maps to the `getYear` method of `java.time.LocalDateTime`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function getYear() returns int {
        return java_time_LocalDateTime_getYear(self.jObj);
    }

    # The function that maps to the `hashCode` method of `java.time.LocalDateTime`.
    #
    # + return - The `int` value returning from the Java mapping.
    public function hashCode() returns int {
        return java_time_LocalDateTime_hashCode(self.jObj);
    }

    # The function that maps to the `isAfter` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimechrono:ChronoLocalDateTime` value required to map with the Java method parameter.
    # + return - The `boolean` value returning from the Java mapping.
    public function isAfter(javatimechrono:ChronoLocalDateTime arg0) returns boolean {
        return java_time_LocalDateTime_isAfter(self.jObj, arg0.jObj);
    }

    # The function that maps to the `isBefore` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimechrono:ChronoLocalDateTime` value required to map with the Java method parameter.
    # + return - The `boolean` value returning from the Java mapping.
    public function isBefore(javatimechrono:ChronoLocalDateTime arg0) returns boolean {
        return java_time_LocalDateTime_isBefore(self.jObj, arg0.jObj);
    }

    # The function that maps to the `isEqual` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimechrono:ChronoLocalDateTime` value required to map with the Java method parameter.
    # + return - The `boolean` value returning from the Java mapping.
    public function isEqual(javatimechrono:ChronoLocalDateTime arg0) returns boolean {
        return java_time_LocalDateTime_isEqual(self.jObj, arg0.jObj);
    }

    # The function that maps to the `isSupported` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimetemporal:TemporalField` value required to map with the Java method parameter.
    # + return - The `boolean` value returning from the Java mapping.
    public function isSupported(javatimetemporal:TemporalField arg0) returns boolean {
        return java_time_LocalDateTime_isSupported(self.jObj, arg0.jObj);
    }

    # The function that maps to the `isSupported` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimetemporal:TemporalUnit` value required to map with the Java method parameter.
    # + return - The `boolean` value returning from the Java mapping.
    public function isSupported2(javatimetemporal:TemporalUnit arg0) returns boolean {
        return java_time_LocalDateTime_isSupported2(self.jObj, arg0.jObj);
    }

    # The function that maps to the `minus` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + arg1 - The `javatimetemporal:TemporalUnit` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function minus(int arg0, javatimetemporal:TemporalUnit arg1) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_minus(self.jObj, arg0, arg1.jObj);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `minus` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimetemporal:TemporalAmount` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function minus2(javatimetemporal:TemporalAmount arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_minus2(self.jObj, arg0.jObj);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `minusDays` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function minusDays(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_minusDays(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `minusHours` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function minusHours(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_minusHours(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `minusMinutes` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function minusMinutes(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_minusMinutes(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `minusMonths` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function minusMonths(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_minusMonths(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `minusNanos` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function minusNanos(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_minusNanos(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `minusSeconds` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function minusSeconds(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_minusSeconds(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `minusWeeks` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function minusWeeks(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_minusWeeks(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `minusYears` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function minusYears(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_minusYears(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `notify` method of `java.time.LocalDateTime`.
    public function notify() {
        java_time_LocalDateTime_notify(self.jObj);
    }

    # The function that maps to the `notifyAll` method of `java.time.LocalDateTime`.
    public function notifyAll() {
        java_time_LocalDateTime_notifyAll(self.jObj);
    }

    # The function that maps to the `plus` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + arg1 - The `javatimetemporal:TemporalUnit` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function plus(int arg0, javatimetemporal:TemporalUnit arg1) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_plus(self.jObj, arg0, arg1.jObj);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `plus` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimetemporal:TemporalAmount` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function plus2(javatimetemporal:TemporalAmount arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_plus2(self.jObj, arg0.jObj);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `plusDays` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function plusDays(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_plusDays(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `plusHours` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function plusHours(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_plusHours(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `plusMinutes` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function plusMinutes(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_plusMinutes(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `plusMonths` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function plusMonths(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_plusMonths(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `plusNanos` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function plusNanos(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_plusNanos(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `plusSeconds` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function plusSeconds(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_plusSeconds(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `plusWeeks` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function plusWeeks(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_plusWeeks(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `plusYears` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function plusYears(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_plusYears(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `query` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimetemporal:TemporalQuery` value required to map with the Java method parameter.
    # + return - The `javalang:Object` value returning from the Java mapping.
    public function query(javatimetemporal:TemporalQuery arg0) returns javalang:Object {
        handle externalObj = java_time_LocalDateTime_query(self.jObj, arg0.jObj);
        javalang:Object newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `range` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimetemporal:TemporalField` value required to map with the Java method parameter.
    # + return - The `javatimetemporal:ValueRange` value returning from the Java mapping.
    public function range(javatimetemporal:TemporalField arg0) returns javatimetemporal:ValueRange {
        handle externalObj = java_time_LocalDateTime_range(self.jObj, arg0.jObj);
        javatimetemporal:ValueRange newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `toEpochSecond` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `ZoneOffset` value required to map with the Java method parameter.
    # + return - The `int` value returning from the Java mapping.
    public function toEpochSecond(ZoneOffset arg0) returns int {
        return java_time_LocalDateTime_toEpochSecond(self.jObj, arg0.jObj);
    }

    # The function that maps to the `toInstant` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `ZoneOffset` value required to map with the Java method parameter.
    # + return - The `Instant` value returning from the Java mapping.
    public function toInstant(ZoneOffset arg0) returns Instant {
        handle externalObj = java_time_LocalDateTime_toInstant(self.jObj, arg0.jObj);
        Instant newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `toLocalDate` method of `java.time.LocalDateTime`.
    #
    # + return - The `LocalDate` value returning from the Java mapping.
    public function toLocalDate() returns LocalDate {
        handle externalObj = java_time_LocalDateTime_toLocalDate(self.jObj);
        LocalDate newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `toLocalTime` method of `java.time.LocalDateTime`.
    #
    # + return - The `LocalTime` value returning from the Java mapping.
    public function toLocalTime() returns LocalTime {
        handle externalObj = java_time_LocalDateTime_toLocalTime(self.jObj);
        LocalTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `truncatedTo` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimetemporal:TemporalUnit` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function truncatedTo(javatimetemporal:TemporalUnit arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_truncatedTo(self.jObj, arg0.jObj);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `until` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimetemporal:Temporal` value required to map with the Java method parameter.
    # + arg1 - The `javatimetemporal:TemporalUnit` value required to map with the Java method parameter.
    # + return - The `int` value returning from the Java mapping.
    public function until(javatimetemporal:Temporal arg0, javatimetemporal:TemporalUnit arg1) returns int {
        return java_time_LocalDateTime_until(self.jObj, arg0.jObj, arg1.jObj);
    }

    # The function that maps to the `wait` method of `java.time.LocalDateTime`.
    #
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function 'wait() returns javalang:InterruptedException? {
        error|() externalObj = java_time_LocalDateTime_wait(self.jObj);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `wait` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function wait2(int arg0) returns javalang:InterruptedException? {
        error|() externalObj = java_time_LocalDateTime_wait2(self.jObj, arg0);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `wait` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + arg1 - The `int` value required to map with the Java method parameter.
    # + return - The `javalang:InterruptedException` value returning from the Java mapping.
    public function wait3(int arg0, int arg1) returns javalang:InterruptedException? {
        error|() externalObj = java_time_LocalDateTime_wait3(self.jObj, arg0, arg1);
        if (externalObj is error) {
            javalang:InterruptedException e = error javalang:InterruptedException(javalang:INTERRUPTEDEXCEPTION, externalObj, message = externalObj.message());
            return e;
        }
    }

    # The function that maps to the `with` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimetemporal:TemporalAdjuster` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function 'with(javatimetemporal:TemporalAdjuster arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_with(self.jObj, arg0.jObj);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `with` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `javatimetemporal:TemporalField` value required to map with the Java method parameter.
    # + arg1 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function with2(javatimetemporal:TemporalField arg0, int arg1) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_with2(self.jObj, arg0.jObj, arg1);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `withDayOfMonth` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function withDayOfMonth(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_withDayOfMonth(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `withDayOfYear` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function withDayOfYear(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_withDayOfYear(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `withHour` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function withHour(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_withHour(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `withMinute` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function withMinute(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_withMinute(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `withMonth` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function withMonth(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_withMonth(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `withNano` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function withNano(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_withNano(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `withSecond` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function withSecond(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_withSecond(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

    # The function that maps to the `withYear` method of `java.time.LocalDateTime`.
    #
    # + arg0 - The `int` value required to map with the Java method parameter.
    # + return - The `LocalDateTime` value returning from the Java mapping.
    public function withYear(int arg0) returns LocalDateTime {
        handle externalObj = java_time_LocalDateTime_withYear(self.jObj, arg0);
        LocalDateTime newObj = new (externalObj);
        return newObj;
    }

}

# The function that maps to the `from` method of `java.time.LocalDateTime`.
#
# + arg0 - The `javatimetemporal:TemporalAccessor` value required to map with the Java method parameter.
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_from(javatimetemporal:TemporalAccessor arg0) returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_from(arg0.jObj);
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `now` method of `java.time.LocalDateTime`.
#
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_now() returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_now();
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `now` method of `java.time.LocalDateTime`.
#
# + arg0 - The `Clock` value required to map with the Java method parameter.
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_now2(Clock arg0) returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_now2(arg0.jObj);
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `now` method of `java.time.LocalDateTime`.
#
# + arg0 - The `ZoneId` value required to map with the Java method parameter.
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_now3(ZoneId arg0) returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_now3(arg0.jObj);
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `of` method of `java.time.LocalDateTime`.
#
# + arg0 - The `int` value required to map with the Java method parameter.
# + arg1 - The `int` value required to map with the Java method parameter.
# + arg2 - The `int` value required to map with the Java method parameter.
# + arg3 - The `int` value required to map with the Java method parameter.
# + arg4 - The `int` value required to map with the Java method parameter.
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_of(int arg0, int arg1, int arg2, int arg3, int arg4) returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_of(arg0, arg1, arg2, arg3, arg4);
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `of` method of `java.time.LocalDateTime`.
#
# + arg0 - The `int` value required to map with the Java method parameter.
# + arg1 - The `int` value required to map with the Java method parameter.
# + arg2 - The `int` value required to map with the Java method parameter.
# + arg3 - The `int` value required to map with the Java method parameter.
# + arg4 - The `int` value required to map with the Java method parameter.
# + arg5 - The `int` value required to map with the Java method parameter.
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_of2(int arg0, int arg1, int arg2, int arg3, int arg4, int arg5) returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_of2(arg0, arg1, arg2, arg3, arg4, arg5);
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `of` method of `java.time.LocalDateTime`.
#
# + arg0 - The `int` value required to map with the Java method parameter.
# + arg1 - The `int` value required to map with the Java method parameter.
# + arg2 - The `int` value required to map with the Java method parameter.
# + arg3 - The `int` value required to map with the Java method parameter.
# + arg4 - The `int` value required to map with the Java method parameter.
# + arg5 - The `int` value required to map with the Java method parameter.
# + arg6 - The `int` value required to map with the Java method parameter.
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_of3(int arg0, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6) returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_of3(arg0, arg1, arg2, arg3, arg4, arg5, arg6);
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `of` method of `java.time.LocalDateTime`.
#
# + arg0 - The `int` value required to map with the Java method parameter.
# + arg1 - The `Month` value required to map with the Java method parameter.
# + arg2 - The `int` value required to map with the Java method parameter.
# + arg3 - The `int` value required to map with the Java method parameter.
# + arg4 - The `int` value required to map with the Java method parameter.
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_of4(int arg0, Month arg1, int arg2, int arg3, int arg4) returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_of4(arg0, arg1.jObj, arg2, arg3, arg4);
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `of` method of `java.time.LocalDateTime`.
#
# + arg0 - The `int` value required to map with the Java method parameter.
# + arg1 - The `Month` value required to map with the Java method parameter.
# + arg2 - The `int` value required to map with the Java method parameter.
# + arg3 - The `int` value required to map with the Java method parameter.
# + arg4 - The `int` value required to map with the Java method parameter.
# + arg5 - The `int` value required to map with the Java method parameter.
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_of5(int arg0, Month arg1, int arg2, int arg3, int arg4, int arg5) returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_of5(arg0, arg1.jObj, arg2, arg3, arg4, arg5);
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `of` method of `java.time.LocalDateTime`.
#
# + arg0 - The `int` value required to map with the Java method parameter.
# + arg1 - The `Month` value required to map with the Java method parameter.
# + arg2 - The `int` value required to map with the Java method parameter.
# + arg3 - The `int` value required to map with the Java method parameter.
# + arg4 - The `int` value required to map with the Java method parameter.
# + arg5 - The `int` value required to map with the Java method parameter.
# + arg6 - The `int` value required to map with the Java method parameter.
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_of6(int arg0, Month arg1, int arg2, int arg3, int arg4, int arg5, int arg6) returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_of6(arg0, arg1.jObj, arg2, arg3, arg4, arg5, arg6);
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `of` method of `java.time.LocalDateTime`.
#
# + arg0 - The `LocalDate` value required to map with the Java method parameter.
# + arg1 - The `LocalTime` value required to map with the Java method parameter.
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_of7(LocalDate arg0, LocalTime arg1) returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_of7(arg0.jObj, arg1.jObj);
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `ofEpochSecond` method of `java.time.LocalDateTime`.
#
# + arg0 - The `int` value required to map with the Java method parameter.
# + arg1 - The `int` value required to map with the Java method parameter.
# + arg2 - The `ZoneOffset` value required to map with the Java method parameter.
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_ofEpochSecond(int arg0, int arg1, ZoneOffset arg2) returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_ofEpochSecond(arg0, arg1, arg2.jObj);
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `ofInstant` method of `java.time.LocalDateTime`.
#
# + arg0 - The `Instant` value required to map with the Java method parameter.
# + arg1 - The `ZoneId` value required to map with the Java method parameter.
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_ofInstant(Instant arg0, ZoneId arg1) returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_ofInstant(arg0.jObj, arg1.jObj);
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `parse` method of `java.time.LocalDateTime`.
#
# + arg0 - The `javalang:CharSequence` value required to map with the Java method parameter.
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_parse(javalang:CharSequence arg0) returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_parse(arg0.jObj);
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that maps to the `parse` method of `java.time.LocalDateTime`.
#
# + arg0 - The `javalang:CharSequence` value required to map with the Java method parameter.
# + arg1 - The `javatimeformat:DateTimeFormatter` value required to map with the Java method parameter.
# + return - The `LocalDateTime` value returning from the Java mapping.
public function LocalDateTime_parse2(javalang:CharSequence arg0, javatimeformat:DateTimeFormatter arg1) returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_parse2(arg0.jObj, arg1.jObj);
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that retrieves the value of the public field `MIN`.
#
# + return - The `LocalDateTime` value of the field.
public function LocalDateTime_getMIN() returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_getMIN();
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

# The function that retrieves the value of the public field `MAX`.
#
# + return - The `LocalDateTime` value of the field.
public function LocalDateTime_getMAX() returns LocalDateTime {
    handle externalObj = java_time_LocalDateTime_getMAX();
    LocalDateTime newObj = new (externalObj);
    return newObj;
}

function java_time_LocalDateTime_adjustInto(handle receiver, handle arg0) returns handle = @java:Method {
    name: "adjustInto",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.temporal.Temporal"]
} external;

function java_time_LocalDateTime_atOffset(handle receiver, handle arg0) returns handle = @java:Method {
    name: "atOffset",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.ZoneOffset"]
} external;

function java_time_LocalDateTime_atZone(handle receiver, handle arg0) returns handle = @java:Method {
    name: "atZone",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.ZoneId"]
} external;

function java_time_LocalDateTime_compareTo(handle receiver, handle arg0) returns int = @java:Method {
    name: "compareTo",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.chrono.ChronoLocalDateTime"]
} external;

function java_time_LocalDateTime_equals(handle receiver, handle arg0) returns boolean = @java:Method {
    name: "equals",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.lang.Object"]
} external;

function java_time_LocalDateTime_format(handle receiver, handle arg0) returns handle = @java:Method {
    name: "format",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.format.DateTimeFormatter"]
} external;

function java_time_LocalDateTime_from(handle arg0) returns handle = @java:Method {
    name: "from",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.temporal.TemporalAccessor"]
} external;

function java_time_LocalDateTime_get(handle receiver, handle arg0) returns int = @java:Method {
    name: "get",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.temporal.TemporalField"]
} external;

function java_time_LocalDateTime_getChronology(handle receiver) returns handle = @java:Method {
    name: "getChronology",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_getClass(handle receiver) returns handle = @java:Method {
    name: "getClass",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_getDayOfMonth(handle receiver) returns int = @java:Method {
    name: "getDayOfMonth",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_getDayOfWeek(handle receiver) returns handle = @java:Method {
    name: "getDayOfWeek",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_getDayOfYear(handle receiver) returns int = @java:Method {
    name: "getDayOfYear",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_getHour(handle receiver) returns int = @java:Method {
    name: "getHour",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_getLong(handle receiver, handle arg0) returns int = @java:Method {
    name: "getLong",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.temporal.TemporalField"]
} external;

function java_time_LocalDateTime_getMinute(handle receiver) returns int = @java:Method {
    name: "getMinute",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_getMonth(handle receiver) returns handle = @java:Method {
    name: "getMonth",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_getMonthValue(handle receiver) returns int = @java:Method {
    name: "getMonthValue",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_getNano(handle receiver) returns int = @java:Method {
    name: "getNano",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_getSecond(handle receiver) returns int = @java:Method {
    name: "getSecond",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_getYear(handle receiver) returns int = @java:Method {
    name: "getYear",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_hashCode(handle receiver) returns int = @java:Method {
    name: "hashCode",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_isAfter(handle receiver, handle arg0) returns boolean = @java:Method {
    name: "isAfter",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.chrono.ChronoLocalDateTime"]
} external;

function java_time_LocalDateTime_isBefore(handle receiver, handle arg0) returns boolean = @java:Method {
    name: "isBefore",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.chrono.ChronoLocalDateTime"]
} external;

function java_time_LocalDateTime_isEqual(handle receiver, handle arg0) returns boolean = @java:Method {
    name: "isEqual",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.chrono.ChronoLocalDateTime"]
} external;

function java_time_LocalDateTime_isSupported(handle receiver, handle arg0) returns boolean = @java:Method {
    name: "isSupported",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.temporal.TemporalField"]
} external;

function java_time_LocalDateTime_isSupported2(handle receiver, handle arg0) returns boolean = @java:Method {
    name: "isSupported",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.temporal.TemporalUnit"]
} external;

function java_time_LocalDateTime_minus(handle receiver, int arg0, handle arg1) returns handle = @java:Method {
    name: "minus",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long", "java.time.temporal.TemporalUnit"]
} external;

function java_time_LocalDateTime_minus2(handle receiver, handle arg0) returns handle = @java:Method {
    name: "minus",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.temporal.TemporalAmount"]
} external;

function java_time_LocalDateTime_minusDays(handle receiver, int arg0) returns handle = @java:Method {
    name: "minusDays",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_minusHours(handle receiver, int arg0) returns handle = @java:Method {
    name: "minusHours",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_minusMinutes(handle receiver, int arg0) returns handle = @java:Method {
    name: "minusMinutes",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_minusMonths(handle receiver, int arg0) returns handle = @java:Method {
    name: "minusMonths",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_minusNanos(handle receiver, int arg0) returns handle = @java:Method {
    name: "minusNanos",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_minusSeconds(handle receiver, int arg0) returns handle = @java:Method {
    name: "minusSeconds",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_minusWeeks(handle receiver, int arg0) returns handle = @java:Method {
    name: "minusWeeks",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_minusYears(handle receiver, int arg0) returns handle = @java:Method {
    name: "minusYears",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_notify(handle receiver) = @java:Method {
    name: "notify",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_notifyAll(handle receiver) = @java:Method {
    name: "notifyAll",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_now() returns handle = @java:Method {
    name: "now",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_now2(handle arg0) returns handle = @java:Method {
    name: "now",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.Clock"]
} external;

function java_time_LocalDateTime_now3(handle arg0) returns handle = @java:Method {
    name: "now",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.ZoneId"]
} external;

function java_time_LocalDateTime_of(int arg0, int arg1, int arg2, int arg3, int arg4) returns handle = @java:Method {
    name: "of",
    'class: "java.time.LocalDateTime",
    paramTypes: ["int", "int", "int", "int", "int"]
} external;

function java_time_LocalDateTime_of2(int arg0, int arg1, int arg2, int arg3, int arg4, int arg5) returns handle = @java:Method {
    name: "of",
    'class: "java.time.LocalDateTime",
    paramTypes: ["int", "int", "int", "int", "int", "int"]
} external;

function java_time_LocalDateTime_of3(int arg0, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6) returns handle = @java:Method {
    name: "of",
    'class: "java.time.LocalDateTime",
    paramTypes: ["int", "int", "int", "int", "int", "int", "int"]
} external;

function java_time_LocalDateTime_of4(int arg0, handle arg1, int arg2, int arg3, int arg4) returns handle = @java:Method {
    name: "of",
    'class: "java.time.LocalDateTime",
    paramTypes: ["int", "java.time.Month", "int", "int", "int"]
} external;

function java_time_LocalDateTime_of5(int arg0, handle arg1, int arg2, int arg3, int arg4, int arg5) returns handle = @java:Method {
    name: "of",
    'class: "java.time.LocalDateTime",
    paramTypes: ["int", "java.time.Month", "int", "int", "int", "int"]
} external;

function java_time_LocalDateTime_of6(int arg0, handle arg1, int arg2, int arg3, int arg4, int arg5, int arg6) returns handle = @java:Method {
    name: "of",
    'class: "java.time.LocalDateTime",
    paramTypes: ["int", "java.time.Month", "int", "int", "int", "int", "int"]
} external;

function java_time_LocalDateTime_of7(handle arg0, handle arg1) returns handle = @java:Method {
    name: "of",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.LocalDate", "java.time.LocalTime"]
} external;

function java_time_LocalDateTime_ofEpochSecond(int arg0, int arg1, handle arg2) returns handle = @java:Method {
    name: "ofEpochSecond",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long", "int", "java.time.ZoneOffset"]
} external;

function java_time_LocalDateTime_ofInstant(handle arg0, handle arg1) returns handle = @java:Method {
    name: "ofInstant",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.Instant", "java.time.ZoneId"]
} external;

function java_time_LocalDateTime_parse(handle arg0) returns handle = @java:Method {
    name: "parse",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.lang.CharSequence"]
} external;

function java_time_LocalDateTime_parse2(handle arg0, handle arg1) returns handle = @java:Method {
    name: "parse",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.lang.CharSequence", "java.time.format.DateTimeFormatter"]
} external;

function java_time_LocalDateTime_plus(handle receiver, int arg0, handle arg1) returns handle = @java:Method {
    name: "plus",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long", "java.time.temporal.TemporalUnit"]
} external;

function java_time_LocalDateTime_plus2(handle receiver, handle arg0) returns handle = @java:Method {
    name: "plus",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.temporal.TemporalAmount"]
} external;

function java_time_LocalDateTime_plusDays(handle receiver, int arg0) returns handle = @java:Method {
    name: "plusDays",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_plusHours(handle receiver, int arg0) returns handle = @java:Method {
    name: "plusHours",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_plusMinutes(handle receiver, int arg0) returns handle = @java:Method {
    name: "plusMinutes",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_plusMonths(handle receiver, int arg0) returns handle = @java:Method {
    name: "plusMonths",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_plusNanos(handle receiver, int arg0) returns handle = @java:Method {
    name: "plusNanos",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_plusSeconds(handle receiver, int arg0) returns handle = @java:Method {
    name: "plusSeconds",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_plusWeeks(handle receiver, int arg0) returns handle = @java:Method {
    name: "plusWeeks",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_plusYears(handle receiver, int arg0) returns handle = @java:Method {
    name: "plusYears",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_query(handle receiver, handle arg0) returns handle = @java:Method {
    name: "query",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.temporal.TemporalQuery"]
} external;

function java_time_LocalDateTime_range(handle receiver, handle arg0) returns handle = @java:Method {
    name: "range",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.temporal.TemporalField"]
} external;

function java_time_LocalDateTime_toEpochSecond(handle receiver, handle arg0) returns int = @java:Method {
    name: "toEpochSecond",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.ZoneOffset"]
} external;

function java_time_LocalDateTime_toInstant(handle receiver, handle arg0) returns handle = @java:Method {
    name: "toInstant",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.ZoneOffset"]
} external;

function java_time_LocalDateTime_toLocalDate(handle receiver) returns handle = @java:Method {
    name: "toLocalDate",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_toLocalTime(handle receiver) returns handle = @java:Method {
    name: "toLocalTime",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_truncatedTo(handle receiver, handle arg0) returns handle = @java:Method {
    name: "truncatedTo",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.temporal.TemporalUnit"]
} external;

function java_time_LocalDateTime_until(handle receiver, handle arg0, handle arg1) returns int = @java:Method {
    name: "until",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.temporal.Temporal", "java.time.temporal.TemporalUnit"]
} external;

function java_time_LocalDateTime_wait(handle receiver) returns error? = @java:Method {
    name: "wait",
    'class: "java.time.LocalDateTime",
    paramTypes: []
} external;

function java_time_LocalDateTime_wait2(handle receiver, int arg0) returns error? = @java:Method {
    name: "wait",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long"]
} external;

function java_time_LocalDateTime_wait3(handle receiver, int arg0, int arg1) returns error? = @java:Method {
    name: "wait",
    'class: "java.time.LocalDateTime",
    paramTypes: ["long", "int"]
} external;

function java_time_LocalDateTime_with(handle receiver, handle arg0) returns handle = @java:Method {
    name: "with",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.temporal.TemporalAdjuster"]
} external;

function java_time_LocalDateTime_with2(handle receiver, handle arg0, int arg1) returns handle = @java:Method {
    name: "with",
    'class: "java.time.LocalDateTime",
    paramTypes: ["java.time.temporal.TemporalField", "long"]
} external;

function java_time_LocalDateTime_withDayOfMonth(handle receiver, int arg0) returns handle = @java:Method {
    name: "withDayOfMonth",
    'class: "java.time.LocalDateTime",
    paramTypes: ["int"]
} external;

function java_time_LocalDateTime_withDayOfYear(handle receiver, int arg0) returns handle = @java:Method {
    name: "withDayOfYear",
    'class: "java.time.LocalDateTime",
    paramTypes: ["int"]
} external;

function java_time_LocalDateTime_withHour(handle receiver, int arg0) returns handle = @java:Method {
    name: "withHour",
    'class: "java.time.LocalDateTime",
    paramTypes: ["int"]
} external;

function java_time_LocalDateTime_withMinute(handle receiver, int arg0) returns handle = @java:Method {
    name: "withMinute",
    'class: "java.time.LocalDateTime",
    paramTypes: ["int"]
} external;

function java_time_LocalDateTime_withMonth(handle receiver, int arg0) returns handle = @java:Method {
    name: "withMonth",
    'class: "java.time.LocalDateTime",
    paramTypes: ["int"]
} external;

function java_time_LocalDateTime_withNano(handle receiver, int arg0) returns handle = @java:Method {
    name: "withNano",
    'class: "java.time.LocalDateTime",
    paramTypes: ["int"]
} external;

function java_time_LocalDateTime_withSecond(handle receiver, int arg0) returns handle = @java:Method {
    name: "withSecond",
    'class: "java.time.LocalDateTime",
    paramTypes: ["int"]
} external;

function java_time_LocalDateTime_withYear(handle receiver, int arg0) returns handle = @java:Method {
    name: "withYear",
    'class: "java.time.LocalDateTime",
    paramTypes: ["int"]
} external;

function java_time_LocalDateTime_getMIN() returns handle = @java:FieldGet {
    name: "MIN",
    'class: "java.time.LocalDateTime"
} external;

function java_time_LocalDateTime_getMAX() returns handle = @java:FieldGet {
    name: "MAX",
    'class: "java.time.LocalDateTime"
} external;

