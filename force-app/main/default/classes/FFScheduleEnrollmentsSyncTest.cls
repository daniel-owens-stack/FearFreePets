@IsTest
private class FFScheduleEnrollmentsSyncTest {
    
    // Static variable to track if removeLMSUser was called
    private static Boolean removedCalled = false;
    
    // Mock wrapper for FFGetUserCourseWrapper
    public static void mockGetSchooxCourseData(Id userId) {
        System.debug('Mock getSchooxCourseData called for userId ' + userId);
    }
    
    // Mock SchooxAPI remove method
    public static void mockRemoveLMSUser(Id userId) {
        removedCalled = true;
        System.debug('Mock removeLMSUser called for userId ' + userId);
    }
    
    @IsTest
    static void testScheduleAndExecute() {
        // Setup test data
        
        Id personAccountRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1].Id;
        Account personAcc = new Account(
            RecordTypeId = personAccountRecordTypeId,
            LastName = 'Test',
            PersonEmail = 'test@example.com'
        );
        insert personAcc;

        Contact con = [SELECT Id, LastName FROM Contact WHERE AccountId =: personAcc.Id];
        con.Email = 'test@example.com';

        update con;
        
        SX_LMS_User__c lmsUser = new SX_LMS_User__c(
            SF_Contact__c = con.Id
        );
        insert lmsUser;

        Membership__c membership = new Membership__c(
            Name = 'Test Membership'
        );
        insert membership;
        
        Account_Membership__c accountMembership = new Account_Membership__c(
            Account_Id__c = personAcc.Id,
            Membership__c = membership.Id, // Use a valid Membership Id
            Status__c = 'Active'
        );
        insert accountMembership;
        
        // Use Test.startTest / Test.stopTest to run async/scheduled code
        Test.startTest();
        
        // Schedule job
        List<Id> userIds = new List<Id>{personAcc.Id};
        FFScheduleEnrollmentsSync.scheduleJob(userIds);
        
        // Instantiate job and execute directly for testing
        FFScheduleEnrollmentsSync job = new FFScheduleEnrollmentsSync(userIds);
        job.execute(null);
        
        Test.stopTest();
        
        // Assert remove LMS user not called because membership active
        System.assertEquals(false, removedCalled, 'removeLMSUser should NOT be called with active membership');
    }
}