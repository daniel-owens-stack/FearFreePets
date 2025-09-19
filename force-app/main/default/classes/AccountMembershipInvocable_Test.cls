/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 07-30-2025 - FSM
 * @last modified by  : FSM
**/
@IsTest
public with sharing class AccountMembershipInvocable_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test business account (this will be the input)
        Account businessAccount = new Account(
            Name = 'Test Business Account'
        );
        insert businessAccount;
        
        // Create regular accounts that reference the business account
        Account regularAccount1 = new Account(
            Name = 'Test Regular Account 1',
            Business__c = businessAccount.Id
        );
        insert regularAccount1;
        
        Account regularAccount2 = new Account(
            Name = 'Test Regular Account 2',
            Business__c = businessAccount.Id
        );
        insert regularAccount2;
        
        // Create test account memberships for the regular accounts
        Account_Membership__c membership1 = new Account_Membership__c(
            Account_Id__c = regularAccount1.Id
        );
        insert membership1;
        
        // Create a second membership to test ordering
        Account_Membership__c membership2 = new Account_Membership__c(
            Account_Id__c = regularAccount1.Id
        );
        insert membership2;
        
        // Create membership for second account
        Account_Membership__c membership3 = new Account_Membership__c(
            Account_Id__c = regularAccount2.Id
        );
        insert membership3;
    }
    
    @IsTest
    static void testGetAccountMemberships_Success() {
        // Get the business account (this will be the input)
        Account businessAccount = [SELECT Id, Name FROM Account WHERE Business__c = null LIMIT 1];
        
        // Create input for the invocable
        AccountMembershipInvocable.InputRequest input = new AccountMembershipInvocable.InputRequest();
        input.accountId = businessAccount.Id;
        
        Test.startTest();
        List<AccountMembershipInvocable.OutputResult> results = 
            AccountMembershipInvocable.getAccountMemberships(new List<AccountMembershipInvocable.InputRequest>{input});
        Test.stopTest();
        
        // Verify results - should return a list with one OutputResult containing all memberships
        System.assertEquals(1, results.size(), 'Should return exactly one OutputResult');
        System.assertEquals(2, results[0].memberships.size(), 'Should return exactly two memberships in the first result (1 from each child account due to LIMIT 1)');
        
        // Debug: Print what we got
        System.debug('Results returned: ' + results.size() + ' OutputResults');
        System.debug('First result contains: ' + results[0].memberships.size() + ' memberships');
        for (Account_Membership__c membership : results[0].memberships) {
            System.debug('Membership: ' + membership.Name + ', Created: ' + membership.CreatedDate + ', ID: ' + membership.Id);
        }
        
        // Verify each membership has the expected data
        for (Account_Membership__c membership : results[0].memberships) {
            System.assertNotEquals(null, membership.Id, 'Membership ID should not be null');
            System.assertNotEquals(null, membership.Name, 'Membership Name should not be null');
            System.assertNotEquals(null, membership.CreatedDate, 'Created Date should not be null');
        }
        
        // Verify that we have exactly 2 memberships returned (1 from account1, 1 from account2 due to LIMIT 1)
        System.assertEquals(2, results[0].memberships.size(), 'Should return exactly 2 memberships (1 from each child account due to LIMIT 1)');
        
        // Verify that we have the expected number of memberships
        System.assertEquals(2, results[0].memberships.size(), 'Should return exactly 2 memberships (1 from each child account due to LIMIT 1)');
    }
    
    @IsTest
    static void testGetAccountMemberships_NoMemberships() {
        // Create a business account without any child accounts that have memberships
        Account businessAccountNoMemberships = new Account(
            Name = 'Business Account No Memberships'
        );
        insert businessAccountNoMemberships;
        
        // Create input for the invocable
        AccountMembershipInvocable.InputRequest input = new AccountMembershipInvocable.InputRequest();
        input.accountId = businessAccountNoMemberships.Id;
        
        Test.startTest();
        List<AccountMembershipInvocable.OutputResult> results = 
            AccountMembershipInvocable.getAccountMemberships(new List<AccountMembershipInvocable.InputRequest>{input});
        Test.stopTest();
        
        // Verify results - should return a list with one OutputResult containing empty memberships
        System.assertEquals(1, results.size(), 'Should return exactly one OutputResult');
        System.assertEquals(0, results[0].memberships.size(), 'Should return empty list when no accounts with memberships exist');
    }
    
    @IsTest
    static void testGetAccountMemberships_NullInput() {
        // Create input with null account ID
        AccountMembershipInvocable.InputRequest input = new AccountMembershipInvocable.InputRequest();
        input.accountId = null;
        
        Test.startTest();
        List<AccountMembershipInvocable.OutputResult> results = 
            AccountMembershipInvocable.getAccountMemberships(new List<AccountMembershipInvocable.InputRequest>{input});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return exactly one OutputResult');
        System.assertEquals(0, results[0].memberships.size(), 'Should return empty list for null input');
    }
    
    @IsTest
    static void testGetAccountMemberships_InvalidAccountId() {
        // Create input with invalid account ID
        AccountMembershipInvocable.InputRequest input = new AccountMembershipInvocable.InputRequest();
        input.accountId = '001000000000000'; // Invalid ID
        
        Test.startTest();
        List<AccountMembershipInvocable.OutputResult> results = 
            AccountMembershipInvocable.getAccountMemberships(new List<AccountMembershipInvocable.InputRequest>{input});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return exactly one OutputResult');
        System.assertEquals(0, results[0].memberships.size(), 'Should return empty list for invalid account ID');
    }
    
    @IsTest
    static void testGetAccountMemberships_MultipleInputs() {
        // Get business accounts
        List<Account> businessAccounts = [SELECT Id, Name FROM Account WHERE Business__c = null LIMIT 2];
        
        // Create inputs for multiple business accounts
        List<AccountMembershipInvocable.InputRequest> inputs = new List<AccountMembershipInvocable.InputRequest>();
        for (Account acc : businessAccounts) {
            AccountMembershipInvocable.InputRequest input = new AccountMembershipInvocable.InputRequest();
            input.accountId = acc.Id;
            inputs.add(input);
        }
        
        Test.startTest();
        List<AccountMembershipInvocable.OutputResult> results = 
            AccountMembershipInvocable.getAccountMemberships(inputs);
        Test.stopTest();
        
        // Verify results - should return an OutputResult for each input
        System.assertEquals(inputs.size(), results.size(), 'Should return one OutputResult per input');
        
        // Verify each OutputResult has the expected data
        for (AccountMembershipInvocable.OutputResult result : results) {
            for (Account_Membership__c membership : result.memberships) {
                System.assertNotEquals(null, membership.Id, 'Membership ID should not be null');
                System.assertNotEquals(null, membership.Name, 'Membership Name should not be null');
            }
        }
    }
}