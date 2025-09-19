public with sharing class B2BILMAFromCaseController {
    @AuraEnabled(cacheable=true)
    public static List<Account_Membership__c> getAccountMembershipsForCase(Id caseId) {
        Case c = [SELECT Contact.AccountId FROM Case WHERE Id = :caseId LIMIT 1];
        if (c.Contact == null || c.Contact.AccountId == null) {
            return new List<Account_Membership__c>();
        }

        return [
            SELECT Id, Name, Membership__c, Membership__r.Name,
                   Account_Assignment_Date__c, Status__c
            FROM Account_Membership__c
            WHERE Account_Id__c = :c.Contact.AccountId
            ORDER BY Account_Assignment_Date__c DESC
        ];
    }
}