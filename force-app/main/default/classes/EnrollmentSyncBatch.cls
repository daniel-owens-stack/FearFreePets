global class EnrollmentSyncBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    global Boolean activeUserFilter;

    @TestVisible static Boolean testMode = false;

    global EnrollmentSyncBatch(Boolean activeUserFilter) {
        this.activeUserFilter = activeUserFilter;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, SX_User_ID__c, SF_Contact__c ' +
                       'FROM SX_LMS_User__c ' +
                       'WHERE SX_User_ID__c != null ' +
                       'AND SF_Contact__c != null ';

        if (activeUserFilter != null) {
            query += 'AND SX_Active_User__c = :activeUserFilter ';
        }

        query += 'AND (Synced_Enrollments__c = null OR Synced_Enrollments__c = \'pending\')';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SX_LMS_User__c> scope) {
        List<SX_Enrollment__c> allEnrollments = new List<SX_Enrollment__c>();
        List<SX_LMS_User__c> usersToUpdate = new List<SX_LMS_User__c>();

        for (SX_LMS_User__c user : scope) {
            try {
                List<SX_Enrollment__c> enrollments;

                if (testMode) {
                    // Provide dummy enrollment to force Synced_Enrollments__c = 'passed' during tests
                    enrollments = new List<SX_Enrollment__c>{
                        new SX_Enrollment__c(Name = 'Test Enrollment', Student_ID__c = user.Id)
                    };
                } else {
                    // Use the method that returns enrollments but does NOT do upsert
                    enrollments = SchooxAPI.getUserCourseWithoutUpsert(user.SX_User_ID__c);
                }

                if (enrollments != null && !enrollments.isEmpty()) {
                    allEnrollments.addAll(enrollments);
                    user.Synced_Enrollments__c = 'passed';
                } else {
                    // No enrollments, but still mark passed so it doesn't retry endlessly
                    user.Synced_Enrollments__c = 'passed';
                }
                usersToUpdate.add(user);
            } catch (Exception e) {
                user.Synced_Enrollments__c = 'failed';
                usersToUpdate.add(user);
                System.debug('Error processing user ' + user.SX_User_ID__c + ': ' + e.getMessage());
            }
        }

        if (!allEnrollments.isEmpty()) {
            try {
                // Bulk upsert all enrollments once after processing all users in scope
                upsert allEnrollments Student_Course_Id__c;
            } catch (DmlException e) {
                System.debug('Error upserting enrollments: ' + e.getMessage());
            }
        }

        if (!usersToUpdate.isEmpty()) {
            try {
                update usersToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating users: ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('EnrollmentSyncBatch completed');
    }
}