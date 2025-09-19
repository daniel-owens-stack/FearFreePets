@isTest
public class BatchDeactivateLMSUsersTest {
    
    // Mock for HTTP callouts
    private class MockSchooxCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String jsonResponse = '{ "status": "success", "message": "User removed successfully" }';
            res.setBody(jsonResponse);
            return res;
        }
    }
    
    @testSetup
    static void setupData() {
        // Create memberships
        Membership__c membership1 = new Membership__c(Name = 'Inactive Membership');
        Membership__c membership2 = new Membership__c(Name = 'Active Membership');
        insert new List<Membership__c>{ membership1, membership2 };
        
        RecordType paRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1];
        
        // Account 1: Has inactive membership, should be processed
        Account acct1 = new Account(
            RecordTypeId = paRt.Id,
            FirstName = 'Inactive',
            LastName = 'User',
            PersonEmail = 'inactive@example.com',
            Original_System_ID__c = 'SYS001'
        );
        insert acct1;
        
        Contact con1 = [SELECT Id FROM Contact WHERE AccountId = :acct1.Id LIMIT 1];
        con1.SX_Active_User__c = true;
        update con1;
        
        // Create SX_LMS_User linked to contact
        SX_LMS_User__c lmsUser1 = new SX_LMS_User__c(
            //Name = 'Test LMS User 1',
            SX_User_ID__c = 'LMS12345',
            SF_Contact__c = con1.Id,
            SX_Active_User__c = true
        );
        insert lmsUser1;
        
        insert new Account_Membership__c(
            Account_Id__c = acct1.Id,
            Membership__c = membership1.Id,
            Status__c = 'Complete'
        );
        
        // Account 2: Has expired membership, should be processed
        Account acct2 = new Account(
            RecordTypeId = paRt.Id,
            FirstName = 'Expired',
            LastName = 'User',
            PersonEmail = 'expired@example.com',
            Original_System_ID__c = 'SYS002'
        );
        insert acct2;
        
        Contact con2 = [SELECT Id FROM Contact WHERE AccountId = :acct2.Id LIMIT 1];
        con2.SX_Active_User__c = true;
        update con2;
        
        // Create SX_LMS_User linked to contact
        SX_LMS_User__c lmsUser2 = new SX_LMS_User__c(
            //Name = 'Test LMS User 2',
            SX_User_ID__c = 'LMS67890',
            SF_Contact__c = con2.Id,
            SX_Active_User__c = true
        );
        insert lmsUser2;
        
        insert new Account_Membership__c(
            Account_Id__c = acct2.Id,
            Membership__c = membership1.Id,
            Status__c = 'Complete'
        );
        
        // Account 3: Has active membership, should NOT be processed
        Account acct3 = new Account(
            RecordTypeId = paRt.Id,
            FirstName = 'Active',
            LastName = 'User',
            PersonEmail = 'active@example.com',
            Original_System_ID__c = 'SYS003'
        );
        insert acct3;
        
        Contact con3 = [SELECT Id FROM Contact WHERE AccountId = :acct3.Id LIMIT 1];
        con3.SX_Active_User__c = true;
        update con3;
        
        // Create SX_LMS_User linked to contact
        SX_LMS_User__c lmsUser3 = new SX_LMS_User__c(
            //Name = 'Test LMS User 3',
            SX_User_ID__c = 'LMS11111',
            SF_Contact__c = con3.Id,
            SX_Active_User__c = true
        );
        insert lmsUser3;
        
        insert new Account_Membership__c(
            Account_Id__c = acct3.Id,
            Membership__c = membership2.Id,
            Status__c = 'Complete'
        );
        
        // Account 4: No LMS User, should NOT be processed
        Account acct4 = new Account(
            RecordTypeId = paRt.Id,
            FirstName = 'NoLMS',
            LastName = 'User',
            PersonEmail = 'nolms@example.com',
            Original_System_ID__c = 'SYS004'
        );
        insert acct4;
        
        insert new Account_Membership__c(
            Account_Id__c = acct4.Id,
            Membership__c = membership1.Id,
            Status__c = 'Complete'
        );
        
        // Account 5: No email, should NOT be processed
        Account acct5 = new Account(
            RecordTypeId = paRt.Id,
            FirstName = 'NoEmail',
            LastName = 'User',
            Original_System_ID__c = 'SYS005'
        );
        insert acct5;
        
        Contact con5 = [SELECT Id FROM Contact WHERE AccountId = :acct5.Id LIMIT 1];
        con5.SX_Active_User__c = true;
        update con5;
        
        // Create SX_LMS_User linked to contact
        SX_LMS_User__c lmsUser5 = new SX_LMS_User__c(
           // Name = 'Test LMS User 5',
            SX_User_ID__c = 'LMS55555',
            SF_Contact__c = con5.Id,
            SX_Active_User__c = true
        );
        insert lmsUser5;
        
        insert new Account_Membership__c(
            Account_Id__c = acct5.Id,
            Membership__c = membership1.Id,
            Status__c = 'Complete'
        );
        
        // Account 6: No Original_System_ID__c, should NOT be processed
        Account acct6 = new Account(
            RecordTypeId = paRt.Id,
            FirstName = 'NoSystemID',
            LastName = 'User',
            PersonEmail = 'nosystemid@example.com'
        );
        insert acct6;
        
        Contact con6 = [SELECT Id FROM Contact WHERE AccountId = :acct6.Id LIMIT 1];
        con6.SX_Active_User__c = true;
        update con6;
        
        // Create SX_LMS_User linked to contact
        SX_LMS_User__c lmsUser6 = new SX_LMS_User__c(
            //Name = 'Test LMS User 6',
            SX_User_ID__c = 'LMS66666',
            SF_Contact__c = con6.Id,
            SX_Active_User__c = true
        );
        insert lmsUser6;
        
        insert new Account_Membership__c(
            Account_Id__c = acct6.Id,
            Membership__c = membership1.Id,
            Status__c = 'Complete'
        );
    }
    
    @isTest
    static void testBatchExecution_Success() {
        Test.setMock(HttpCalloutMock.class, new MockSchooxCallout());
        
        Test.startTest();
        Database.executeBatch(new BatchDeactivateLMSUsers(), 200);
        Test.stopTest();
        
        // Verify contacts are deactivated for processed accounts
        List<Contact> deactivatedContacts = [
            SELECT SX_Active_User__c, Account.FirstName
            FROM Contact 
            WHERE Account.FirstName IN ('Inactive', 'Expired')
        ];
        
        System.assertEquals(2, deactivatedContacts.size(), 'Two contacts should be deactivated');
        for (Contact con : deactivatedContacts) {
            System.assertEquals(false, con.SX_Active_User__c, 'Contact should be deactivated: ' + con.Account.FirstName);
        }
        
        // Verify LMS User records are deactivated
        List<SX_LMS_User__c> deactivatedLMSUsers = [
            SELECT SX_Active_User__c, SF_Contact__r.Account.FirstName
            FROM SX_LMS_User__c 
            WHERE SF_Contact__r.Account.FirstName IN ('Inactive', 'Expired')
        ];
        
        System.assertEquals(2, deactivatedLMSUsers.size(), 'Two LMS User records should be deactivated');
        for (SX_LMS_User__c lmsUser : deactivatedLMSUsers) {
            System.assertEquals(false, lmsUser.SX_Active_User__c, 'LMS User should be deactivated: ' + lmsUser.SF_Contact__r.Account.FirstName);
        }
        
        // Verify contacts that should NOT be processed remain unchanged
        List<Contact> unchangedContacts = [
            SELECT SX_Active_User__c, Account.FirstName
            FROM Contact 
            WHERE Account.FirstName IN ('Active', 'NoLMS', 'NoEmail', 'NoSystemID')
        ];
        
        System.assertEquals(4, unchangedContacts.size(), 'Four contacts should remain unchanged');
        for (Contact con : unchangedContacts) {
            System.assertEquals(true, con.SX_Active_User__c, 'Contact should remain active: ' + con.Account.FirstName);
        }
        
        // Verify LMS User records that should NOT be processed remain active
        List<SX_LMS_User__c> unchangedLMSUsers = [
            SELECT SX_Active_User__c, SF_Contact__r.Account.FirstName
            FROM SX_LMS_User__c 
            WHERE SF_Contact__r.Account.FirstName IN ('Active', 'NoEmail', 'NoSystemID')
        ];
        
        for (SX_LMS_User__c lmsUser : unchangedLMSUsers) {
            System.assertEquals(true, lmsUser.SX_Active_User__c, 'LMS User should remain active: ' + lmsUser.SF_Contact__r.Account.FirstName);
        }
    }
    
    @isTest
    static void testBatchExecution_QueryLocator() {
        Test.setMock(HttpCalloutMock.class, new MockSchooxCallout());
        
        BatchDeactivateLMSUsers batch = new BatchDeactivateLMSUsers();
        Database.QueryLocator ql = batch.start(null);
        
        // Execute the query to verify it returns the correct records
        List<Account> accounts = Database.query(ql.getQuery());
        
        // Should return only accounts with inactive/expired memberships, email, and Original_System_ID__c
        System.assertEquals(2, accounts.size(), 'Query should return 2 accounts (Inactive and Expired)');
        
        Set<String> expectedNames = new Set<String>{'Inactive', 'Expired'};
        Set<String> actualNames = new Set<String>();
        
        for (Account acc : accounts) {
            actualNames.add(acc.FirstName);
            // Verify the query includes the necessary fields
            System.assertNotEquals(null, acc.PersonContactId, 'PersonContactId should not be null');
        }
        
        System.assertEquals(expectedNames, actualNames, 'Should return accounts with inactive/expired memberships');
    }
    
    @isTest
    static void testBatchExecution_MissingSXUserId() {
        Test.setMock(HttpCalloutMock.class, new MockSchooxCallout());
        
        RecordType paRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1];
        Membership__c membership = [SELECT Id FROM Membership__c LIMIT 1];
        
        // Create account with inactive membership
        Account acct = new Account(
            RecordTypeId = paRt.Id,
            FirstName = 'MissingID',
            LastName = 'User',
            PersonEmail = 'missingid@example.com',
            Original_System_ID__c = 'SYS007'
        );
        insert acct;
        
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :acct.Id LIMIT 1];
        con.SX_Active_User__c = true;
        update con;
        
        // Create an LMS User without SX_User_ID__c but with SX_Active_User__c = true
        SX_LMS_User__c lmsUserNoId = new SX_LMS_User__c(
            //Name = 'LMS User No ID',
            SF_Contact__c = con.Id,
            SX_Active_User__c = true
            // SX_User_ID__c is null
        );
        insert lmsUserNoId;
        
        insert new Account_Membership__c(
            Account_Id__c = acct.Id,
            Membership__c = membership.Id,
            Status__c = 'Complete'
        );
        
        Test.startTest();
        Database.executeBatch(new BatchDeactivateLMSUsers(), 200);
        Test.stopTest();
        
        // Verify account is not processed due to missing SX_User_ID__c
        Contact unchangedContact = [
            SELECT SX_Active_User__c 
            FROM Contact 
            WHERE Account.FirstName = 'MissingID' 
            LIMIT 1
        ];
        System.assertEquals(true, unchangedContact.SX_Active_User__c, 'Contact should remain active when SX_User_ID__c is missing');
    }
    
    @isTest
    static void testBatchExecution_NoLMSUserRecord() {
        Test.setMock(HttpCalloutMock.class, new MockSchooxCallout());
        
        RecordType paRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1];
        Membership__c membership = [SELECT Id FROM Membership__c LIMIT 1];
        
        // Create account with inactive membership but no LMS User record
        Account acct = new Account(
            RecordTypeId = paRt.Id,
            FirstName = 'NoLMSRecord',
            LastName = 'User',
            PersonEmail = 'nolmsrecord@example.com',
            Original_System_ID__c = 'SYS008'
        );
        insert acct;
        
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :acct.Id LIMIT 1];
        con.SX_Active_User__c = true;
        update con;
        
        insert new Account_Membership__c(
            Account_Id__c = acct.Id,
            Membership__c = membership.Id,
            Status__c = 'Complete'
        );
        
        Test.startTest();
        Database.executeBatch(new BatchDeactivateLMSUsers(), 200);
        Test.stopTest();
        
        // Verify account is not processed due to no LMS User record
        Contact unchangedContact = [
            SELECT SX_Active_User__c 
            FROM Contact 
            WHERE Account.FirstName = 'NoLMSRecord' 
            LIMIT 1
        ];
        System.assertEquals(true, unchangedContact.SX_Active_User__c, 'Contact should remain active when no LMS User record exists');
    }
}