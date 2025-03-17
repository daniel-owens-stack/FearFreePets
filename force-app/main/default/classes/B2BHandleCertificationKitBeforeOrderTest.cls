@isTest
public class B2BHandleCertificationKitBeforeOrderTest {

    @TestSetup static void makeData(){
        String accountId = B2BTestDataFactory.createAccount();
        String contactId = B2BTestDataFactory.createContact(accountId);
        User user = B2BTestDataFactory.createCommunityUser(contactId);
        String productId = B2BTestDataFactory.createProduct();

        Product2 product = [SELECT Id, Product_Group__c FROM Product2 WHERE Id = :productId];
        product.Product_Group__c = 'Certification Kit';
        update product;

        Membership__c m = new Membership__c(
            Name = 'Test Membership',
            Individual_Certification_Kit__c = productId
        );
        insert m;

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
    }

    @isTest static void testUpdateOrderItems() {
        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];
        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Product1' LIMIT 1].Id;

        Test.StartTest();
        System.runAs(user) {
            String orderId = B2BTestDataFactory.createOrder(accountId, productId);
            B2BHandleCertificationKitBeforeOrder.updateOrderItems(orderId);
        }
        Test.StopTest();
    }

    @isTest static void testUpdateOrderItems_exception() {
        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Product1' LIMIT 1].Id;

        Test.StartTest();
        try {
            B2BTestDataFactory.createOrder(accountId, productId);
        }
        catch(Exception e) {}
        Test.StopTest();
    }
}