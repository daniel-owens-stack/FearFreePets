@isTest
private class B2BProvisioningBatchTest {

    @isTest
    static void runBatch_withFactoryPersonAccounts() {
        Id personAccId = B2BTestDataFactory.createPersonAccount();

        Contact con = [SELECT Id FROM Contact WHERE AccountId = :personAccId LIMIT 1];
        Account acc = [SELECT Id, PersonEmail FROM Account WHERE Id = :personAccId];

        acc.PersonEmail = 'provision-' + System.currentTimeMillis() + '@test.com';
        acc.Provisioned_to_B2B_Store__c = 'Pending';
        acc.Original_System_ID__c = 'Test123';
        update acc;

        Test.startTest();
        Database.executeBatch(new B2BProvisioningBatch(), 200);
        Test.stopTest();
    }

    @isTest
    static void runBatch_withFactoryPersonAccounts_unsuccessfull() {
        Id personAccId = B2BTestDataFactory.createPersonAccount();

        Contact con = [SELECT Id FROM Contact WHERE AccountId = :personAccId LIMIT 1];
        Account acc = [SELECT Id, PersonEmail FROM Account WHERE Id = :personAccId];

        acc.Provisioned_to_B2B_Store__c = 'Pending';
        acc.Original_System_ID__c = 'Test12345';
        update acc;

        Test.startTest();
        Database.executeBatch(new B2BProvisioningBatch(), 200);
        Test.stopTest();
    }
}