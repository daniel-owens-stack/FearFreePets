@isTest
private class B2BBuyerGroupsAssignmentBatchTest {

    @isTest
    static void testBatchExecutionSingleRun() {
        Account acc = new Account();
        acc.LastName = 'Test Account';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        acc.Historical_Jobs_Assigned__c = 'Succesful';
        insert acc;

        Test.startTest();
        Database.executeBatch(new B2BBuyerGroupsAssignmentBatch(), 1);
        Test.stopTest();
    }

    @isTest
    static void testBatchExecutionMultipleAccounts() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            Account acc = new Account();
            acc.LastName = 'Test ' + i;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
            acc.Historical_Jobs_Assigned__c = 'Succesful';
            accounts.add(acc);
        }
        insert accounts;

        Test.startTest();
        Database.executeBatch(new B2BBuyerGroupsAssignmentBatch(), 200);
        Test.stopTest();
    }
}