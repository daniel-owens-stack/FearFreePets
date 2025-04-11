public class B2BBuyerGroupsAssignmentBatch implements Database.Batchable<sObject>, Database.Stateful {

    public B2BBuyerGroupsAssignmentBatch() { }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id FROM Account_Membership__c WHERE Historical_Membership__c != null and Status__c == \'Active\' AND Membership__r.Active__c == true';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account_Membership__c> accountMemberships){

        try {
            for(Account_Membership__c ilma : accountMemberships) {
                B2BBuyerGroupAssignemntController.handleBuyerGroupsForILMA(ilma);
            }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'Historical Memberships', 'BuyerGroups Assignment');
        }
    }

    public void finish(Database.BatchableContext bc){

    }

    public class HistoricalOrdersException extends Exception {}
}