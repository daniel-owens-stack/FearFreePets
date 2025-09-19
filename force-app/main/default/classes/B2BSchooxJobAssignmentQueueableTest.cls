@isTest
public class B2BSchooxJobAssignmentQueueableTest {

    @isTest
    static void testQueueableExecution() {
        B2BTestDataFactory.createWebStore();
        String accountId = B2BTestDataFactory.createPersonAccount();

        Account acc = [SELECT Id FROM Account WHERE Id = :accountId];
        acc.SX_User_Id__pc = '1234567890';
        update acc;

        Test.setMock(HttpCalloutMock.class, new B2BSchooxApiCallMock());

        List<Integer> jobIds = new List<Integer>{1234, 5678};

        Test.startTest();
        System.enqueueJob(new B2BSchooxJobAssignmentQueueable(accountId, jobIds));
        Test.stopTest();
    }
}