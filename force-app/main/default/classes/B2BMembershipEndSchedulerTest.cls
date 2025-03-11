@IsTest
public class B2BMembershipEndSchedulerTest {

    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String accountId = B2BTestDataFactory.createAccount();

        Membership__c m = new Membership__c(
            Name = 'Test Membership',
            Job_Id__c = 123456
        );
        insert m;

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
            Certified__c = false,
            Role__c = 'Non Admin'
        );
        insert bg_membership;
    }
    
    @isTest static void testMembershipEnd_Expired() {
        Test.startTest();

        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        String membershipId = [SELECT Id FROM Membership__c WHERE Name = 'Test Membership' LIMIT 1].Id;

        Account_Membership__c am = new Account_Membership__c(
            Membership__c = membershipId,
            Account_Id__c = accountId,
            Parent_Id__c = accountId,
            Purchaser_Account__c = accountId,
            Account_Assignment_Date__c = System.today().addMonths(-12).addDays(-1),
            Welcome_Kit_Status__c = 'Claimed',
            Status__c = 'Complete'
        );
        insert am;

        System.schedule('TestB2BMembershipEndJob', '0 0 12 * * ?', new B2BMembershipEndScheduler());
        Test.stopTest(); 
    }

    @isTest static void testGetBuyerGroupMemberships_null() {

        String membershipId = [SELECT Id FROM Membership__c WHERE Name = 'Test Membership' LIMIT 1].Id;

        Test.StartTest();

        Buyer_Group_Membership__c bgm = [SELECT Id FROM Buyer_Group_Membership__c WHERE Membership__c = :membershipId];
        delete bgm;

        B2BMembershipEndHelper.getBuyerGroupMemberships(membershipId, false, false);
        Test.StopTest();
    }

    @isTest static void testGetActiveILMAofSameType() {
        
        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        String membershipId = [SELECT Id FROM Membership__c WHERE Name = 'Test Membership' LIMIT 1].Id;

        Account_Membership__c am = new Account_Membership__c(
            Membership__c = membershipId,
            Account_Id__c = accountId,
            Parent_Id__c = accountId,
            Purchaser_Account__c = accountId,
            Account_Assignment_Date__c = System.today().addMonths(-12).addDays(-1),
            Welcome_Kit_Status__c = 'Claimed',
            Status__c = 'Active'
        );
        insert am;

        Test.StartTest();
        B2BMembershipEndHelper.getActiveILMAofSameType(accountId, membershipId);
        Test.StopTest();
    }
}