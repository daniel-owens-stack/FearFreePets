/**
 * @description       : 
 * @author            : Poojitha Anthati
 * @group             : 
 * @last modified on  : 09-16-2025
 * @last modified by  : Poojitha Anthati
**/
@isTest
public class B2BUtilsTest {
    
    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String webStoreId  = [SELECT Id FROM WebStore WHERE Name = 'TestWebStore' LIMIT 1].Id;
        String accountId = B2BTestDataFactory.createAccount();
        String contactId = B2BTestDataFactory.createContact(accountId);
        User user = B2BTestDataFactory.createCommunityUser(contactId);
        B2BTestDataFactory.createWebCart(webStoreId, accountId, user.Id);

        String productId = B2BTestDataFactory.createProduct();
        String cartId = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1].Id;
        B2BTestDataFactory.createCartDeliveryGroup(cartId, productId);
    }

    @isTest static void testGetCartDeliveryGroupId () {

        String cartId = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1].Id;

        Test.StartTest();
        B2BUtils.getCartDeliveryGroupId(cartId);
        Test.StopTest();
    }

    @isTest static void testGetUserContactID () {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Test.StartTest();
        System.runAs(user) {
            B2BUtils.getUserContactID();
        }
        Test.StopTest();
    }

    @isTest static void testGetWebStoreBaseURL () {

        Test.StartTest();
        B2BUtils.getWebStoreBaseURL();
        Test.StopTest();
    }

    @isTest static void testGetAccountActiveOrCheckoutWebCart() {

        WebCart cart = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1];
        delete cart;
        
        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];
        
        Test.StartTest();
        System.runAs(user) {
            B2BUtils.getAccountActiveOrCheckoutWebCart();
        }
        Test.StopTest();
    }

    @isTest static void testIsFirstTimeLogin_no () {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Test.StartTest();
        System.runAs(user) {
            B2BUtils.isFirstTimeLogin();
        }
        Test.StopTest();
    }
    @isTest static void testgetFirstTimeLoginProduct () {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Test.StartTest();
        System.runAs(user) {
            B2BUtils.getFirstTimeLoginProduct();
        }
        Test.StopTest();
    }

    @isTest static void testGetProductPriceByAccountId () {

        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Product1' LIMIT 1].Id;
        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Test.StartTest();
        System.runAs(user) {
            try{
                B2BUtils.getProductPriceByAccountId(accountId, productId);
            }
            catch(Exception e) {}
        }
        Test.StopTest();
    }

    @isTest static void testUpdateCart () {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];
        String cartId = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1].Id;

        Test.StartTest();
        System.runAs(user) {
            try{
                B2BUtils.updateCart(cartId);
            }
            catch(Exception e) {}
        }
        Test.StopTest();
    }

    @isTest static void testSendResetPasswordEmail() {
        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];
        List<Id> UserIds = new List<Id>{user.Id};

        Test.StartTest();
        System.runAs(user) {
            try{
                B2BUtils.sendResetPasswordEmail(UserIds);
            }
            catch(Exception e) {}
        }
        Test.StopTest();
    }

    @isTest static void testUpdateTaxIdOnCart () {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];
        String cartId = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1].Id;

        Test.StartTest();
        System.runAs(user) {
            try{
                B2BUtils.updateTaxIdOnCart(cartId, '12345');
            }
            catch(Exception e) {}
        }
        Test.StopTest();
    }
}