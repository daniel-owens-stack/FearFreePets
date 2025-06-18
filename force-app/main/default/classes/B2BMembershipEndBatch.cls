public class B2BMembershipEndBatch implements Database.Batchable<sObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Status__c, Account_Id__c, can_be_fully_reassigned__c, Membership__c, Job_Id__c, Certified__c, Expired__c ' +
                       'FROM Account_Membership__c ' + 
                       'WHERE Expiration_Date__c =  YESTERDAY OR LastModifiedDate = YESTERDAY';
        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account_Membership__c> scope) {
        try {
            B2BMembershipEndController.handleMembershipUnassignments(scope);
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BMembershipEndBatch', 'execute');
        }
    }

    public void finish(Database.BatchableContext bc) {}
}