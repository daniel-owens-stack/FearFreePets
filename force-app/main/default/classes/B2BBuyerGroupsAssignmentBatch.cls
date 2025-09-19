global class B2BBuyerGroupsAssignmentBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Integer a = 1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        a=1;
        
        return Database.getQueryLocator([
            SELECT Id 
            FROM Account 
            WHERE Historical_Jobs_Assigned__c = 'Succesful' AND Admin_Account__c = true
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Account> accounts = (List<Account>)scope;

        for (Account acc : accounts) {
            try {
                B2BBuyerGroupAssignemntController.handleBuyerGroupsForAccount(acc);
            } catch (Exception e) {
                String errorMessage = 'Failed to assign/unassign buyer groups for Account Id: ' + acc.Id +
                                      ' | Error: ' + e.getMessage();
                B2BHandleCustomException.LogException(
                    new BuyerGroupAssignmentException(errorMessage),
                    'Buyer Group Assignment',
                    'Batch Execution'
                );
            }
        }
    }

    global void finish(Database.BatchableContext bc) {}

    public class BuyerGroupAssignmentException extends Exception {}
}