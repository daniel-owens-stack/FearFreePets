public class B2BCalculatePLMARenewalDatesBatch implements Database.Batchable<sObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        Map<String,String> minMaxDates = B2BUtils.calculateMinMaxRenewalOffsetRange();
        String minDate = minMaxDates.get('minDate');
        String maxDate = minMaxDates.get('maxDate');

        String query = 'SELECT Business_Account__c '+
                       'FROM Practice_Level_Membership_Assignment__c ' +
                       'WHERE Expiration_Date__c >= ' + minDate + ' AND Expiration_Date__c <= ' + maxDate +
                       ' AND Status__c = \'Active\'';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Practice_Level_Membership_Assignment__c> scope) {
        try {

            Set<String> accountIds = new Set<String>();

            for(Practice_Level_Membership_Assignment__c pm : scope) {
                accountIds.add(pm.Business_Account__c);
            }

            List<Account> accounts = [SELECT PracticeLevelRenewalDate__c FROM Account WHERE Id IN :accountIds];

            if(!accounts.isEmpty()) {
                List<Account> accountsToUpdate = new List<Account>();

                for (Account record : accounts) {
                    record.PracticeLevelRenewalDate__c = Date.today();
                    accountsToUpdate.add(record);
                }

                if(!accountsToUpdate.isEmpty()) {
                    update accountsToUpdate;
                }
            }
        } 
        catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BCalculatePLMARenewalDatesBatch', 'execute');
        }
    }

    public void finish(Database.BatchableContext bc) {}
}