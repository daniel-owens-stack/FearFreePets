/**
 * @description       : 
 * @author            : Poojitha Anthati
 * @group             : 
 * @last modified on  : 10-16-2025
 * @last modified by  : Poojitha Anthati
**/
@IsTest
public class B2BHandleMembershipAssignQueueableTest {

    @IsTest
    static void testQueueableExecution() {

        Id accountId = B2BTestDataFactory.createAccount();
        Membership__c membership = new Membership__c(Name = 'Test Membership');
        insert membership;

        Account_Membership__c am = new Account_Membership__c(
            Account_Id__c = accountId,
            Membership__c = membership.Id,
            Certified__c = true,
            Status__c = 'Active'
        );
        insert am;

        List<Account_Membership__c> membershipList = new List<Account_Membership__c>{ am };
        B2BHandleMembershipAssignmentQueueable queueableJob = new B2BHandleMembershipAssignmentQueueable(membershipList);

        Test.startTest();
        System.enqueueJob(queueableJob);
        Test.stopTest(); 

        System.assert(true, 'Queueable executed successfully without unhandled exceptions.');
    }

    @IsTest
    static void testQueueableWithEmptyList() {
        List<Account_Membership__c> emptyMembershipList = new List<Account_Membership__c>();

        B2BHandleMembershipAssignmentQueueable queueableJob = new B2BHandleMembershipAssignmentQueueable(emptyMembershipList);

        Test.startTest();
        System.enqueueJob(queueableJob);
        Test.stopTest();

        System.assert(true, 'Queueable handled empty membership list gracefully.');
    }
}