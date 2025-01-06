public class B2BCalculatePLMARenewalDatesBatch implements Database.Batchable<sObject>, Database.Stateful {

    private String query;

    public B2BCalculatePLMARenewalDatesBatch(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

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