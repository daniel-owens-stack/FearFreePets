@isTest
public class B2BSchooxJobsAssignmentBatchTest {

//    @isTest
// static void test_SuccessfulAssignment() {
//     String accId = B2BTestDataFactory.createPersonAccount();
//     Account acc = [SELECT Id FROM Account WHERE Id = :accId];
//     acc.Historical_Jobs_Assigned__c = 'Pending';
//     update acc;

//     Membership__c membership = new Membership__c(Name = 'Membership Success', Job_Id__c = 1001, Active__c = true);
//     insert membership;

//     Account_Membership__c am = new Account_Membership__c(
//         Membership__c = membership.Id,
//         Account_Id__c = acc.Id,
//         Parent_Id__c = acc.Id,
//         Purchaser_Account__c = acc.Id,
//         Account_Assignment_Date__c = System.today(),
//         Start_Date__c = System.today(),
//         Welcome_Kit_Status__c = 'Unavailable',
//         Status__c = 'Active',
//         Historical_Membership__c = 'Success'
//     );
//     insert am;

//     // 🛡️ Set your callout mock before the batch runs
//     Test.setMock(HttpCalloutMock.class, new B2BSchooxApiCallMock());

//     Test.startTest();
//     Database.executeBatch(new B2BSchooxJobsAssignmentBatch(), 1); // use 1 so only 1 job enqueued
//     Test.stopTest();
// }


    @isTest static void test_NoMemberships() {
        String accId = B2BTestDataFactory.createPersonAccount();
        Account acc = [SELECT Id FROM Account WHERE Id = :accId];
        acc.Historical_Jobs_Assigned__c = 'Pending';
        update acc;

        Test.startTest();
        Database.executeBatch(new B2BSchooxJobsAssignmentBatch(), 1);
        Test.stopTest();
    }

    @isTest static void test_InactiveMembership() {
        String accId = B2BTestDataFactory.createPersonAccount();
        Account acc = [SELECT Id FROM Account WHERE Id = :accId];
        acc.Historical_Jobs_Assigned__c = 'Pending';
        update acc;

        Membership__c membership = new Membership__c(Name = 'Inactive Membership', Job_Id__c = 9999, Active__c = false);
        insert membership;

        Account_Membership__c am = new Account_Membership__c(
            Membership__c = membership.Id,
            Account_Id__c = acc.Id,
            Parent_Id__c = acc.Id,
            Purchaser_Account__c = acc.Id,
            Account_Assignment_Date__c = System.today(),
            Start_Date__c = System.today(),
            Welcome_Kit_Status__c = 'Unavailable',
            Status__c = 'Active',
            Historical_Membership__c = 'InactiveTest'
        );
        insert am;

        Test.startTest();
        Database.executeBatch(new B2BSchooxJobsAssignmentBatch(), 1);
        Test.stopTest();
    }

    @isTest static void test_StatusAlreadySet() {
        String accId = B2BTestDataFactory.createPersonAccount();
        Account acc = [SELECT Id FROM Account WHERE Id = :accId];
        acc.Historical_Jobs_Assigned__c = 'Succesful';
        update acc;

        Test.startTest();
        Database.executeBatch(new B2BSchooxJobsAssignmentBatch(), 1);
        Test.stopTest();
    }
}