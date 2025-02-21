@isTest
public class B2BBuyerGroupAssignemntControllerTest {
    
    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String accountId = B2BTestDataFactory.createAccount();

        Membership__c m = new Membership__c(
            Name = 'Test Membership'
        );
        insert m;

        Account_Membership__c am = new Account_Membership__c(
            Membership__c = m.Id,
            Account_Id__c = accountId,
            Parent_Id__c = accountId,
            Purchaser_Account__c = accountId,
            Account_Assignment_Date__c = System.today(),
            Start_Date__c = System.today(),
            Welcome_Kit_Status__c = 'Unavailable',
            Status__c = 'Active'
        );
        insert am;

        BuyerAccount ba = new BuyerAccount(
            BuyerId = accountId,
            Name = 'Test Buyer Account',
            IsActive = true
        );
        insert ba;

        BuyerGroup bg = [SELECT Id FROM BuyerGroup WHERE Name = 'Test Buyer Group' LIMIT 1];

        BuyerGroupMember bg_member = new BuyerGroupMember(
            BuyerId = accountId,
            BuyerGroupId = bg.Id
        );
        insert bg_member;

        Buyer_Group_Membership__c bg_membership = new Buyer_Group_Membership__c(
            Membership__c = m.Id,
            Buyer_Group__c = bg.Id,
            Certified__c = true
        );
        insert bg_membership;
    }

    @isTest static void testHandleBuyerGroupsForILMA() {
        Test.StartTest();
        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id; 
        Account_Membership__c am = [SELECT Id, Account_Id__c, Certified__c, Membership__c, Job_Id__c FROM Account_Membership__c WHERE Account_Id__c = :accountId];

        B2BBuyerGroupAssignemntController.handleBuyerGroupsForILMA(am);
        Test.StopTest();
    }

    @isTest static void testHandleBuyerGroupsForAccount() {
        Test.StartTest();
        Account account = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        B2BBuyerGroupAssignemntController.handleBuyerGroupsForAccount(account);
        Test.StopTest();
    }
}