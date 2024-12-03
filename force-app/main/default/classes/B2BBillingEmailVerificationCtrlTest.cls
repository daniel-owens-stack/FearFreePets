@isTest
public class B2BBillingEmailVerificationCtrlTest {
    
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

    @isTest static void testGetAccountDetails() {
        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        B2BBillingEmailVerificationController.AccountWrapper result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BBillingEmailVerificationController.getAccountDetails();
        }
        Test.StopTest();
    }

    @isTest static void testGetAccountDetails_team() {
        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Account businessAccount = new Account(
            Name = 'Test Business Account'
        );
        insert businessAccount;

        Account account = [SELECT Id, Business__c, Admin_Account__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.Business__c = businessAccount.Id;
        account.Admin_Account__c = true;
        update account;

        B2BBillingEmailVerificationController.AccountWrapper result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BBillingEmailVerificationController.getAccountDetails();
        }
        Test.StopTest();
    }

    @isTest static void testUpdateAccount() {
        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        String billingEmail = 'test123@gmail.com';
        Boolean emailVerified = true;

        Test.StartTest();
        System.runAs(user) {
            B2BBillingEmailVerificationController.updateAccount(billingEmail, emailVerified);
        }
        Test.StopTest();
    }

    @isTest static void testUpdateAccount_team() {
        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Account businessAccount = new Account(
            Name = 'Test Business Account'
        );
        insert businessAccount;

        Account account = [SELECT Id, Business__c, Admin_Account__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.Business__c = businessAccount.Id;
        account.Admin_Account__c = true;
        update account;

        String billingEmail = 'test123@gmail.com';
        Boolean emailVerified = true;

        Test.StartTest();
        System.runAs(user) {
            B2BBillingEmailVerificationController.updateAccount(billingEmail, emailVerified);
        }
        Test.StopTest();
    }

    @isTest static void testUpdateAccount_exception() {
        try{
            String billingEmail = 'test123@gmail.com';
            Boolean emailVerified = true;

            Test.StartTest();
            B2BBillingEmailVerificationController.updateAccount(billingEmail, emailVerified);
            Test.StopTest();
        }
        catch(Exception e) {}
    }

    @isTest static void testGenerateVerificationCode() {

        Integer result;
        Test.StartTest();
        result = B2BBillingEmailVerificationController.generateVerificationCode();
        Test.StopTest();
    }

    @isTest static void testVerifyCode() {

        String email = 'test123@gmail.com';
        String code = '12345';

        B2BBillingEmailVerificationController.FlowInputs flowInput = new B2BBillingEmailVerificationController.FlowInputs();
        flowInput.email = email;
        flowInput.code = code;
        List<B2BBillingEmailVerificationController.FlowInputs> flowInputs = new List<B2BBillingEmailVerificationController.FlowInputs>{flowInput};

        Boolean result;
        Test.StartTest();
        B2BBillingEmailVerificationController.saveVerificationCode(flowInputs);
        result = B2BBillingEmailVerificationController.verifyCode(email, code);
        Test.StopTest();
    }

    @isTest static void testVerifyCode_exception() {
        try{
            String email = 'test123@gmail.com';
            String code = '12345';

            Boolean result;
            Test.StartTest();
            result = B2BBillingEmailVerificationController.verifyCode(email, code);
            Test.StopTest();
        }
        catch(Exception e) {}
    }

    @isTest static void testSaveVerificationCodee_exception() {
        try{
            Test.StartTest();
             B2BBillingEmailVerificationController.saveVerificationCode(null);
            Test.StopTest();
        }
        catch(Exception e) {}
    }
}