/*
 * Last Modified: 2024-09-04 19:36:33
 */

/**
 * @ Author: Gary Guthrie
 * @ Create Time: 2022-11-17 12:18:40
 * @ Modified by: Gary Guthrie
 * @ Modified time: 2024-09-04 00:14:07
 * @ Description: Test class for SX_LMS_UsersTriggerHelper
 */

@IsTest
private class SX_LMS_UsersTriggerHelper_Test {
    @TestSetup static void setup() {
        TestDataFactory.insertLMSUserData();
    }
    
    @IsTest static void testUpdate() {
        System.debug('==================SX_LMS_UsersTriggerHelper_Test Update=====================');
        List<SX_LMS_User__c> lmsList = [SELECT SX_Active_User__c FROM SX_LMS_User__c];
        Test.startTest();
        for(SX_LMS_User__c lms : lmsList){
            lms.SX_Active_User__c = !lms.SX_Active_User__c;
        }
        SchooxAPI.testResponse = SchooxAPI_Test.getMockResponse(200, SchooxAPI.ApiType.UserDetails);
        update lmsList;

        Test.stopTest();
        System.assertEquals(SchooxAPI.apiError, false, 'Get API');
    }

    @IsTest static void testCreate() {
        System.debug('==================SX_LMS_UsersTriggerHelper_Test Create=====================');
        List<SX_LMS_User__c> lmsList = [SELECT SX_Active_User__c, SX_User_ID__c, SF_User__c, SF_Contact__c FROM SX_LMS_User__c WHERE SX_User_ID__c != NULL];
        Test.startTest();
        SX_LMS_User__c lmsCopy = lmsList.get(0).clone(false, false, false, false);
        lmsCopy.SX_User_ID__c = null;
        try{
            insert lmsCopy;
        } catch (Exception ex){}


        SchooxAPI.testResponse = SchooxAPI_Test.getMockResponse(200, SchooxAPI.ApiType.UserDetails);
        delete lmsList;

        Test.stopTest();
        System.assertEquals(SchooxAPI.apiError, false, 'Get API');
    }
}