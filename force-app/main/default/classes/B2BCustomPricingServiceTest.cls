@IsTest
public class B2BCustomPricingServiceTest {

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

        Membership__c m = new Membership__c(
            Name = 'Test Membership',
            Renewal_Amount__c = 333
        );
        insert m;

        Product2 product = [SELECT Id, Membership__c FROM Product2 WHERE Name = 'Test Product1' LIMIT 1];
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

        CartItem ci = [SELECT Id, Individual_Membership_Assignment__c, Type FROM CartItem WHERE Product2Id = :productId LIMIT 1];
        ci.Individual_Membership_Assignment__c = am.Id;
        ci.Type = 'Product';
        update ci;
    }
    
    @isTest static void testProcessTransactionalPrice() {

        String cartId = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1].Id;
        B2BCustomPricingService.testCartId = cartId;

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        // Create a TransactionalPricingRequest object
        commercestorepricing.TransactionalPricingRequest request = new commercestorepricing.TransactionalPricingRequest();

        commercestorepricing.TransactionalPricingResponse response;
        Test.startTest();
        System.runAs(user){
            try{
                // Call pricing method
                B2BCustomPricingService pricingService = new B2BCustomPricingService();
                response = pricingService.processTransactionalPrice(request);
            }
            catch(Exception e) {
                System.debug('##Exception: '+ e.getMessage());
            }
        }
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
    }
}