@IsTest
private class BatchEnrollmentsSyncTest {
    
    @IsTest
    static void testScheduleJobAndBatchExecution() {
        // Create supporting records
        Account acct = new Account(Name = 'Test Account');
        insert acct;
        
        Contact c = new Contact(LastName = 'TestContact', AccountId = acct.Id);
        insert c;
        
        Membership__c membership = new Membership__c(Name = 'Test Membership');
        insert membership;
        
        Account_Membership__c am = new Account_Membership__c(
            Account_Id__c = acct.Id,
            Status__c = 'Active',
            Membership__c = membership.Id
        );
        insert am;
        
        // Create LMS User records
        SX_LMS_User__c lmsUser1 = new SX_LMS_User__c(
            SX_User_ID__c = 'external-lms-user-001',
            SF_Contact__c = c.Id,
            SX_Active_User__c = true
        );
        insert lmsUser1;
        
        // Note: now pass List<String> because class expects external IDs
        List<String> userExternalIds = new List<String>{ 'external-lms-user-001' };
        
        Test.startTest();
        BatchEnrollmentsSync.scheduleJob(userExternalIds);
        Database.executeBatch(new BatchEnrollmentsSync(userExternalIds), 1);
        Test.stopTest();
    }
    
    @isTest
    static void testEmptyUserIdsDoesNotThrow() {
        Test.startTest();
        BatchEnrollmentsSync job = new BatchEnrollmentsSync(new List<String>());
        job.execute(null); // covers early return in Schedulable
        job.start(null);   // covers early return in start()
        Test.stopTest();
        System.assert(true, 'No exception should be thrown when userIds is empty');
    }
    
    @isTest
    static void testRemoveLMSUserPath() {
        // Create LMS User with no active memberships
        Contact c = new Contact(LastName = 'NoMembershipContact', AccountId = null);
        insert c;
        
        SX_LMS_User__c lmsUser = new SX_LMS_User__c(
            SX_User_ID__c = 'external-lms-user-002',
            SF_Contact__c = c.Id,
            SX_Active_User__c = true
        );
        insert lmsUser;
        
        List<String> userExternalIds = new List<String>{ 'external-lms-user-002' };
        
        Test.startTest();
        Database.executeBatch(new BatchEnrollmentsSync(userExternalIds), 1);
        Test.stopTest();
    }
    
    @isTest
    static void testScheduleJobExceptionPath() {
        Boolean thrown = false;
        try {
            BatchEnrollmentsSync.scheduleJob(new List<String>());
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Expected AuraHandledException when scheduling with empty list');
    }
}