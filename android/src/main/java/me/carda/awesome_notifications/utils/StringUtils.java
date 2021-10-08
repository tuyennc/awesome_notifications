package me.carda.awesome_notifications.utils;

import java.math.BigInteger;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

import androidx.annotation.NonNull;

public class StringUtils {

    public static Boolean isNullOrEmpty(String string){
        return isNullOrEmpty(string, true);
    }

    public static Boolean isNullOrEmpty(String string, boolean considerWhiteSpaceAsEmpty){
        return string == null || (considerWhiteSpaceAsEmpty ? string.trim().isEmpty() : string.isEmpty());
    }

    public static String getValueOrDefault(String value, String defaultValue){
        return isNullOrEmpty(value) ? defaultValue : value;
    }

    @NonNull
    public static String digestString(String reference){

        if(reference == null)
            return "";

        try {
            reference = reference.replaceAll("\\W+", "");
            byte[] bytes = reference.getBytes(StandardCharsets.UTF_8);

            MessageDigest md = MessageDigest.getInstance("MD5");
            md.reset();
            md.update(bytes);

            final BigInteger bigInt = new BigInteger(1, md.digest());
            return String.format("%032x", bigInt);

        } catch (Exception ex) {
            //("MD5 Cryptography Not Supported");
            return reference;
        }
    }
}
