@IsTest
private class BatchEnrollmentsSync_ProcessPendingTest {

    // Inline mock: returns the same course twice to force one UpsertResult failure
    private class SchooxHttpMock_Dupe7212464 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            if (req.getEndpoint() != null && req.getEndpoint().contains('/courses')) {
                res.setBody(
                    '[{"id":"7212464","progress":"10","enroll_date":"2025-01-01","timecompleted":null},' +
                    ' {"id":"7212464","progress":"20","enroll_date":"2025-01-02","timecompleted":null}]'
                );
            } else {
                res.setBody('{"ok":true}');
            }
            return res;
        }
    }

    @IsTest
    static void processesDueUsers_UpsertHandlesDuplicate_andClearsFlags() {
        // --- Setup org data ---
        Account acct = new Account(Name = 'A1');
        insert acct;

        Contact c1 = new Contact(LastName = 'C1', AccountId = acct.Id, Email = 'c1@test.com');
        Contact c2 = new Contact(LastName = 'C2', AccountId = acct.Id, Email = 'c2@test.com');
        insert new List<Contact>{ c1, c2 };

        // Course must exist or parser ignores it
        SX_Courses__c course = new SX_Courses__c(Name='Course 7212464', SX_Course_ID__c='7212464');
        insert course;

        // Helpful if your parser sets SF_Contact_Lookup__c by Contact.SX_User_Id__c
        c1.SX_User_Id__c = 'ext-due-001';
        c2.SX_User_Id__c = 'ext-future-001';
        update new List<Contact>{ c1, c2 };

        // LMS users
        SX_LMS_User__c dueUser = new SX_LMS_User__c(
            SF_Contact__c = c1.Id,
            SX_User_ID__c = 'ext-due-001',
            SX_Process_Pending__c = true,
            Enrollments_Due_At__c = System.now().addMinutes(-5)
        );
        SX_LMS_User__c futureUser = new SX_LMS_User__c(
            SF_Contact__c = c2.Id,
            SX_User_ID__c = 'ext-future-001',
            SX_Process_Pending__c = true,
            Enrollments_Due_At__c = System.now().addHours(2)
        );
        insert new List<SX_LMS_User__c>{ dueUser, futureUser };

        // Keep removal path quiet for dueUser
        insert new Account_Membership__c(Account_Id__c = c1.AccountId, Status__c = 'Active');

        // --- Pre-insert one enrollment so one upsert will UPDATE (success) ---
        // Make sure to populate the required master-detail field.
        SX_Enrollment__c pre = new SX_Enrollment__c(
            Student_Course_Id__c = 'ext-due-001#7212464',
            Student_ID__c        = dueUser.Id,   // master-detail to SX_LMS_User__c
            SX_Course__c         = course.Id
        );
        insert pre;

        // --- Mock + run batch ---
        Test.setMock(HttpCalloutMock.class, new SchooxHttpMock_Dupe7212464());
        Test.startTest();
        Database.executeBatch(new BatchEnrollmentsSync_ProcessPendingDue(), 50);
        Test.stopTest();

        // --- Asserts ---
        // Due user cleared; future still pending
        dueUser = [SELECT SX_Process_Pending__c, Enrollments_Due_At__c FROM SX_LMS_User__c WHERE Id = :dueUser.Id];
        futureUser = [SELECT SX_Process_Pending__c, Enrollments_Due_At__c FROM SX_LMS_User__c WHERE Id = :futureUser.Id];
        System.assertEquals(false, dueUser.SX_Process_Pending__c);
        System.assertEquals(null,  dueUser.Enrollments_Due_At__c);
        System.assertEquals(true,  futureUser.SX_Process_Pending__c);
        System.assertNotEquals(null, futureUser.Enrollments_Due_At__c);

        // Exactly one row with that external id should exist (the pre-inserted one, updated)
        Integer cnt = [SELECT COUNT() FROM SX_Enrollment__c WHERE Student_Course_Id__c = 'ext-due-001#7212464'];
        System.assertEquals(1, cnt, 'One upsert should succeed; the duplicate in the same upsert should fail');
    }
}