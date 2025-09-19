/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-11-18 06:13:10
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:41:43
 * @ Description: Test class for GetAllSchooxScheduler
 */

@isTest
private class GetAllSchooxScheduler_Test {
    @testSetup static void setup() {
        TestDataFactory.insertLMSUserData();
        TestDataFactory.insertCourseData();
    }

    @isTest static void testGetData(){
        Test.startTest();
        SchooxAPI.testResponse = SchooxAPI_Test.getMockResponse(200, SchooxAPI.ApiType.AllUnit);
        new GetAllSchooxScheduler().execute(null);
        Test.stopTest();
    }
}