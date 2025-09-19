@IsTest
public class B2BPLMAMembershipEndSchedulerTest {

    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String accountId = B2BTestDataFactory.createAccount();

        Membership__c m = new Membership__c(
            Name = 'Test Membership',
            Job_Id__c = 123456
        );
        insert m;

        Practice_Level_Membership_Assignment__c pm = new Practice_Level_Membership_Assignment__c(
            Membership__c = m.Id,
            Business_Account__c = accountId,
            Purchaser__c = accountId,
            Start_Date__c = System.today().addMonths(-12).addDays(-1),
            Welcome_Kit_Status__c = 'Claimed',
            Status__c = 'Active'
        );
        insert pm;
    }
    
    @isTest static void testPLMAMembershipEnd_Expired() {
        Test.startTest();        
        System.schedule('TestB2BPLMAMembershipEndJob', '0 0 12 * * ?', new B2BPLMAMembershipEndScheduler());
        Test.stopTest(); 
    }
}