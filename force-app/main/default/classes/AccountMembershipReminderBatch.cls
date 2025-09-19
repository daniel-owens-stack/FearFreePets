global virtual class AccountMembershipReminderBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Integer updatedCount = 0; // Tracks how many records were updated

    global List<Date> targetDates;

    // Default constructor for production use
    global AccountMembershipReminderBatch() {
        this.targetDates = new List<Date>{
            Date.today().addDays(30), //30 days before expiration
            Date.today().addDays(15), //15 days before expiration
            Date.today().addDays(1), //1 day before expiration),
            Date.today().addDays(-30), //30 days after expiration
            Date.today().addDays(-90), //90 days after expiration
            Date.today().addDays(-270) //270 days after expiration
        };
    }

    // Overloaded constructor for test use
    global AccountMembershipReminderBatch(List<Date> customTargetDates) {
        this.targetDates = customTargetDates;
    }

    global Database.QueryLocator start(Database.BatchableContext batchContext) {
        System.debug('Batch Target Dates: ' + targetDates);
        
        return Database.getQueryLocator([
            SELECT Id, Send_Renewal_Reminder__c,Renewed_Membership__c
            FROM Account_Membership__c
            WHERE Expiration_Date__c IN :targetDates
            AND Send_Renewal_Reminder__c = false
        ]);
    }

    global void execute(Database.BatchableContext batchContext, List<Account_Membership__c> scope) {
        List<Account_Membership__c> toUpdate = new List<Account_Membership__c>();

        for (Account_Membership__c am : scope) {
            if (!am.Send_Renewal_Reminder__c && am.Renewed_Membership__c == null) {
                am.Send_Renewal_Reminder__c = true;
                toUpdate.add(am);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
            updatedCount += toUpdate.size(); // Add to total count
        }
    }

    global void finish(Database.BatchableContext batchContext) {
        System.debug('⚙️ Finish method called for AccountMembershipReminderBatch.');
        System.debug('📦 Total number of records updated: ' + updatedCount);        
    }    
}