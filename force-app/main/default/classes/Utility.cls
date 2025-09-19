/**
 * @ Author: Gary Guthrie
 * @ Create Time: 2022-09-12 23:11:03
 * @ Modified by: Gary Guthrie
 * @ Modified time: 2022-11-17 12:23:53
 * @ Description: Test class is Utility_Test
 */

public with sharing class Utility {
    public static Decimal decimalValue(Object rec) {
        String recValue = String.valueOf(rec);
        return String.isNotBlank(recValue) ? Decimal.valueOf(recValue) : null;
    }

    public static Integer integerValue(Object rec) {
        String recValue = String.valueOf(rec);
        return String.isNotBlank(recValue) ? Integer.valueOf(recValue) : null;
    }

    public static Boolean booleanValue(Object rec) {
        String recValue = String.valueOf(rec);
        return String.isNotBlank(recValue) ? Boolean.valueOf(recValue) : false;
    }

    public static Date dateValue(Object rec) {
        String recValue = String.valueOf(rec);
        return String.isNotBlank(recValue) ? Date.valueOf(recValue) : null;
    }

    public static void insertObject(SObject anyObject) {
        insertObject(new List<SObject>{anyObject});
    }

    public static void insertObject(List<SObject> anyObjects) {
        try {
            insert anyObjects;
            System.debug('🚀 ~ ' + anyObjects.getSObjectType() + ' record inserted: ' + anyObjects.size());
        } catch (Exception ex) {
            printException(ex);
            System.debug('🚀 ~ ' + anyObjects.getSObjectType() + ' Size(): ' + anyObjects.size());
            System.debug(JSON.serializePretty(anyObjects));
        }
    }

    public static void updateObject(SObject anyObject) {
        updateObject(new List<SObject>{anyObject});
    }

    public static void updateObject(List<SObject> anyObjects) {
        try {
            update anyObjects;
            System.debug('🚀 ~ ' + anyObjects.getSObjectType() + ' record updated: ' + anyObjects.size());
        } catch (Exception ex) {
            printException(ex);
            System.debug('🚀 ~ ' + anyObjects.getSObjectType() + ' Size: ' + anyObjects.size());
            System.debug(JSON.serializePretty(anyObjects));
        }
    }

    public static void printException(Exception ex) {
        System.debug('🚀 ~ Exception type caught: ' + ex.getTypeName());    
        System.debug('Message: ' + ex.getMessage());    
        System.debug('Cause: ' + ex.getCause());    // returns null
        System.debug('Line number: ' + ex.getLineNumber());
        System.debug('Stack trace: ' + ex.getStackTraceString());
    }
}