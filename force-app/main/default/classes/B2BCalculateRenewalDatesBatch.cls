public class B2BCalculateRenewalDatesBatch implements Database.Batchable<sObject>, Database.Stateful {

    private String query;

    public B2BCalculateRenewalDatesBatch(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Id personRecordTypeId = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Account' 
            AND IsPersonType = true 
            AND IsActive = true 
            LIMIT 1].Id;

        Id businessRecordTypeId = [
            SELECT Id FROM RecordType 
            WHERE SobjectType = 'Account' 
            AND DeveloperName = 'Business_Account' 
            AND IsActive = true].Id;

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        try {
            List<Account> accountsToUpdate = new List<Account>();

            for (Account record : scope) {

                record.IndividualLevelRenewalDate__c = B2BCalculateRenewalDatesController.getIndividualLevelRenewalDate(record.Id);
                record.PracticeLevelRenewalDate__c = B2BCalculateRenewalDatesController.getPracticeLevelRenewalDate(record.Id);

                accountsToUpdate.add(record);
            }

            if(!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }
        } 
        catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BCalculateRenewalDatesBatch', 'execute');
        }
    }

    public void finish(Database.BatchableContext bc) {}
}