@isTest
public class B2BBuyerGroupsAssignmentBatchTest {

    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String accountId = B2BTestDataFactory.createAccount();

        Membership__c m = new Membership__c(
            Name = 'Test Membership',
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

    @isTest static void testBatchExecution() {
        Test.startTest();
        B2BBuyerGroupsAssignmentBatch batch = new B2BBuyerGroupsAssignmentBatch();
        ID batchId = Database.executeBatch(batch, 1);
        Test.stopTest();
    }

    @isTest static void testBatchWithException() {
        Test.startTest();
        try {
            B2BBuyerGroupsAssignmentBatch.throwException = true;
            Database.executeBatch(new B2BBuyerGroupsAssignmentBatch(), 1);
        }
        catch(Exception e) {}
        Test.stopTest();
    }
}