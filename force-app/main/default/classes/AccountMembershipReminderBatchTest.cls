@isTest
public class AccountMembershipReminderBatchTest {

    @isTest
    static void testBatchExecution() {
        List<Account_Membership__c> qualifying = new List<Account_Membership__c>();
        // 30 days in future
        qualifying.add(new Account_Membership__c(
            Account_Assignment_Date__c = Date.today().addDays(30).addMonths(-12),
            Send_Renewal_Reminder__c = false
        ));
        // 15 days in future
        qualifying.add(new Account_Membership__c(
            Account_Assignment_Date__c = Date.today().addDays(15).addMonths(-12),
            Send_Renewal_Reminder__c = false
        ));
        // 1 day in future
        qualifying.add(new Account_Membership__c(
            Account_Assignment_Date__c = Date.today().addDays(1).addMonths(-12),
            Send_Renewal_Reminder__c = false
        ));
        // 30 days in past
        qualifying.add(new Account_Membership__c(
            Account_Assignment_Date__c = Date.today().addDays(-30).addMonths(-12),
            Send_Renewal_Reminder__c = false
        ));

        // Non-qualifying record
        List<Account_Membership__c> nonQualifying = new List<Account_Membership__c>();
        Date notTargetDate = Date.today().addDays(20);
        for (Integer i = 0; i < 2; i++) {
            nonQualifying.add(new Account_Membership__c(
                Account_Assignment_Date__c = notTargetDate.addMonths(-12),
                Send_Renewal_Reminder__c = false
            ));
        }

        insert qualifying;
        insert nonQualifying;

        // Debug logging after insert
        List<Account_Membership__c> debugMemberships = [
            SELECT Id, Account_Assignment_Date__c, Expiration_Date__c, Send_Renewal_Reminder__c
            FROM Account_Membership__c
        ];
        for (Account_Membership__c am : debugMemberships) {
            System.debug('Assignment: ' + am.Account_Assignment_Date__c +
                         ', Expiration: ' + am.Expiration_Date__c +
                         ', Reminder: ' + am.Send_Renewal_Reminder__c);
        }

        Test.startTest();
        AccountMembershipReminderBatch batch = new AccountMembershipReminderBatch();
        Database.executeBatch(batch, 5);
        Test.stopTest();

        List<Account_Membership__c> updatedMemberships = [
            SELECT Id FROM Account_Membership__c WHERE Send_Renewal_Reminder__c = true
        ];
        System.assertEquals(4, updatedMemberships.size(),
            'Only records with Expiration_Date__c matching a target date should be updated.');
    }

    @isTest
    static void testFinishMethod() {
        List<Account_Membership__c> memberships = new List<Account_Membership__c>();
        // This will create Expiration_Date__c 15 days from today
        Date assignmentDate = Date.today().addDays(15).addMonths(-12);
        for (Integer i = 0; i < 2; i++) {
            memberships.add(new Account_Membership__c(
                Account_Assignment_Date__c = assignmentDate,
                Send_Renewal_Reminder__c = false
            ));
        }
        insert memberships;

        // Debug logging after insert
        List<Account_Membership__c> debugMemberships = [
            SELECT Id, Account_Assignment_Date__c, Expiration_Date__c, Send_Renewal_Reminder__c
            FROM Account_Membership__c
        ];
        for (Account_Membership__c am : debugMemberships) {
            System.debug('Assignment: ' + am.Account_Assignment_Date__c +
                         ', Expiration: ' + am.Expiration_Date__c +
                         ', Reminder: ' + am.Send_Renewal_Reminder__c);
        }

        Test.startTest();
        AccountMembershipReminderBatch batch = new AccountMembershipReminderBatch();
        Database.executeBatch(batch, 5);
        Test.stopTest();
        // Optionally, assert that the records were updated
        List<Account_Membership__c> updatedMemberships = [
            SELECT Id FROM Account_Membership__c WHERE Send_Renewal_Reminder__c = true
        ];
        System.assertEquals(2, updatedMemberships.size(),
            'Finish method: Only records with Expiration_Date__c matching a target date should be updated.');
    }

    @isTest
    static void testNoRecordsToProcess() {
        // Insert memberships with Expiration_Date__c outside target dates so none qualify
        List<Account_Membership__c> memberships = new List<Account_Membership__c>();
        Date assignmentDate = Date.today().addDays(90).addMonths(-12); // Expiration = today + 90
        for (Integer i = 0; i < 3; i++) {
            memberships.add(new Account_Membership__c(
                Account_Assignment_Date__c = assignmentDate,
                Send_Renewal_Reminder__c = false
            ));
        }
        insert memberships;

        // Debug logging after insert
        List<Account_Membership__c> debugMemberships = [
            SELECT Id, Account_Assignment_Date__c, Expiration_Date__c, Send_Renewal_Reminder__c
            FROM Account_Membership__c
        ];
        for (Account_Membership__c am : debugMemberships) {
            System.debug('Assignment: ' + am.Account_Assignment_Date__c +
                         ', Expiration: ' + am.Expiration_Date__c +
                         ', Reminder: ' + am.Send_Renewal_Reminder__c);
        }

        Test.startTest();
        AccountMembershipReminderBatch batch = new AccountMembershipReminderBatch();
        Database.executeBatch(batch, 5);
        Test.stopTest();

        List<Account_Membership__c> updatedMemberships = [
            SELECT Id FROM Account_Membership__c WHERE Send_Renewal_Reminder__c = true
        ];
        System.assertEquals(0, updatedMemberships.size(), 'No records should have been updated.');
    }
    @isTest
    static void testRenewedMembershipExclusion() {
        List<Account_Membership__c> memberships = new List<Account_Membership__c>();
        // This record should be updated (no renewed membership)
        memberships.add(new Account_Membership__c(
            Account_Assignment_Date__c = Date.today().addDays(30).addMonths(-12),
            Send_Renewal_Reminder__c = false
        ));
        // This record should NOT be updated (renewed membership populated)
        memberships.add(new Account_Membership__c(
            Account_Assignment_Date__c = Date.today().addDays(15).addMonths(-12),
            Send_Renewal_Reminder__c = false,
            Renewed_Membership__c = 'a0EcX000001wHkfUAE' 
        ));
        insert memberships;

        Test.startTest();
        AccountMembershipReminderBatch batch = new AccountMembershipReminderBatch();
        Database.executeBatch(batch, 5);
        Test.stopTest();

        // Query both records
        List<Account_Membership__c> results = [
            SELECT Send_Renewal_Reminder__c, Renewed_Membership__c
            FROM Account_Membership__c
            WHERE Id IN :memberships
        ];
        // Assert only the first record was updated
        System.assertEquals(true, results[0].Send_Renewal_Reminder__c, 'Should be updated');
        System.assertEquals(false, results[1].Send_Renewal_Reminder__c, 'Should NOT be updated because Renewed_Membership__c is populated');
    }

    @isTest
    static void testDebugLogging() {
        List<Account_Membership__c> debugMemberships = [
            SELECT Id, Account_Assignment_Date__c, Expiration_Date__c
            FROM Account_Membership__c
        ];
        for (Account_Membership__c am : debugMemberships) {
            System.debug('Assignment: ' + am.Account_Assignment_Date__c + ', Expiration: ' + am.Expiration_Date__c);
        }
    }
}