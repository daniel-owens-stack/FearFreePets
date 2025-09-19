@IsTest
public class UserCourseSyncQueueableTest {
    // Mock HTTP callout returning one enrollment
    private class MockWithEnrollments implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String body = '[{"id":"COURSE1","progress":75,"enroll_date":"2024-01-01","timecompleted":"2024-06-01"}]';
            res.setBody(body);
            return res;
        }
    }

    // Mock HTTP callout returning empty list
    private class MockEmpty implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('[]');
            return res;
        }
    }

    @TestSetup
    static void setupTestData() {
        Contact c = new Contact(LastName = 'QueueableTest');
        insert c;

        SX_LMS_User__c user = new SX_LMS_User__c(
            SX_User_ID__c = 'testUser123',
            SF_Contact__c = c.Id,
            SX_Active_User__c = true,
            Synced_Enrollments__c = 'pending'
        );
        insert user;

        SX_Courses__c course = new SX_Courses__c(
            Name = 'Test Course',
            SX_Course_ID__c = 'COURSE1'
        );
        insert course;
    }

    @IsTest
    static void testQueueableWithEnrollments() {
        Test.setMock(HttpCalloutMock.class, new MockWithEnrollments());
        SX_LMS_User__c user = [SELECT Id FROM SX_LMS_User__c WHERE SX_User_ID__c = 'testUser123' LIMIT 1];

        Test.startTest();
        System.enqueueJob(new UserCourseSyncQueueable(user.Id));
        Test.stopTest();

        user = [SELECT Synced_Enrollments__c FROM SX_LMS_User__c WHERE Id = :user.Id];
        System.assertEquals('passed', user.Synced_Enrollments__c, 'Sync status should be passed');

        List<SX_Enrollment__c> enrollments = [
            SELECT Id FROM SX_Enrollment__c WHERE Student_ID__c = :user.Id
        ];
        System.assertEquals(1, enrollments.size(), 'One enrollment should be created');
    }

    @IsTest
    static void testQueueableWithNoEnrollments() {
        Test.setMock(HttpCalloutMock.class, new MockEmpty());
        SX_LMS_User__c user = [SELECT Id FROM SX_LMS_User__c WHERE SX_User_ID__c = 'testUser123' LIMIT 1];

        Test.startTest();
        System.enqueueJob(new UserCourseSyncQueueable(user.Id));
        Test.stopTest();

        user = [SELECT Synced_Enrollments__c FROM SX_LMS_User__c WHERE Id = :user.Id];
        System.assertEquals('passed', user.Synced_Enrollments__c, 'Sync status should be passed when no enrollments');

        Integer countEn = [SELECT COUNT() FROM SX_Enrollment__c WHERE Student_ID__c = :user.Id];
        System.assertEquals(0, countEn, 'No enrollments should be created');
    }
}