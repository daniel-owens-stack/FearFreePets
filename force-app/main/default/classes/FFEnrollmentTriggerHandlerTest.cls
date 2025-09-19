@IsTest
private class FFEnrollmentTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        // Create a Person Account (for Contact/Account context)
        Account acc = new Account(
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1].Id,
            LastName = 'Test Person',
            FirstName = 'Unit',
            PersonEmail = 'test@example.com'
        );
        insert acc;

        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

        // Membership
        Membership__c membership = new Membership__c(Name = 'Test Membership');
        insert membership;

        // Create SX_Courses__c record (correct object for the lookup)
        SX_Courses__c course = new SX_Courses__c(Name = 'Dummy Course', Membership__c = membership.Id, CE_Hours__c = 5);
        insert course;

        // Certification_Course__c junction
        Certification_Course__c cc = new Certification_Course__c(
            Membership__c = membership.Id,
            SX_Course__c = course.Id
        );
        insert cc;

        SX_LMS_User__c lmsUser = new SX_LMS_User__c(
            SF_Contact__c = con.Id,
            SX_User_ID__c = 'test-user-001',
            SX_Active_User__c = true
        );
        insert lmsUser;

        // Account_Membership__c
        Account_Membership__c am = new Account_Membership__c(
            Account_Id__c = acc.Id,
            Membership__c = membership.Id,
            Status__c = 'Active',
            Certified__c = false
        );
        insert am;

        // Enrollment (only writable fields, don’t touch formulas)
        SX_Enrollment__c enrollment = new SX_Enrollment__c(
            SF_Contact_Lookup__c = con.Id,
            SX_Course__c = course.Id,
            SX_percent_Completed__c = 100,
            SX_Completed_Date__c = Date.today(),
            Student_ID__c = lmsUser.Id
        );
        insert enrollment;

        SX_Enrollment__c enrollment2 = new SX_Enrollment__c(
            SF_Contact_Lookup__c = con.Id,
            SX_Course__c = course.Id,
            SX_percent_Completed__c = 100,
            SX_Completed_Date__c = Date.today().addDays(-1),
            Student_ID__c = lmsUser.Id
        );
        insert enrollment2;
    }

    @IsTest
    static void testProcessEnrollments() {
        Test.startTest();

        // Force trigger execution by updating enrollment
        SX_Enrollment__c e = [SELECT Id FROM SX_Enrollment__c LIMIT 1];
        e.SX_percent_Completed__c = 100; // redundant, but ensures trigger logic hits
        update e;

        Test.stopTest();

        // Validate Account_Membership updated
        Account_Membership__c am = [SELECT Certified__c FROM Account_Membership__c LIMIT 1];
        System.assertEquals(true, am.Certified__c, 'Membership should be certified after enrollment completion');

        // Validate CE credits (if CE_Credits__c rollup logic applied)
        Account acc = [SELECT CE_Credits__c FROM Account LIMIT 1];
        System.assertEquals(10, acc.CE_Credits__c, 'Account should have CE credits updated');
    }
}