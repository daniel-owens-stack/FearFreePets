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

    @isTest static void testCreateWebCart () {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];
        Test.StartTest();
        System.runAs(user) {
            B2BUtils.createWebCart();
        }
        Test.StopTest();
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
}