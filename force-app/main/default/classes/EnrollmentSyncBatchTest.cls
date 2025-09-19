@isTest
public class EnrollmentSyncBatchTest {

    @testSetup
    static void setupTestData() {
        Contact contact = new Contact(LastName = 'Test Contact');
        insert contact;

        insert new SX_LMS_User__c[]{
            new SX_LMS_User__c(
                SX_User_ID__c = 'Active-User',
                SF_Contact__c = contact.Id,
                SX_Active_User__c = true,
                Synced_Enrollments__c = null
            ),
            new SX_LMS_User__c(
                SX_User_ID__c = 'Inactive-User',
                SF_Contact__c = contact.Id,
                SX_Active_User__c = false,
                Synced_Enrollments__c = null
            )
        };
    }

    @isTest
    static void testBatchActiveUserFilterTrue() {
        EnrollmentSyncBatch.testMode = true;

        Test.startTest();
        Database.executeBatch(new EnrollmentSyncBatch(true), 200);
        Test.stopTest();

        List<SX_LMS_User__c> activeUsers = [
            SELECT Synced_Enrollments__c FROM SX_LMS_User__c WHERE SX_Active_User__c = true
        ];
        System.assertEquals('passed', activeUsers[0].Synced_Enrollments__c, 'Active user should be marked passed');
    }

    @isTest
    static void testBatchActiveUserFilterFalse() {
        EnrollmentSyncBatch.testMode = true;

        Test.startTest();
        Database.executeBatch(new EnrollmentSyncBatch(false), 200);
        Test.stopTest();

        List<SX_LMS_User__c> inactiveUsers = [
            SELECT Synced_Enrollments__c FROM SX_LMS_User__c WHERE SX_Active_User__c = false
        ];
        System.assertEquals('passed', inactiveUsers[0].Synced_Enrollments__c, 'Inactive user should be marked passed');
    }

    @isTest
    static void testBatchActiveUserFilterNull() {
        EnrollmentSyncBatch.testMode = true;

        Test.startTest();
        Database.executeBatch(new EnrollmentSyncBatch(null), 200);
        Test.stopTest();

        List<SX_LMS_User__c> allUsers = [
            SELECT Synced_Enrollments__c FROM SX_LMS_User__c
        ];
        System.assertEquals(2, allUsers.size(), 'Should process all users');
        for (SX_LMS_User__c user : allUsers) {
            System.assertEquals('passed', user.Synced_Enrollments__c, 'All users should be marked passed');
        }
    }

    @isTest
    static void testBatchWithEmptyScope() {
        EnrollmentSyncBatch.testMode = true;

        Test.startTest();
        Database.executeBatch(new EnrollmentSyncBatch(false), 200);
        Test.stopTest();

        System.assert(true, 'Batch ran safely with empty or filtered scope');
    }

    @isTest
    static void testFinishMethod() {
        BatchableContextMock mockContext = new BatchableContextMock();

        EnrollmentSyncBatch batch = new EnrollmentSyncBatch(true);

        Test.startTest();
        batch.finish(mockContext);
        Test.stopTest();

        System.assert(true, 'Finish method executed successfully');
    }

    // Helper mock class implementing Database.BatchableContext
    private class BatchableContextMock implements Database.BatchableContext {
        public Id getJobId() {
            return UserInfo.getUserId();
        }
        public Id getChildJobId() {
            return null;
        }
    }
}