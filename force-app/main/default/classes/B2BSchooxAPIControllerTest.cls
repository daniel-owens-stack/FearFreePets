@IsTest
public class B2BSchooxAPIControllerTest {

    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String accountId = B2BTestDataFactory.createAccount();

        Account account = [SELECT Id, SX_User_Id__pc FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.SX_User_Id__pc = '1918259581';
        update account;

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

    @isTest static void testHandleJobAssignmentManual() {
        Test.StartTest();
        String accountId = [SELECT Id, SX_User_Id__pc FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;

        Account_Membership__c am = [SELECT Id, Account_Id__c, Job_Id__c FROM Account_Membership__c WHERE Account_Id__c = :accountId];
        try{
            Test.setMock(HttpCalloutMock.class, new B2BSchooxApiCallMock());
            B2BSchooxAPIController.handleJobAssignmentManual(am.Id);
        }
        catch(Exception e) {}
        Test.StopTest();
    }

    @isTest static void testHandleJobUnassignmentManual() {
        Test.StartTest();
        String accountId = [SELECT Id, SX_User_Id__pc FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;

        Account_Membership__c am = [SELECT Id, Account_Id__c, Job_Id__c FROM Account_Membership__c WHERE Account_Id__c = :accountId];
        try{
            Test.setMock(HttpCalloutMock.class, new B2BSchooxApiCallMock());
            B2BSchooxAPIController.handleJobUnassignmentManual(am.Id);
        }
        catch(Exception e) {}
        Test.StopTest();
    }

    @isTest static void testGetAllJobs() {
        Test.StartTest();
        try{
            Test.setMock(HttpCalloutMock.class, new B2BSchooxApiCallMock());
            B2BSchooxAPIController.getAllJobs();
        }
        catch(Exception e) {}
        Test.StopTest();
    }
}