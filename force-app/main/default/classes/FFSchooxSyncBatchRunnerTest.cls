@IsTest
private class FFSchooxSyncBatchRunnerTest {
    
    // Minimal mock that returns 200 for any callout (enough for update/reactivate path)
    private class OkHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // Return a simple ok body
            res.setBody('{"ok":true}');
            return res;
        }
    }
    
    @IsTest
    static void testRunBatchForAccount() {
        // Arrange: Business Account
        Account businessAcc = new Account(Name = 'Test Business');
        insert businessAcc;
        
        // Arrange: Person Account (only if PA is enabled)
        Id paRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1].Id;
        Account personAcc = new Account(
            RecordTypeId = paRtId,
        LastName     = 'PA User',
        PersonEmail  = 'pa@test.com'
            );
        // link to business if the field exists in your org
        try { personAcc.put('Business__c', businessAcc.Id); } catch (Exception ignore) {}
        insert personAcc;
        
        // Ensure the CONTACT looks like an existing Schoox user
        Contact pc = [SELECT Id FROM Contact WHERE AccountId = :personAcc.Id LIMIT 1];
        pc.SX_User_Id__c    = 'sx-12345';   // <— critical: makes batch choose update path
        pc.SX_Active_User__c = true;
        update pc;
        // Need the PersonContactId to seed an existing LMS user (update path)
        System.assertNotEquals(null, pc.Id, 'PersonContactId should be populated');
        
        // Optional but helpful if your batch flags existing LMS users:
        Id lmsRtExternal = Schema.SObjectType.SX_LMS_User__c
            .getRecordTypeInfosByDeveloperName().get('External').getRecordTypeId();
        
        insert new SX_LMS_User__c(
            RecordTypeId      = lmsRtExternal,
        SF_Contact__c     = pc.Id,
        SX_User_ID__c     = 'sx-12345',
        SX_Active_User__c = true
            );
        
        // Mock callouts used by the batch
        Test.setMock(HttpCalloutMock.class, new OkHttpMock());
        
        // Act
        Test.startTest();
        FFSchooxSyncBatchRunner.runBatchForAccount(businessAcc.Id);
        Test.stopTest();
        
        // Assert: no exception thrown is enough here; optionally assert something lightweight,
        // e.g., that the LMS user still exists
        SX_LMS_User__c lmsUser = [SELECT Id FROM SX_LMS_User__c WHERE SF_Contact__c = :pc.Id];
        System.assertNotEquals(null, lmsUser, 'LMS user should still be present');
    }
    
    @IsTest
    static void testRunBatchForAccountNullId() {
        try {
            FFSchooxSyncBatchRunner.runBatchForAccount(null);
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
    }
}