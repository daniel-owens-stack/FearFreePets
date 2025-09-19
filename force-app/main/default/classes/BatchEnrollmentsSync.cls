public with sharing class BatchEnrollmentsSync implements Database.Batchable<SX_LMS_User__c>, Schedulable, Database.AllowsCallouts {
    
    private List<String> lmsUserExternalIds;
    
    // Constructor to accept external LMS user IDs
    public BatchEnrollmentsSync(List<String> userExternalIds) {
        this.lmsUserExternalIds = userExternalIds;
    }
    
    // No-arg constructor required for Schedulable interface
    public BatchEnrollmentsSync() {
        this.lmsUserExternalIds = new List<String>();
    }
    
    // Schedulable interface method - schedules the batch immediately
    public void execute(SchedulableContext sc) {
        if (lmsUserExternalIds == null || lmsUserExternalIds.isEmpty()) {
            System.debug('BatchEnrollmentsSync scheduled with no user IDs to process.');
            return;
        }
        Database.executeBatch(this, 1);
    }
    
    // Batch start method - query SX_LMS_User__c records based on SX_User_ID__c
    public Iterable<SX_LMS_User__c> start(Database.BatchableContext bc) {
        if (lmsUserExternalIds == null || lmsUserExternalIds.isEmpty()) {
            return new List<SX_LMS_User__c>();
        }
        return [
            SELECT Id, SX_User_ID__c, SF_Contact__c
            FROM SX_LMS_User__c
            WHERE SX_User_ID__c IN :lmsUserExternalIds
        ];
    }
    
    // Batch execute method - process each SX_LMS_User__c record
    public void execute(Database.BatchableContext bc, List<SX_LMS_User__c> scope) {
    for (SX_LMS_User__c lmsUser : scope) {
        String userId = lmsUser.SX_User_ID__c;

        // First callout: get course data
        try {
            FFGetUserCourseWrapper.getSchooxCourseData(userId);
        } catch (Exception e) {
            System.debug('Error fetching course data for userId ' + userId + ': ' + e.getMessage());
        }

        // Second step: check membership count and queue removal if needed
        try {
            if (lmsUser.SF_Contact__c != null) {
                Integer activeMembershipCount = [
                    SELECT COUNT()
                    FROM Account_Membership__c
                    WHERE Account_Id__c = :lmsUser.SF_Contact__c
                      AND Status__c = 'Active'
                ];
                if (activeMembershipCount == 0) {
                    System.enqueueJob(new RemoveLMSUserQueueable(userId));
                }
            }
        } catch (Exception e) {
            System.debug('Error queuing LMS user removal for userId ' + userId + ': ' + e.getMessage());
        }
    }
}
    
    public void finish(Database.BatchableContext bc) {
        System.debug('BatchEnrollmentsSync finished.');
    }
    
    public static void scheduleJob(List<String> userExternalIds) {
        if (userExternalIds == null || userExternalIds.isEmpty()) {
            throw new AuraHandledException('No user IDs to process.');
        }
        String jobName = 'BatchEnrollmentsSync_' + DateTime.now().getTime();
        
        // Schedule to run one minute from now
         String cronExp = Datetime.now().addHours(1).format('s m H d M ? yyyy');
        System.schedule(jobName, cronExp, new BatchEnrollmentsSync(userExternalIds));
    }
}