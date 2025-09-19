@IsTest
public class BatchUserCourseSyncTest {

    @TestSetup
    static void setup() {
        // Create Contacts
        Contact c = new Contact(LastName = 'TestContact');
        insert c;

        // Create SX_LMS_User__c linked to Contact
        SX_LMS_User__c user = new SX_LMS_User__c(
            SX_User_ID__c = 'TESTUSER1',
            SF_Contact__c = c.Id,
            SX_Active_User__c = true,
            Synced_Enrollments__c = 'pending'
        );
        insert user;
    }

    @IsTest
    static void testBatchExecution() {
        Test.startTest();

        BatchUserCourseSync batch = new BatchUserCourseSync(true);
        Id batchId = Database.executeBatch(batch, 10);

        Test.stopTest();

        // Verify that the batch enqueued queueable
        // Because queueable is async, we assert the SX_LMS_User__c record status was updated to 'passed' or 'failed'
        SX_LMS_User__c updatedUser = [
            SELECT Synced_Enrollments__c FROM SX_LMS_User__c WHERE SX_User_ID__c = 'TESTUSER1' LIMIT 1
        ];
        System.assert(
            updatedUser.Synced_Enrollments__c == 'passed' || updatedUser.Synced_Enrollments__c == 'failed',
            'User sync status should be updated by queueable.'
        );
    }
}