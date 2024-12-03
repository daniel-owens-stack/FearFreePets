@isTest
public class B2BCustomAddToCartControllerTest {
    
    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String webStoreId  = [SELECT Id FROM WebStore WHERE Name = 'TestWebStore' LIMIT 1].Id;
        String accountId = B2BTestDataFactory.createAccount();
        String contactId = B2BTestDataFactory.createContact(accountId);
        User user = B2BTestDataFactory.createCommunityUser(contactId);
        B2BTestDataFactory.createWebCart(webStoreId, accountId, user.Id);
        B2BTestDataFactory.createProduct();

        Membership__c m = new Membership__c(
            Name = 'Test Membership'
        );
        insert m;

        Product2 product = [SELECT Id, Membership__c FROM Product2 WHERE Name = 'Test Product1' LIMIT 1];
        product.Membership__c = m.Id;
        update product;

        Account businessAccount = new Account(
            Name = 'Test Business Account'
        );
        insert businessAccount;

        Account account = [SELECT Id, Business__c FROM Account WHERE Id = :accountId LIMIT 1];
        account.Business__c = businessAccount.Id;
        update account;


        Account_Membership__c am = new Account_Membership__c(
            Membership__c = m.Id,
            Account_Id__c = accountId,
            Parent_Id__c = accountId,
            Account_Assignment_Date__c = Date.valueOf('2024-09-01'),
            Start_Date__c = Date.valueOf('2024-09-01'),
            Welcome_Kit_Status__c = 'Unclaimed',
            Status__c = 'Active'
        );
        insert am;

        Practice_Level_Membership_Assignment__c pm = new Practice_Level_Membership_Assignment__c(
            Start_Date__c = Date.valueOf('2024-09-01'),
            Welcome_Kit_Status__c = 'Unclaimed',
            Membership__c = m.Id,
            Business_Account__c = businessAccount.Id,
            Status__c = 'Active'
        );
        insert pm;

    }

    @isTest static void testIsVariantProduct () {

        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Product1' LIMIT 1].Id;

        Boolean result;
        Test.StartTest();
        result = B2BCustomAddToCartController.isVariantProduct(productId);
        Test.StopTest();
    }

    @isTest static void testGetProductGroup () {

        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Product1' LIMIT 1].Id;
        String result;
        Test.StartTest();
        result = B2BCustomAddToCartController.getProductGroup(productId);
        Test.StopTest();
    }

    @isTest static void testGetProductGroup_null () {

        String productId = null;
        String result;
        Test.StartTest();
        result = B2BCustomAddToCartController.getProductGroup(productId);
        Test.StopTest();
    }

    @isTest static void testIsAdminAccount () {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];
        Test.StartTest();
        Boolean result;
        System.runAs(user) {
            result = B2BCustomAddToCartController.isAdminAccount();
        }
        Test.StopTest();
    }

    @isTest static void testGetIndividualLevelMemberships () {

        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Product1' LIMIT 1].Id;
        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Test.StartTest();
        List<Account_Membership__c> result;
        System.runAs(user) {
            result = B2BCustomAddToCartController.getIndividualLevelMemberships(productId);
        }
        Test.StopTest();
    }

    @isTest static void testGetPracticeLevelMemberships () {

        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Product1' LIMIT 1].Id;
        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Test.StartTest();
        List<Practice_Level_Membership_Assignment__c> result;
        System.runAs(user) {
            result = B2BCustomAddToCartController.getPracticeLevelMemberships(productId);
        }
        Test.StopTest();
    }

    @isTest static void testIsProductPresentInCart () {

        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Product1' LIMIT 1].Id;
        String cartId = [SELECT Id FROM WebCart WHERE  Name = 'Test Cart' LIMIT 1].Id;
        B2BTestDataFactory.createCartDeliveryGroup(cartId, productId);

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Test.StartTest();
        Boolean result;
        System.runAs(user) {
            result = B2BCustomAddToCartController.isProductPresentInCart(productId);
        }
        Test.StopTest();
    }

    @isTest static void testIsProductPresentInCart_null () {

        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Product1' LIMIT 1].Id;
        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Test.StartTest();
        Boolean result;
        System.runAs(user) {
            result = B2BCustomAddToCartController.isProductPresentInCart(productId);
        }
        Test.StopTest();
    }
}