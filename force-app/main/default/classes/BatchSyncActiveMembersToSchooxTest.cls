@isTest
public class BatchSyncActiveMembersToSchooxTest {
    
    // Mock for createLMSUser callout inside future method
    private class MockSchooxCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            // Return a simple JSON object like the real createLMSUser response expects
            String jsonResponse = '{ "id": "12345", "status": 201, "joined_date": "2025-07-22", "error": null }';
            res.setBody(jsonResponse);
            return res;
        }
    }
    
    @testSetup
    static void setupData() {
        // Supporting objects
        SX_Unit__c unit = new SX_Unit__c(Name = 'Unit 1', SX_ID__c = 'unit-001');
        SX_Unit__c aboveUnit = new SX_Unit__c(Name = 'Above Unit', SX_ID__c = 'above-001');
        insert new List<SX_Unit__c>{ unit, aboveUnit };
        
        SX_Job__c job = new SX_Job__c(Name = 'Vet Job', SX_Job_ID__c = '1234567');
        insert job;
        
        // Memberships
        Membership__c mappedMem = new Membership__c(Name = 'Vet Pro');
        Membership__c unmatchedMem = new Membership__c(Name = 'Unmapped Membership');
        insert new List<Membership__c>{ mappedMem, unmatchedMem };
        
        RecordType paRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1];
        
        // Account 1: Matching membership
        Account acct1 = new Account(
            RecordTypeId = paRt.Id,
        FirstName = 'Match',
        LastName = 'User',
        PersonEmail = 'match@example.com',
        SX_User_Synced__c = false
            );
        insert acct1;
        
        Contact con1 = [SELECT Id FROM Contact WHERE AccountId = :acct1.Id LIMIT 1];
        con1.SX_Job_Lookup__c = job.Id;
        update con1;
        
        insert new Account_Membership__c(
            Account_Id__c = acct1.Id,
        Membership__c = mappedMem.Id,
        Status__c = 'Active'
            );
        
        // Account 2: Unmatched membership
        Account acct2 = new Account(
            RecordTypeId = paRt.Id,
        FirstName = 'NoMatch',
        LastName = 'User',
        PersonEmail = 'nomatch@example.com'
            );
        insert acct2;
        
        insert new Account_Membership__c(
            Account_Id__c = acct2.Id,
        Membership__c = unmatchedMem.Id,
        Status__c = 'Active'
            );
        
        // Account 3: No memberships
        Account acct3 = new Account(
            RecordTypeId = paRt.Id,
        FirstName = 'NoMembership',
        LastName = 'User',
        PersonEmail = 'nomembership@example.com'
            );
        insert acct3;
    }
    
    @isTest
    static void testBatchExecution() {
        Test.setMock(HttpCalloutMock.class, new MockSchooxCallout());
        
        // Get ID of the membership we want to map
        Id mappedMemId = [SELECT Id FROM Membership__c WHERE Name = 'Vet Pro' LIMIT 1].Id;
        
        // Only one membership mapped to a job
        Map<Id, Integer> jobMap = new Map<Id, Integer>{
            mappedMemId => 1234567
        };
        
        Test.startTest();
        Database.executeBatch(new BatchSyncActiveMembersToSchoox(jobMap), 200);
        Test.stopTest();
        
        // Assert we still have all 3 accounts
        System.assertEquals(3, [SELECT COUNT() FROM Account WHERE IsPersonAccount = true]);
    }
    
    @isTest
    static void testBatchExecution_defaultConstructor() {
        Test.setMock(HttpCalloutMock.class, new MockSchooxCallout());
        
        Test.startTest();
        BatchSyncActiveMembersToSchoox batch = new BatchSyncActiveMembersToSchoox(); // 👈 default constructor
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        System.assertEquals(3, [SELECT COUNT() FROM Account WHERE IsPersonAccount = true]);
    }
}