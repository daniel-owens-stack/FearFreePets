/**
 * @ Author: Gary Guthrie
 * @ Create Time: 2022-11-17 12:23:00
 * @ Modified by: Gary Guthrie
 * @ Modified time: 2022-11-18 06:36:19
 * @ Description: Test class for ContactCourses_CTRL
 */

@IsTest
public with sharing class ContactCourses_CTRL_Test {
    @TestSetup static void setup() {
        TestDataFactory.insertContactData();
        TestDataFactory.insertLMSUserData();
        TestDataFactory.insertCourseData();
    }

    @IsTest static void testCreate() {
        System.debug('==================ContactCourses_CTRL_Test Create=====================');
        Contact testCon = [SELECT SX_User_Id__c FROM Contact WHERE SX_User_Id__c = NULL LIMIT 1];
        Test.startTest();

        ContactCourses_CTRL ctrl = new ContactCourses_CTRL();
        
        SchooxAPI.testResponse = SchooxAPI_Test.getMockResponse(200, SchooxAPI.ApiType.User);
        ContactCourses_CTRL.createUser(testCon.Id);

        testCon = [SELECT SX_User_Id__c FROM Contact WHERE SX_User_Id__c != NULL LIMIT 1];
        SchooxAPI.testResponse = SchooxAPI_Test.getMockResponse(200, SchooxAPI.ApiType.AllCourse);
        ContactCourses_CTRL.getCourse(testCon.Id, testCon.SX_User_Id__c);

        Test.stopTest();
        System.assertEquals(SchooxAPI.apiError, false, 'Get API');
    }
}