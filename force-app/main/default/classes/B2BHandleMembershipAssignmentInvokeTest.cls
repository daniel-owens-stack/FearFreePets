@IsTest
public class B2BHandleMembershipAssignmentInvokeTest {
   
    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String accountId = B2BTestDataFactory.createAccount();
        String contactId = B2BTestDataFactory.createContact(accountId);
        User user = B2BTestDataFactory.createCommunityUser(contactId);

        Membership__c m = new Membership__c(
            Name = 'Test Membership'
        );
        insert m;
    }

    @isTest static void testHandleCommerceOnMembershipAssignment() {
        Test.StartTest();
        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        String membershipId = [SELECT Id FROM Membership__c WHERE Name = 'Test Membership' LIMIT 1].Id;

        Account_Membership__c am = new Account_Membership__c(
            Membership__c = membershipId,
            Account_Id__c = accountId,
            Parent_Id__c = accountId,
            Purchaser_Account__c = accountId,
            Account_Assignment_Date__c = System.today(),
            Start_Date__c = System.today(),
            Welcome_Kit_Status__c = 'Unavailable',
            Status__c = 'Active'
        );
        insert am;

        List<Account_Membership__c> accountMembershipList = new List<Account_Membership__c>{am};
        List<List<Account_Membership__c>> accountMembershipLists = new List<List<Account_Membership__c>>{accountMembershipList};

        B2BHandleMembershipAssignmentInvokable.handleCommerceOnMembershipAssignment(accountMembershipLists);
        Test.StopTest();
    }

    @isTest static void testHandleCommerceOnMembershipAssignment_null() {
        Test.StartTest();
        List<Account_Membership__c> accountMembershipList = null;
        List<List<Account_Membership__c>> accountMembershipLists = new List<List<Account_Membership__c>>{accountMembershipList};

        B2BHandleMembershipAssignmentInvokable.handleCommerceOnMembershipAssignment(accountMembershipLists);
        Test.StopTest();
    }
}