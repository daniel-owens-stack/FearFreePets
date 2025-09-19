global class BatchUserCourseSync implements Database.Batchable<SX_LMS_User__c>, Database.AllowsCallouts {
    private Boolean activeStatus;

    public BatchUserCourseSync(Boolean activeStatus) {
        this.activeStatus = activeStatus;
    }

    global Iterable<SX_LMS_User__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, SX_User_ID__c, SF_Contact__c
            FROM SX_LMS_User__c
            WHERE SX_User_ID__c != null
            AND SF_Contact__c != null
            AND SX_Active_User__c = :activeStatus
            AND (Synced_Enrollments__c = null OR Synced_Enrollments__c = 'pending')
            LIMIT 20000
        ];
    }

    global void execute(Database.BatchableContext BC, List<SX_LMS_User__c> scope) {
        for (SX_LMS_User__c user : scope) {
            System.enqueueJob(new UserCourseSyncQueueable(user.Id));
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('BatchUserCourseSync completed.');
    }
}