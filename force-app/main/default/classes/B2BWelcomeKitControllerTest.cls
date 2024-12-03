@isTest
public class B2BWelcomeKitControllerTest {
    
    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String webStoreId  = [SELECT Id FROM WebStore WHERE Name = 'TestWebStore' LIMIT 1].Id;
        String accountId = B2BTestDataFactory.createAccount();
        String contactId = B2BTestDataFactory.createContact(accountId);
        User user = B2BTestDataFactory.createCommunityUser(contactId);
        B2BTestDataFactory.createWebCart(webStoreId, accountId, user.Id);
        String productId = B2BTestDataFactory.createSetProduct();

        Account businessAccount = new Account(
            Name = 'Test Business Account'
        );
        insert businessAccount;

        Membership__c m = new Membership__c(
            Name = 'Test Membership',
            Welcome_Kit_Parent__c = productId
        );
        insert m;

        Product2 product = [SELECT Id, Membership__c FROM Product2 WHERE Name = 'Test Set Product' LIMIT 1];
        product.Membership__c = m.Id;
        update product;

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

    @isTest static void testGetUnclaimedKits() {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        List<B2BWelcomeKitController.WelcomeKitWrapper> result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BWelcomeKitController.getUnclaimedKits();
        }
        Test.StopTest();
    }

    @isTest static void testGetUnclaimedKits_null() {

        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Set Product' LIMIT 1].Id;
        String cartId = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1].Id;
        B2BTestDataFactory.createCartDeliveryGroup(cartId, productId);

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        List<B2BWelcomeKitController.WelcomeKitWrapper> result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BWelcomeKitController.getUnclaimedKits();
        }
        Test.StopTest();
    }

    @isTest static void testGetUnclaimedKits_noCart() {

        WebCart cart = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1];
        delete cart;

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        List<B2BWelcomeKitController.WelcomeKitWrapper> result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BWelcomeKitController.getUnclaimedKits();
        }
        Test.StopTest();
    }

    @isTest static void testGetShippingAddress() {

        Account businessAccount = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];

        Account account = [SELECT Id, Business__c, Business_Shipping_Address__Street__s, Business_Shipping_Address__City__s, Business_Shipping_Address__StateCode__s, Business_Shipping_Address__PostalCode__s, Business_Shipping_Address__CountryCode__s
                           FROM Account 
                           WHERE Name = 'Test Account' LIMIT 1];
        account.Business__c = businessAccount.Id;
        account.Business_Shipping_Address__Street__s = '2000 Auburn Street';
        account.Business_Shipping_Address__City__s = 'Beachwood';
        account.Business_Shipping_Address__StateCode__s = 'OH';
        account.Business_Shipping_Address__PostalCode__s = '44122';
        account.Business_Shipping_Address__CountryCode__s = 'US';
        update account;

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        B2BWelcomeKitController.AddressWrapper result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BWelcomeKitController.getShippingAddress();
        }
        Test.StopTest();
    }

    @isTest static void testGetShippingAddress_null() {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        B2BWelcomeKitController.AddressWrapper result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BWelcomeKitController.getShippingAddress();
        }
        Test.StopTest();
    }

    @isTest static void testAddWelcomeKitToCart() {

        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Set Product' LIMIT 1].Id;
        String cartId = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1].Id;
        B2BTestDataFactory.createCartDeliveryGroup(cartId, productId);

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Test.StartTest();
        System.runAs(user) {
            B2BWelcomeKitController.addWelcomeKitToCart(productId);
        }
        Test.StopTest();
    }

    @isTest static void testSaveShippingAddress() {

        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Set Product' LIMIT 1].Id;
        Account businessAccount = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];

        Account account = [SELECT Id, Business__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.Business__c = businessAccount.Id;
        update account;

        B2BWelcomeKitController.AddressWrapper address = new B2BWelcomeKitController.AddressWrapper();
        address.street = '2000 Auburn Dr';
        address.city = 'Beachwood';
        address.state = 'OH';
        address.postalCode = '44122';
        address.country = 'US';

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Test.StartTest();
        System.runAs(user) {
            B2BWelcomeKitController.saveShippingAddress(address);
        }
        Test.StopTest();
    }

    @isTest static void testGetUnclaimedPracticeLevelKits() {

        Account businessAccount = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];

        Account account = [SELECT Id, Business__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.Business__c = businessAccount.Id;
        update account;

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        List<Practice_Level_Membership_Assignment__c> result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BWelcomeKitController.getUnclaimedPracticeLevelKits();
        }
        Test.StopTest();
    }

    @isTest static void testGetUnclaimedPracticeLevelKits_null() {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        List<Practice_Level_Membership_Assignment__c> result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BWelcomeKitController.getUnclaimedPracticeLevelKits();
        }
        Test.StopTest();
    }

    @isTest static void testCreateOrderSummary() {

        Account businessAccount = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];

        Account account = [SELECT Id, Business__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.Business__c = businessAccount.Id;
        update account;

        String membershipId = [SELECT Id FROM Membership__c WHERE Name = 'Test Membership' LIMIT 1].Id;
        List<String> membershipIds = new List<String>();
        membershipIds.add(membershipId);

        B2BWelcomeKitController.AddressWrapper address = new B2BWelcomeKitController.AddressWrapper();
        address.street = '2000 Auburn Dr';
        address.city = 'Beachwood';
        address.state = 'OH';
        address.postalCode = '44122';
        address.country = 'US';

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Boolean result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BWelcomeKitController.createOrderSummary(membershipIds, address);
        }
        Test.StopTest();
    }

    @isTest static void testCreateOrderSummary_withShippingProd() {
        B2BTestDataFactory.createShippingProduct();

        Account businessAccount = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];

        Account account = [SELECT Id, Business__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.Business__c = businessAccount.Id;
        update account;

        String membershipId = [SELECT Id FROM Membership__c WHERE Name = 'Test Membership' LIMIT 1].Id;
        List<String> membershipIds = new List<String>();
        membershipIds.add(membershipId);

        B2BWelcomeKitController.AddressWrapper address = new B2BWelcomeKitController.AddressWrapper();
        address.street = '2000 Auburn Dr';
        address.city = 'Beachwood';
        address.state = 'OH';
        address.postalCode = '44122';
        address.country = 'US';

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Boolean result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BWelcomeKitController.createOrderSummary(membershipIds, address);
        }
        Test.StopTest();
    }

    @isTest static void testCreateOrderSummary_withODM() {
        B2BTestDataFactory.createShippingProduct();
        String productId = [SELECT Id FROM Product2 WHERE Name = 'Delivery Charge' LIMIT 1].Id;
        B2BTestDataFactory.createOrderDeliveryMethod(productId);

        Account businessAccount = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];

        Account account = [SELECT Id, Business__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.Business__c = businessAccount.Id;
        update account;

        String membershipId = [SELECT Id FROM Membership__c WHERE Name = 'Test Membership' LIMIT 1].Id;
        List<String> membershipIds = new List<String>();
        membershipIds.add(membershipId);

        B2BWelcomeKitController.AddressWrapper address = new B2BWelcomeKitController.AddressWrapper();
        address.street = '2000 Auburn Dr';
        address.city = 'Beachwood';
        address.state = 'OH';
        address.postalCode = '44122';
        address.country = 'US';

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Boolean result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BWelcomeKitController.createOrderSummary(membershipIds, address);
        }
        Test.StopTest();
    }

    @isTest static void testUpdatePracticeCertificationKitStatus() {

        Account businessAccount = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];
        Id productId = [SELECT Id FROM Product2 WHERE Name = 'Test Set Product' LIMIT 1].Id;
        List<Id> productIds = new List<Id>();
        productIds.add(productId);

        Test.StartTest();
        B2BWelcomeKitController.updatePracticeCertificationKitStatus(businessAccount.Id, productIds, null);
        Test.StopTest();
    }
}