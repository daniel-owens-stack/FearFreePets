/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-11-17 22:38:58
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:40:32
 * @ Description: Test class for CreateLMSUnit_CTRL
 */

@isTest
private class CreateLMSUnit_CTRL_Test {
    @testSetup static void setup() {
        List<SX_Above_Unit__c> aboveUnitList = TestDataFactory.insertAboveUnitData();
        List<Account> accList = TestDataFactory.insertAccountData();
        for (Integer i = 0; i < aboveUnitList.size(); i++) {
            accList.get(i).put('SX_Above_Unit_Lookup__c', aboveUnitList.get(i).Id);
        }
        update accList;
    }

    @isTest static void testCreate() {
        System.debug('==================CreateLMSUnit_CTRL_Test Create=====================');
        Account testAcc = [SELECT Name FROM Account WHERE SX_Above_Unit_Lookup__c != null LIMIT 1];
        Test.StartTest();
        
        SchooxAPI.testResponse = SchooxAPI_Test.getMockResponse(200, SchooxAPI.ApiType.Unit);
        CreateLMSUnit_CTRL.createUnit(testAcc.Id);

        Test.StopTest();
        System.assertEquals(SchooxAPI.apiError, false, 'Create Unit API');
    }
}