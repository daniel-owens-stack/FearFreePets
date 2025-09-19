@isTest
public class B2BMembershipEndBatchRunnerTest {
    
    @isTest
    static void testSimulateRunWithMemberships() {
        // Setup test data
        Id accountId = B2BTestDataFactory.createAccount();

        Membership__c m = new Membership__c(
            Name = 'Test Membership',
            Job_Id__c = 123456
        );
        insert m;
        
        // Create test Account_Membership__c records
        List<Account_Membership__c> memberships = new List<Account_Membership__c>();
        for (Integer i = 0; i < 3; i++) {
            memberships.add(new Account_Membership__c(
                Account_Id__c = accountId,
                Status__c = 'Active',
                Account_Assignment_Date__c = System.today().addMonths(-12).addDays(-1),
                can_be_fully_reassigned__c = false,
                Membership__c = m.id
            ));
        }
        insert memberships;

        Test.startTest();
        String result = B2BMembershipEndBatchRunner.simulateRun(Date.today().addDays(-1));
        Test.stopTest();
    }

    @isTest
    static void testSimulateRunNoMemberships() {
        // Setup: no Account_Membership__c inserted

        Test.startTest();
        String result = B2BMembershipEndBatchRunner.simulateRun(Date.today());
        Test.stopTest();

        System.assertEquals('No memberships found for the selected date.', result, 'Expected no membership message');
    }

    @isTest
    static void testSimulateRunWithException() {
        // Force an exception by inserting a record with missing required fields
        Account_Membership__c invalidMembership = new Account_Membership__c(
            Status__c = 'Active',
            Account_Assignment_Date__c = System.today().addMonths(-12).addDays(-1)
            // Missing Account_Id__c which may be required
        );
        insert invalidMembership;

        Test.startTest();
        String result = B2BMembershipEndBatchRunner.simulateRun(Date.today());
        Test.stopTest();
    }
}