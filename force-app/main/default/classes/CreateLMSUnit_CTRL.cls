/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-11-05 08:25:24
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:40:28
 * @ Description: Test class is CreateLMSUnit_CTRL_Test
 */

public with sharing class CreateLMSUnit_CTRL {
    @AuraEnabled( cacheable=false )
    public static String createUnit(Id accountId) {
        Account acc = [SELECT Name, SX_Above_Unit_Lookup__r.SX_ID__c FROM Account WHERE Id = :accountId LIMIT 1];
        SX_Unit__c lmsUnit = SchooxAPI.createLMSUnit(acc);
        insert lmsUnit;

        update new Account(Id = accountId, SX_Unit_Lookup__c = lmsUnit.Id);
        if (acc.SX_Above_Unit_Lookup__c != null) {
            SX_Role__c unitRole = new SX_Role__c(
                Unit__r = new SX_Unit__c(SX_ID__c = lmsUnit.SX_ID__c),
                Above_Unit__r = new SX_Above_Unit__c(SX_ID__c = acc.SX_Above_Unit_Lookup__r.SX_ID__c),
                Unit_Above_Unit__c = lmsUnit.SX_ID__c + '#' + acc.SX_Above_Unit_Lookup__r.SX_ID__c
            );
            insert unitRole;
        }
        return lmsUnit.SX_ID__c;
    }
}