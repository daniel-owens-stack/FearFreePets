public class B2BMembershipEndBatch implements Database.Batchable<sObject>, Database.Stateful {

    private String query;

    public B2BMembershipEndBatch(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account_Membership__c> scope) {
        try {
            for (Account_Membership__c record : scope) {
                B2BMembershipEndController.handleMembershipUnassignment(record);
            }
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BMembershipEndBatch', 'execute');
        }
    }

    public void finish(Database.BatchableContext bc) {}
}