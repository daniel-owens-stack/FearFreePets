public class B2BBuyerGroupsAssignmentBatch implements Database.Batchable<sObject>, Database.Stateful {

    public B2BBuyerGroupsAssignmentBatch() { }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Account_Id__c, Certified__c, Membership__c FROM Account_Membership__c WHERE Historical_Membership__c != null and Status__c = \'Active\' AND Membership__r.Active__c = true';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account_Membership__c> accountMemberships){

        try {
            List<Account_Membership__c> failedBuyerGroupAssignments = new List<Account_Membership__c>();
            for(Account_Membership__c ilma : accountMemberships) {
                try {
                    B2BBuyerGroupAssignemntController.handleBuyerGroupsForILMA(ilma);
                }
                catch(Exception e) {
                    String errorMessage = 'Buyer Group Assignment Failed for Historical Membership: ' + ilma.Name;
                    ilma.Last_Buyer_Groups_Assignment_Exception__c = B2BHandleCustomException.LogException(new HistoricalOrdersException(errorMessage), 'Historical Memberships', 'Buyer Group Assignment');
                    failedBuyerGroupAssignments.add(ilma);
                }
            }
            Database.update(failedBuyerGroupAssignments);
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'Historical Memberships', 'BuyerGroups Assignment - Batch Level Failure');
        }
    }

    public void finish(Database.BatchableContext bc){

    }

    public class HistoricalOrdersException extends Exception {}
}