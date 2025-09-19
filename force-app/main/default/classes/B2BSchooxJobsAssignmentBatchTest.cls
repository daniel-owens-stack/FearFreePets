@isTest
public class B2BSchooxJobsAssignmentBatchTest {

    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String accountId = B2BTestDataFactory.createPersonAccount();
    
        Account account = [SELECT Id, SX_User_Id__pc FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.SX_User_Id__pc = '1918259581';
        update account;
    
        Membership__c m = new Membership__c(
            Name = 'Test Membership',
            Job_Id__c = 123456,
            Active__c = true
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
            Status__c = 'Active',
            Historical_Membership__c = 'Test 12345'
        );
        insert am;
    }

    @isTest static void testBatchSuccess() {
        Test.startTest();
        Database.executeBatch(new B2BSchooxJobsAssignmentBatch(), 1);
        Test.stopTest();
    }

    @isTest static void testBatchWithException() {
        Test.startTest();
        B2BSchooxJobsAssignmentBatch.throwException = true;
        Database.executeBatch(new B2BSchooxJobsAssignmentBatch(), 1);
        Test.stopTest();
    }
}