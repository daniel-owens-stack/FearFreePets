@isTest
public class B2BAccountCodeControllerTest {
    
    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String webStoreId  = [SELECT Id FROM WebStore WHERE Name = 'TestWebStore' LIMIT 1].Id;
        String accountId = B2BTestDataFactory.createAccount();
        String contactId = B2BTestDataFactory.createContact(accountId);
        User user = B2BTestDataFactory.createCommunityUser(contactId);
        B2BTestDataFactory.createWebCart(webStoreId, accountId, user.Id);

        Account_Code__c ac = new Account_Code__c(
            Name = 'Test Account Code',
            Code__c = '12345'
        );
        insert ac;
    }

    @isTest static void testUpdateAccountFields() {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Boolean result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BAccountCodeController.updateAccountFields('12345');
        }
        Test.StopTest();
    }

    @isTest static void testUpdateAccountFields_teamAdmin() {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Account businessAccount = new Account(
            Name = 'Test Business Account'
        );
        insert businessAccount;

        Account account = [SELECT Id, Business__c, Admin_Account__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.Business__c = businessAccount.Id;
        account.Admin_Account__c = true;
        update account;

        Boolean result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BAccountCodeController.updateAccountFields('12345');
        }
        Test.StopTest();
    }

    @isTest static void testUpdateAccountFields_noCode() {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Boolean result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BAccountCodeController.updateAccountFields('2345');
        }
        Test.StopTest();
    }

    @isTest static void testUpdateAccountFields_null() {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Boolean result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BAccountCodeController.updateAccountFields(null);
        }
        Test.StopTest();
    }

    @isTest static void testUpdateAccountFields_exception() {

        Boolean result;
        Test.StartTest();
        try {
            result = B2BAccountCodeController.updateAccountFields('12345');
        }
        catch(Exception e) {}
        Test.StopTest();
    }

    @isTest static void testManageAccountCode() {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        B2BAccountCodeController.AccountCodeWrapper result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BAccountCodeController.manageAccountCode();
        }
        Test.StopTest();
    }

    @isTest static void testDeleteActiveCarts() {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Test.StartTest();
        System.runAs(user) {
            B2BAccountCodeController.deleteActiveCarts();
        }
        Test.StopTest();
    }

    @isTest static void testDeleteActiveCarts_exception() {

        Test.StartTest();
        try {
            B2BAccountCodeController.deleteActiveCarts();
        }
        catch(Exception e) {}
        Test.StopTest();
    }
}