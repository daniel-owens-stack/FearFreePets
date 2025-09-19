/**
 * @ Author: Gary Guthrie
 * @ Create Time: 2022-11-17 23:50:27
 * @ Modified by: Gary Guthrie
 * @ Modified time: 2022-11-18 06:50:13
 * @ Description: Test class for GetAllCoursesEXT
 */

@isTest
private class GetAllCoursesEXT_Test {
    @testSetup static void setup() {
        TestDataFactory.insertCourseData();
    }

    static testMethod void testController (){
        List<SX_Courses__c> testCourseList = [SELECT SX_Course_ID__c FROM SX_Courses__c];
        Test.startTest();
        SchooxAPI.testResponse = SchooxAPI_Test.getMockResponse(200, SchooxAPI.ApiType.AllCourse);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(testCourseList);
        GetAllCoursesEXT courseExt = new GetAllCoursesEXT(sc);
        courseExt.getBack();
        Test.stopTest();
    }
}