public with sharing class FFUpdateILMAsFromPLMAController {
    @AuraEnabled(cacheable=true)
    public static Boolean hasPLMA(Id accountId) {
        // Check account type
        Account acct = [
            SELECT IsPersonAccount
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        
        if (acct.IsPersonAccount) {
            return false; // Person accounts should not show button
        }

        // Check for PLMAs
        return [
            SELECT Id 
            FROM Practice_Level_Membership_Assignment__c
            WHERE Business_Account__c = :accountId
            LIMIT 1
        ].size() > 0;
    }
    
    @AuraEnabled
    public static void updateILMAs(Id accountId) {
        List<Practice_Level_Membership_Assignment__c> plmas = [
            SELECT Id, Status__c, Start_Date__c
            FROM Practice_Level_Membership_Assignment__c
            WHERE Business_Account__c = :accountId
        ];
        
        if (plmas.isEmpty()) {
            return; // nothing to do
        }
        
        List<Account_Membership__c> ilmasToUpdate = new List<Account_Membership__c>();
        
        for (Practice_Level_Membership_Assignment__c plma : plmas) {
            List<Account_Membership__c> ilmas = [
                SELECT Id, Status__c, Start_Date__c, Parent_Id__c
                FROM Account_Membership__c
                WHERE Practice_Level_Membership_Assignment__c = :plma.Id
            ];
            
            for (Account_Membership__c ilma : ilmas) {
                ilma.Status__c = plma.Status__c;
                ilma.Start_Date__c = plma.Start_Date__c;
                ilma.Parent_Id__c = accountId;
                ilmasToUpdate.add(ilma);
            }
        }
        
        if (!ilmasToUpdate.isEmpty()) {
            update ilmasToUpdate;
        }
    }
}