public with sharing class directoryMembersController {
    @AuraEnabled
    public static List<Account> getChildAccounts(String parentId) {
        return [SELECT Name, Job_Title__c
        //(SELECT Assigned_Account_Name__c FROM Account_Memberships__r  WHERE Certified__c = true AND Status__c = 'Active')  
        FROM Account WHERE Business__c = :parentId 
        AND Directory_Opt_In__c = true
        AND Id IN (SELECT Account_Id__c FROM Account_Membership__c WHERE Certified__c = true 
        AND Status__c = 'Active') ];
    }
}