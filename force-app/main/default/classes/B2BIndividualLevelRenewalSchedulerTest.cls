@isTest
public class B2BIndividualLevelRenewalSchedulerTest {
    
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

        Account_Membership__c am = new Account_Membership__c(
            Membership__c = m.Id,
            Account_Id__c = accountId,
            Parent_Id__c = accountId,
            Account_Assignment_Date__c = System.today().addMonths(-12),
            Start_Date__c = System.today().addMonths(-12),
            Welcome_Kit_Status__c = 'Unclaimed',
            Status__c = 'Active'
        );
        insert am;
    }

    public static String CRON_EXP = '0 48 * * * ?';

    @isTest static void testExecute() {
        Account account = [
            SELECT Id, Billing_Email__c, Billing_Email_Verified__c, Payment_Terms__c, IndividualLevelRenewalDate__c 
            FROM Account
            WHERE Name = 'Test Account' LIMIT 1];
            
        Date today = Date.today();
        account.Billing_Email__c = 'test@stack.com';
        account.Billing_Email_Verified__c = true;
        account.Payment_Terms__c = 'Credit Card Only';
        account.IndividualLevelRenewalDate__c = today;

        update account;

        B2BTestDataFactory.createShippingProduct();
        String productId = [SELECT Id FROM Product2 WHERE Name = 'Delivery Charge' LIMIT 1].Id;
        B2BTestDataFactory.createOrderDeliveryMethod(productId);

        Test.StartTest();
        System.schedule('B2BIndividualLevelRenewalSchedulerTest', CRON_EXP, new B2BIndividualLevelRenewalScheduler());
        Test.StopTest();
    }

    @isTest static void testExecute_null() {
        Account account = [
            SELECT Id, IndividualLevelRenewalDate__c 
            FROM Account
            WHERE Name = 'Test Account' LIMIT 1];
            
        Date today = Date.today();
        account.IndividualLevelRenewalDate__c = today.addDays(5);

        update account;

        Test.StartTest();
        System.schedule('B2BIndividualLevelRenewalSchedulerTest', CRON_EXP, new B2BIndividualLevelRenewalScheduler());
        Test.StopTest();
    }

    @isTest static void testExecute_withOrder() {
        Account account = [
            SELECT Id, Billing_Email__c, Billing_Email_Verified__c, Payment_Terms__c, IndividualLevelRenewalDate__c 
            FROM Account
            WHERE Name = 'Test Account' LIMIT 1];
            
        Date today = Date.today();
        account.Billing_Email__c = 'test@stack.com';
        account.Billing_Email_Verified__c = true;
        account.Payment_Terms__c = 'Credit Card Only';
        account.IndividualLevelRenewalDate__c = today;

        update account;

        B2BTestDataFactory.createShippingProduct();
        String shippingProductId = [SELECT Id FROM Product2 WHERE Name = 'Delivery Charge' LIMIT 1].Id;
        B2BTestDataFactory.createOrderDeliveryMethod(shippingProductId);

        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Product1' LIMIT 1].Id;
        Id orderId = B2BTestDataFactory.createOrder(account.Id, productId);
        Order existingOrder= [SELECT IsRenewal__c FROM Order WHERE Id = :orderId LIMIT 1];
        existingOrder.IsRenewal__c = true;
        update existingOrder;

        Test.StartTest();
        System.schedule('B2BIndividualLevelRenewalSchedulerTest', CRON_EXP, new B2BIndividualLevelRenewalScheduler());
        Test.StopTest();
    }
}