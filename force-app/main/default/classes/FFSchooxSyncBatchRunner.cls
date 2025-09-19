public with sharing class FFSchooxSyncBatchRunner {
    @AuraEnabled
    public static void runBatchForAccount(Id accountId) {
         if (accountId == null) {
            throw new AuraHandledException('No Account found provided to FFSchooxSyncBatchRunner.');
        }
        Account acct = [SELECT Id, IsPersonAccount FROM Account WHERE Id = :accountId LIMIT 1];
        
        List<Id> targetAccounts = acct.IsPersonAccount ?
            new List<Id>{ acct.Id } :
            new List<Id>((new Map<Id, Account>([SELECT Id FROM Account WHERE IsPersonAccount = true AND Business__c = :acct.Id AND PersonEmail != null])).keySet());
        
        if (targetAccounts.isEmpty()) {
            throw new AuraHandledException('No valid Person Accounts found.');
        }
        
        Database.executeBatch(new BatchFFSchooxSync(targetAccounts), 1);
    }
}