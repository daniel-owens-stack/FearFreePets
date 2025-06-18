public class B2BPLMAMembershipEndBatch implements Database.Batchable<sObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Status__c, Expired__c ' +
                       'FROM Practice_Level_Membership_Assignment__c ' + 
                       'WHERE Expiration_Date__c =  YESTERDAY';
        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Practice_Level_Membership_Assignment__c> scope) {
        try {
            List<Practice_Level_Membership_Assignment__c> plmasToUpdate = new List<Practice_Level_Membership_Assignment__c>();

            for(Practice_Level_Membership_Assignment__c plma : scope) {
                plma.Status__c = 'Complete';
                plmasToUpdate.add(plma);
            }
            
            if(plmasToUpdate.size() > 0) {
                update plmasToUpdate;
            }
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BPLMAMembershipEndBatch', 'execute');
        }
    }

    public void finish(Database.BatchableContext bc) {}
}