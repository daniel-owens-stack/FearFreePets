public class B2BCalculateILMARenewalDatesBatch implements Database.Batchable<sObject>, Database.Stateful {

    private String query;

    public B2BCalculateILMARenewalDatesBatch(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account_Membership__c> scope) {
        try {

            Set<String> accountIds = new Set<String>();

            for(Account_Membership__c am : scope) {
                accountIds.add(am.Parent_Id__c);
            }

            List<Account> accounts = [SELECT IndividualLevelRenewalDate__c FROM Account WHERE Id IN :accountIds];

            if(!accounts.isEmpty()) {
                List<Account> accountsToUpdate = new List<Account>();

                for (Account record : accounts) {
                    record.IndividualLevelRenewalDate__c = Date.today();
                    accountsToUpdate.add(record);
                }

                if(!accountsToUpdate.isEmpty()) {
                    update accountsToUpdate;
                }
            }
        } 
        catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BCalculateILMARenewalDatesBatch', 'execute');
        }
    }

    public void finish(Database.BatchableContext bc) {}
}