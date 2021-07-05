package me.carda.awesome_notifications.utils;

import java.sql.Time;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;

public class DateUtils {

    public static TimeZone utcTimeZone = TimeZone.getTimeZone("UTC");
    public static TimeZone localTimeZone = TimeZone.getDefault();

    public static Date roundSeconds(Date reference, TimeZone timeZone){
        if(reference == null) return null;
        if(timeZone == null) timeZone = DateUtils.localTimeZone;

        Calendar calendarHelper = Calendar.getInstance();
        calendarHelper.setTimeZone(timeZone);
        calendarHelper.setTime(reference);

        if (calendarHelper.get(Calendar.MILLISECOND) > 500){
            calendarHelper.add(Calendar.SECOND, 1);
        }
        calendarHelper.set(Calendar.MILLISECOND, 0);

        return calendarHelper.getTime();
    }

    public static Date ceilSeconds(Date reference, TimeZone timeZone){
        if(reference == null) return null;
        if(timeZone == null) timeZone = DateUtils.localTimeZone;

        Calendar calendarHelper = Calendar.getInstance();
        calendarHelper.setTimeZone(timeZone);
        calendarHelper.setTime(reference);

        if (calendarHelper.get(Calendar.MILLISECOND) > 0){
            calendarHelper.add(Calendar.SECOND, 1);
        }
        calendarHelper.set(Calendar.MILLISECOND, 0);

        return calendarHelper.getTime();
    }

    public static Date floorSeconds(Date reference, TimeZone timeZone){
        if(reference == null) return null;
        if(timeZone == null) timeZone = DateUtils.localTimeZone;

        Calendar calendarHelper = Calendar.getInstance();
        calendarHelper.setTimeZone(timeZone);
        calendarHelper.setTime(reference);

        calendarHelper.set(Calendar.MILLISECOND, 0);

        return calendarHelper.getTime();
    }

    public static Date stringToDate(String dateTime, String fromTimeZone) throws AwesomeNotificationException {
        try {
            TimeZone timeZone = TimeZone.getTimeZone(fromTimeZone);

            if(timeZone == null)
                throw new AwesomeNotificationException("Invalid time zone");

            SimpleDateFormat simpleDateFormat = new SimpleDateFormat(Definitions.DATE_FORMAT, Locale.US);
            simpleDateFormat.setTimeZone(timeZone);

            return simpleDateFormat.parse(dateTime);
        } catch (ParseException e) {
            e.printStackTrace();
            throw new AwesomeNotificationException("Invalid date");
        }
    }

    public static String dateToString(Date dateTime, String fromTimeZone) throws AwesomeNotificationException {
        TimeZone timeZone = TimeZone.getTimeZone(fromTimeZone);

        if(timeZone == null)
            throw new AwesomeNotificationException("Invalid time zone");

        SimpleDateFormat simpleDateFormat = new SimpleDateFormat(Definitions.DATE_FORMAT, Locale.US);
        simpleDateFormat.setTimeZone(timeZone);

        return simpleDateFormat.format(dateTime);
    }

    public static String getLocalDate(String fromTimeZone) throws AwesomeNotificationException {
        TimeZone timeZone = (fromTimeZone == null) ?
                localTimeZone :
                TimeZone.getTimeZone(fromTimeZone);

        if(timeZone == null)
            throw new AwesomeNotificationException("Invalid time zone");

        Calendar calendar = Calendar.getInstance();
        calendar.setTimeZone(timeZone);

        SimpleDateFormat simpleDateFormat = new SimpleDateFormat(Definitions.DATE_FORMAT, Locale.US);
        simpleDateFormat.setTimeZone(timeZone);

        return simpleDateFormat.format(calendar.getTime());
    }

    public static Date shiftToTimeZone(Date date, TimeZone timeZone) {
        timeZone = (timeZone == null) ? utcTimeZone : timeZone;

        Calendar calendar = Calendar.getInstance();
        calendar.setTime(date);
        calendar.setTimeZone(timeZone);

        SimpleDateFormat simpleDateFormat = new SimpleDateFormat(Definitions.DATE_FORMAT, Locale.US);
        simpleDateFormat.setTimeZone(timeZone);

        return calendar.getTime();
    }

    public static String getUTCDate(){
        Calendar calendar = Calendar.getInstance();
        calendar.setTimeZone(utcTimeZone);

        SimpleDateFormat simpleDateFormat = new SimpleDateFormat(Definitions.DATE_FORMAT, Locale.US);
        simpleDateFormat.setTimeZone(utcTimeZone);

        return simpleDateFormat.format(calendar.getTime());
    }

    public static Date getUTCDateTime(){
        Calendar calendar = Calendar.getInstance();
        calendar.setTimeZone(utcTimeZone);
        return calendar.getTime();
    }

    public static Date getLocalDateTime(String fromTimeZone) throws Exception {
        TimeZone timeZone;

        if(fromTimeZone == null)
            timeZone = localTimeZone;
        else
            timeZone = TimeZone.getTimeZone(fromTimeZone);

        if(timeZone == null)
            throw new AwesomeNotificationException("Invalid time zone");

        Calendar calendar = Calendar.getInstance();
        calendar.setTimeZone(timeZone);
        return calendar.getTime();
    }
}
