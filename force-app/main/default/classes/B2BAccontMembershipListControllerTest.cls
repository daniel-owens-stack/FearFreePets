@isTest
public class B2BAccontMembershipListControllerTest {

    @TestSetup static void makeData(){

        Membership__c m = new Membership__c(
            Name = 'Test Membership'
        );
        insert m;

        String accountId = B2BTestDataFactory.createAccount();

        Account_Membership__c am = new Account_Membership__c(
            Membership__c = m.Id,
            Account_Id__c = accountId,
            Parent_Id__c = accountId,
            Account_Assignment_Date__c = Date.valueOf('2024-09-01'),
            Start_Date__c = Date.valueOf('2024-09-01'),
            Welcome_Kit_Status__c = 'Unclaimed',
            Status__c = 'Active'
        );
        insert am;
    }
    
    @isTest static void testGetAccountMemberships() {
        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;

        Test.StartTest();
        B2BAccontMembershipListController.getAccountMemberships(accountId);
        Test.StopTest();
    }
}