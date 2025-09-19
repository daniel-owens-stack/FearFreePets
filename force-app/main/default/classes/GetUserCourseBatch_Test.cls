/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-11-18 00:04:36
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:42:19
 * @ Description: Test class for GetUserCourseBatch
 */

@isTest
private with sharing class GetUserCourseBatch_Test {
    @testSetup static void setup() {
        TestDataFactory.insertLMSUserData();
        TestDataFactory.insertCourseData();
    }

    @isTest static void testController (){
        Test.startTest();
        SchooxAPI.testResponse = SchooxAPI_Test.getMockResponse(200, SchooxAPI.ApiType.UserCourse);
        new GetUserCourseBatch().execute(null);
        Test.stopTest();
    }
}