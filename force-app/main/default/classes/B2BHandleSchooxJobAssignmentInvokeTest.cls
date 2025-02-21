@IsTest
public class B2BHandleSchooxJobAssignmentInvokeTest {
    
    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String accountId = B2BTestDataFactory.createAccount();

        Membership__c m = new Membership__c(
            Name = 'Test Membership',
            Job_Id__c = 123456
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
    }

    @isTest static void testHandleSchooxJobAssignment() {
        Test.StartTest();
        Account account = [SELECT Id, SX_User_Id__pc FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.SX_User_Id__pc = '1918259581';
        update account;

        B2BSchooxAccountJobWrapper accountJobWrapper = new B2BSchooxAccountJobWrapper();

        Account_Membership__c am = [SELECT Id, Account_Id__c, Job_Id__c FROM Account_Membership__c WHERE Account_Id__c = :account.Id];
        List<Account_Membership__c> accountMemberships = new List<Account_Membership__c>{am};
        accountJobWrapper.accountMemberships = accountMemberships;

        accountJobWrapper.orderSummary_AccountId = account.Id;

        List<Integer> permanentMembershipJobIds = new List<Integer>{987654};
        accountJobWrapper.permanentMembershipJobIds = permanentMembershipJobIds;

        List<B2BSchooxAccountJobWrapper> accountJobWrapperLists = new List<B2BSchooxAccountJobWrapper>{accountJobWrapper};
        try{
            Test.setMock(HttpCalloutMock.class, new B2BSchooxApiCallMock());
            B2BHandleSchooxJobAssignmentInvokable.handleSchooxJobAssignment(accountJobWrapperLists);
        }
        catch(Exception e) {}
        Test.StopTest();
    }
}