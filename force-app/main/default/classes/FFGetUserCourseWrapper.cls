public without sharing class FFGetUserCourseWrapper {
    
    @AuraEnabled
    public static List<SX_Enrollment__c> getSchooxCourseData(String sxUserId) {
        try {
            List<SX_Enrollment__c> courseData = SchooxAPI.getUserCourse(sxUserId);
            return (courseData != null) ? courseData : new List<SX_Enrollment__c>();
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching course data: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void handleLMSUserAsync(Id accountId, List<Integer> courseIds) {
        // Future-safe for UI
        List<String> courseIdStrings = new List<String>();
        for (Integer id : courseIds) {
            courseIdStrings.add(String.valueOf(id));
        }
        runHandleLMSUserFuture(accountId, courseIdStrings);
    }
    
    @future(callout=true)
    public static void runHandleLMSUserFuture(Id accountId, List<String> courseIdsStr) {
        List<Integer> courseIds = new List<Integer>();
        for (String idStr : courseIdsStr) {
            courseIds.add(Integer.valueOf(idStr));
        }
        SchooxAPI.handleLMSUser(accountId, courseIds);
    }
    
    // ✅ New queueable version for use in batch jobs
    public class LMSUserQueueable implements Queueable, Database.AllowsCallouts {
        private Id accountId;
        private List<Integer> courseIds;
        
        public LMSUserQueueable(Id accountId, List<Integer> courseIds) {
            this.accountId = accountId;
            this.courseIds = courseIds;
        }
        
        public void execute(QueueableContext context) {
            if (courseIds == null || courseIds.isEmpty()) {
                // Explicitly pass null when there are no job IDs
                SchooxAPI.handleLMSUser(accountId, null);
            } else {
                SchooxAPI.handleLMSUser(accountId, courseIds);
            }
        }
    }
}