public class UserCourseSyncQueueable implements Queueable, Database.AllowsCallouts {
    private Id userId;

    public UserCourseSyncQueueable(Id userId) {
        this.userId = userId;
    }

    public void execute(QueueableContext context) {
        SX_LMS_User__c user = [
            SELECT Id, SX_User_ID__c, SF_Contact__c
            FROM SX_LMS_User__c
            WHERE Id = :userId
            LIMIT 1
        ];

        try {
            List<SX_Enrollment__c> enrollments = SchooxAPI.getUserCourseWithoutUpsert(user.SX_User_ID__c);

            if (!enrollments.isEmpty()) {
                for (SX_Enrollment__c e : enrollments) {
                    e.Student_ID__c = user.Id;
                    e.SF_Contact_Lookup__c = user.SF_Contact__c;
                }
                Database.insert(enrollments, false);
            }

            user.Synced_Enrollments__c = 'passed';
        } catch (Exception e) {
            user.Synced_Enrollments__c = 'failed';
            System.debug('Error in UserCourseSyncQueueable: ' + e.getMessage());
        }

        update user;
    }
}