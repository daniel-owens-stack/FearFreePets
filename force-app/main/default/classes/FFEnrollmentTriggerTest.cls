@isTest
public class FFEnrollmentTriggerTest {
    @isTest
    static void testTriggerFires() {
        // Create a Person Account
        Account acc = new Account(
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Account' AND IsPersonType=true LIMIT 1].Id,
            LastName = 'Test Person',
            FirstName = 'Trigger'
        );
        insert acc;

        // Create Contact (auto-created for Person Account)
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

        // Create a Membership
        Membership__c membership = new Membership__c(Name = 'Vet Pro');
        insert membership;

        // Create Account_Membership__c
        Account_Membership__c acctMembership = new Account_Membership__c(
            Account_Id__c = acc.Id,
            Membership__c = membership.Id,
            Certified__c = false
        );
        insert acctMembership;

        // Create Course
        SX_Courses__c course = new SX_Courses__c(
            Name = 'Course A',
            Membership__c = membership.Id,
            CE_Hours__c = 5
        );
        insert course;

        // Map Course → Membership through Certification_Course__c
        Certification_Course__c cc = new Certification_Course__c(
            SX_Course__c = course.Id,
            Membership__c = membership.Id
        );
        insert cc;

        // Create LMS User
        SX_LMS_User__c lmsUser = new SX_LMS_User__c(
            SF_Contact__c = con.Id,
            SX_User_ID__c = 'test-user-002',
            SX_Active_User__c = true
        );
        insert lmsUser;

        // Create Enrollment that meets trigger conditions
        SX_Enrollment__c enrollment = new SX_Enrollment__c(
            Name = 'Enroll A',
            SF_Contact_Lookup__c = con.Id,
            SX_Course__c = course.Id,
            SX_percent_Completed__c = 100,
            Student_ID__c = lmsUser.Id
        );
        insert enrollment; // 🚀 fires the trigger

        // Verify Account_Membership__c updated
        Account_Membership__c updated = [
            SELECT Certified__c
            FROM Account_Membership__c
            WHERE Id = :acctMembership.Id
        ];
        System.assertEquals(true, updated.Certified__c, 'Account_Membership__c should be marked Certified');

        // Debug enrollments to see if multiple exist
        List<SX_Enrollment__c> enrollments = [
            SELECT Id, CE_Credits__c, SX_Course__c
            FROM SX_Enrollment__c
            WHERE SF_Contact_Lookup__c = :con.Id
        ];
        System.debug('Enrollments found: ' + enrollments);

        // Verify only 1 enrollment exists for this test
        System.assertEquals(1, enrollments.size(), 'Expected only 1 enrollment in this test');
        System.assertEquals(5, enrollments[0].CE_Credits__c, 'Enrollment should have 5 CE credits');

        // Verify CE credits rolled up to Account
        Account refreshedAcc = [SELECT CE_Credits__c FROM Account WHERE Id = :acc.Id];
        System.debug('Account CE_Credits__c: ' + refreshedAcc.CE_Credits__c);
        System.assertEquals(5, refreshedAcc.CE_Credits__c, 'Account CE_Credits__c should equal enrollment credits');
    }
}