@isTest
public class BatchSyncAllPersonAccountsToSchooxTest {

    private class MockSchooxCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{ "id": "12345", "status": 201, "joined_date": "2025-07-22", "error": null }');
            return res;
        }
    }

    @testSetup
    static void setupData() {
        SX_Unit__c unit = new SX_Unit__c(Name = 'Unit 1', SX_ID__c = 'unit-001');
        SX_Unit__c aboveUnit = new SX_Unit__c(Name = 'Above Unit', SX_ID__c = 'above-001');
        insert new List<SX_Unit__c>{ unit, aboveUnit };

        SX_Job__c job = new SX_Job__c(Name = 'Vet Job', SX_Job_ID__c = '1234567');
        insert job;

        Membership__c mappedMem = new Membership__c(Name = 'Vet Pro');
        Membership__c unmatchedMem = new Membership__c(Name = 'Unmapped Membership');
        insert new List<Membership__c>{ mappedMem, unmatchedMem };

        RecordType paRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1];

        // Account 1: Should trigger createLMSUser (new user)
        Account acct1 = new Account(
            RecordTypeId = paRt.Id,
            FirstName = 'Match',
            LastName = 'User',
            PersonEmail = 'match@example.com',
            SX_User_Synced__c = false,
            Original_System_ID__c = '12347'
        );
        insert acct1;

        Contact con1 = [SELECT Id FROM Contact WHERE AccountId = :acct1.Id LIMIT 1];
        con1.SX_Job_Lookup__c = job.Id;
        con1.SX_Active_User__c = true;
        update con1;

        insert new Account_Membership__c(
            Account_Id__c = acct1.Id,
            Membership__c = mappedMem.Id,
            Status__c = 'Active'
        );

        // Account 2: LMS already exists (simulate updateLMSUser)
        Account acct2 = new Account(
            RecordTypeId = paRt.Id,
            FirstName = 'ExistingLMS',
            LastName = 'User',
            PersonEmail = 'existing@example.com',
            SX_User_Synced__c = false,
            Original_System_ID__c = '22222'
        );
        insert acct2;

        Contact con2 = [SELECT Id FROM Contact WHERE AccountId = :acct2.Id LIMIT 1];
        con2.SX_User_Id__c = 'existing-lms-id';
        con2.SX_Job_Lookup__c = job.Id;
        con2.SX_Active_User__c = true;
        update con2;

        insert new Account_Membership__c(
            Account_Id__c = acct2.Id,
            Membership__c = mappedMem.Id,
            Status__c = 'Active'
        );

        // Account 3: No memberships
        Account acct3 = new Account(
            RecordTypeId = paRt.Id,
            FirstName = 'NoMembership',
            LastName = 'User',
            PersonEmail = 'nomembership@example.com',
            Original_System_ID__c = '12346',
            SX_User_Synced__c = false
        );
        insert acct3;
    }

    @isTest
    static void testBatchExecution_customMap() {
        Test.setMock(HttpCalloutMock.class, new MockSchooxCallout());

        Id mappedMemId = [SELECT Id FROM Membership__c WHERE Name = 'Vet Pro' LIMIT 1].Id;
        Map<Id, Integer> jobMap = new Map<Id, Integer>{
            mappedMemId => 1234567
        };

        Test.startTest();
        Database.executeBatch(new BatchSyncAllPersonAccountsToSchoox(jobMap), 200);
        Test.stopTest();

        List<Account> updated = [
            SELECT FirstName, SX_User_Synced__c
            FROM Account
            WHERE FirstName IN ('Match', 'ExistingLMS')
        ];

        System.assertEquals(2, updated.size(), 'Two accounts should be synced (new + existing)');
        for (Account acc : updated) {
            System.assertEquals(true, acc.SX_User_Synced__c, acc.FirstName + ' should be marked as synced');
        }
    }

    @isTest
    static void testBatchExecution_defaultConstructor() {
        Test.setMock(HttpCalloutMock.class, new MockSchooxCallout());

        Test.startTest();
        Database.executeBatch(new BatchSyncAllPersonAccountsToSchoox(), 200);
        Test.stopTest();

        List<Account> synced = [
            SELECT FirstName, SX_User_Synced__c
            FROM Account
            WHERE FirstName IN ('Match', 'ExistingLMS')
        ];

        System.assertEquals(2, synced.size(), 'Default constructor should sync 2 accounts');
        for (Account acc : synced) {
            System.assertEquals(true, acc.SX_User_Synced__c, acc.FirstName + ' should be marked as synced');
        }
    }
}