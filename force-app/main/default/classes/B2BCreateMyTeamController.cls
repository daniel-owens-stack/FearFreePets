public without sharing class B2BCreateMyTeamController {

    @AuraEnabled
    public static Account getAccountDetails() {
        String accountId = B2BUtils.getUserAccountID();
        List<Account> account = [SELECT Id, Admin_Account__c, Business__c
                                 FROM Account 
                                 WHERE Id =: accountId];   
        
        
        return account[0];
    }
}