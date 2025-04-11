public class B2BSchooxJobsAssignmentBatch implements Database.Batchable<sObject>, Database.Stateful {

    public B2BSchooxJobsAssignmentBatch() { }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Account_Id__c, Job_Id__c FROM Account_Membership__c WHERE Historical_Membership__c != null and Status__c = \'Active\' AND Membership__r.Active__c = true';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account_Membership__c> accountMemberships){

        try {
            Map<String, List<Integer>> accountJobMap = new Map<String, List<Integer>>();

            for(Account_Membership__c ilma : accountMemberships) {
                if (ilma.Account_Id__c != null && ilma.Job_Id__c != null) {
                    if (!accountJobMap.containsKey(ilma.Account_Id__c)) {
                        accountJobMap.put(ilma.Account_Id__c, new List<Integer>());
                    }
                    accountJobMap.get(ilma.Account_Id__c).add(Integer.valueOf(ilma.Job_Id__c));
                }
            }

            for (String accountId : accountJobMap.keySet()) {
                B2BSchooxAPIController.handleJobAssignmnet(accountId, accountJobMap.get(accountId));
            }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'Historical Memberships', 'Schoox Jobs Assignment');
        }
    }

    public void finish(Database.BatchableContext bc){

    }

    public class HistoricalOrdersException extends Exception {}
}