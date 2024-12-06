public without sharing class B2BEditAccountDetailsController {
    
    @AuraEnabled
    public static void updateAccountRecord(Map<String, String> accountDetails){
        try {
            String accountId = accountDetails.get('Id');

            List<Account> account = [SELECT Id, License_Number__c, Trainer_CCPDT_Number__c, Job_Title__c
                                     FROM Account
                                     WHERE Id = :accountId];

            if(account.size() > 0) {
                account[0].License_Number__c = accountDetails.get('licenseNumber');
                account[0].Trainer_CCPDT_Number__c = accountDetails.get('ccpdtNumber');
                account[0].Job_Title__c = accountDetails.get('jobTitle');

                update account[0];
            }
        } 
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BEditAccountDetailsController', 'updateAccountRecord');
        }
    }
}