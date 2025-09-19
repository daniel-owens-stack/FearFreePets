/**
 * @ Author: Gary Guthrie
 * @ Create Time: 2022-11-18 00:01:06
 * @ Modified by: Gary Guthrie
 * @ Modified time: 2022-11-18 06:49:51
 * @ Description: Test class for GetAllUnitsEXT
 */

@isTest
private class GetAllUnitsEXT_Test {
    @testSetup static void setup() {
        TestDataFactory.insertCourseData();
    }

    static testMethod void testController (){
        List<SX_Unit__c> testUnitList = [SELECT SX_ID__c FROM SX_Unit__c];
        Test.startTest();
        SchooxAPI.testResponse = SchooxAPI_Test.getMockResponse(200, SchooxAPI.ApiType.AllUnit);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(testUnitList);
        GetAllUnitsEXT unitExt = new GetAllUnitsEXT(sc);
        unitExt.getBack();
        Test.stopTest();
    }
}