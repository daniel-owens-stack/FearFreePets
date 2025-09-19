public class FFScheduleEnrollmentsSync implements Schedulable {
    private List<Id> lmsUserIds;
    
    // Constructor that accepts a list of user IDs
    public FFScheduleEnrollmentsSync(List<Id> userIds) {
        this.lmsUserIds = userIds;
    }
    
    // Called by the scheduler to run the job
    public void execute(SchedulableContext sc) {
        for (Id userId : lmsUserIds) {
            try {
                FFGetUserCourseWrapper.getSchooxCourseData(userId);
            } catch (Exception e) {
                System.debug('Error fetching course data for userId ' + userId + ': ' + e.getMessage());
            }
            
            try {
                // Check if LMS user has any active memberships before removing
                SX_LMS_User__c lmsUser = [
                    SELECT SF_Contact__c
                    FROM SX_LMS_User__c
                    WHERE SX_User_ID__c = :userId
                    LIMIT 1
                ];
                
                if (lmsUser != null && lmsUser.SF_Contact__c != null) {
                    Integer activeMembershipCount = [
                        SELECT COUNT()
                        FROM Account_Membership__c
                        WHERE Account_Id__c = :lmsUser.SF_Contact__c
                        AND Status__c = 'Active'
                    ];
                    
                    if (activeMembershipCount == 0) {
                        SchooxAPI.removeLMSUser(userId);
                    }
                }
            } catch (Exception e) {
                System.debug('Error removing LMS user for userId ' + userId + ': ' + e.getMessage());
            }
        }
    }
    
    // Static method to schedule this class to run 1 hour later
    public static void scheduleJob(List<Id> userIds) {
        String jobName = 'FFScheduleEnrollmentsSync_' + DateTime.now().getTime();
        String cronExp = getCronExpression(DateTime.now().addHours(1));
        System.schedule(jobName, cronExp, new FFScheduleEnrollmentsSync(userIds));
    }
    
    // Helper to generate cron expression for scheduling
    private static String getCronExpression(DateTime dt) {
        // Build the cron expression manually with correct order and spacing
        return dt.second() + ' ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
    }
    
}