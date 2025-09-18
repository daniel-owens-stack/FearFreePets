/**
 * @description       : 
 * @author            : Poojitha Anthati
 * @group             : 
 * @last modified on  : 09-18-2025
 * @last modified by  : Poojitha Anthati
**/
@isTest
public class B2BAccontMembershipListControllerTest {

    @TestSetup static void makeData(){

        Membership__c m = new Membership__c(
            Name = 'Test Membership'
        );
        insert m;

        String accountId = B2BTestDataFactory.createAccount();

        Account businessAccount = new Account(
            Name = 'Test Business Account'
        );
        insert businessAccount;

        Account account = [SELECT Id, Business__c, Admin_Account__c FROM Account WHERE Id = :accountId LIMIT 1];
        account.Business__c = businessAccount.Id;
        account.Admin_Account__c = true;
        update account;

        Account_Membership__c am = new Account_Membership__c(
            Membership__c = m.Id,
            Account_Id__c = accountId,
            Parent_Id__c = businessAccount.Id,
            Account_Assignment_Date__c = Date.valueOf('2024-09-01'),
            Start_Date__c = Date.valueOf('2024-09-01'),
            Welcome_Kit_Status__c = 'Unclaimed',
            Status__c = 'Active'
        );
        insert am;
    }
    
    @isTest static void testGetAccountMemberships() {
        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1].Id;

        Test.StartTest();
        B2BAccontMembershipListController.getAccountMemberships(accountId);
        Test.StopTest();
    }
}