/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-11-17 23:57:51
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:41:20
 * @ Description: Test class for GetAllJobsEXT
 */

@isTest
private class GetAllJobsEXT_Test {
    @testSetup static void setup() {
        TestDataFactory.insertCourseData();
    }

    static testMethod void testController (){
        List<SX_Job__c> testJobList = [SELECT SX_Job_ID__c FROM SX_Job__c];
        Test.startTest();
        SchooxAPI.testResponse = SchooxAPI_Test.getMockResponse(200, SchooxAPI.ApiType.AllJob);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(testJobList);
        GetAllJobsEXT jobExt = new GetAllJobsEXT(sc);
        jobExt.getBack();
        Test.stopTest();
    }
}