/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-11-17 23:01:23
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:40:59
 * @ Description: Test class for Enrollment_CTRL
 */

@isTest
private class Enrollment_CTRL_Test {
    @testSetup static void setup() {
        TestDataFactory.insertContactData();
        TestDataFactory.insertCourseData();
        TestDataFactory.insertLMSUserData();
    }

    @isTest static void testGetData() {
        System.debug('==================Enrollment_CTRL_Test GetData=====================');
        Contact testCon = [SELECT SX_User_Id__c FROM Contact WHERE SX_User_Id__c != null LIMIT 1];
        SX_LMS_User__c testLMSUser = [SELECT SX_User_Id__c FROM SX_LMS_User__c WHERE SX_User_Id__c != null LIMIT 1];
        SX_Courses__c testCourse = [SELECT SX_Course_ID__c FROM SX_Courses__c WHERE SX_Course_ID__c != null LIMIT 1];
        Test.StartTest();

        Enrollment_CTRL.getCourses(testCon.Id, 'Test');
        Enrollment_CTRL.getCourses(testLMSUser.Id, 'Test');
        Enrollment_CTRL.getStudents(testLMSUser.Id, 'Test');

        SchooxAPI.testResponse = SchooxAPI_Test.getMockResponse(200, SchooxAPI.ApiType.UserCourse);
        Enrollment_CTRL.enrollStudent(testCourse.SX_Course_ID__c, testCon.SX_User_Id__c);
        Enrollment_CTRL.enrollCourses(testLMSUser.SX_User_Id__c, new List<String>{testCourse.SX_Course_ID__c});
        Enrollment_CTRL.updateEnrollment(testCourse.SX_Course_ID__c, new List<String>{testLMSUser.SX_User_Id__c});

        Test.StopTest();
    }
}