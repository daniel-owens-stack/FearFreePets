@isTest
public class B2BChargeCustomerInvoiceSchedulerTest {

    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String webStoreId  = [SELECT Id FROM WebStore WHERE Name = 'TestWebStore' LIMIT 1].Id;
        String accountId = B2BTestDataFactory.createAccount();
        String contactId = B2BTestDataFactory.createContact(accountId);
        User user = B2BTestDataFactory.createCommunityUser(contactId);
        String productId = B2BTestDataFactory.createProduct();
        String orderId =  B2BTestDataFactory.createOrder(accountId, productId);

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

        Invoice__c invoice = new Invoice__c(
            Due_Date__c = System.today(),
            Status__c = 'Active',
            Stripe_Invoice_Id__c = 'test_123',
            Account_Id__c = accountId,
            Amount_Charged__c = 100,
            Name = 'IN-Test001'
        );
        insert invoice;

        Order order = [SELECT Id, InvoiceId__c FROM Order WHERE Id =:orderId LIMIT 1];
        order.InvoiceId__c = 'test_123';
        update order;
    }

    public static String CRON_EXP = '0 48 * * * ?';
    
    @isTest static void testExecute() {
        Test.StartTest();
        System.schedule('B2BChargeCustomerInvoiceSchedulerTest', CRON_EXP, new B2BChargeCustomerInvoiceScheduler());
        Test.StopTest();
    }

    @isTest static void testExecute_withCanceledMemberships() {

        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        String membershipId = [SELECT Id FROM Membership__c WHERE Name = 'Test Membership' LIMIT 1].Id;

        Account_Membership__c am = new Account_Membership__c(
            Membership__c = membershipId,
            Account_Id__c = accountId,
            Parent_Id__c = accountId,
            Account_Assignment_Date__c = Date.valueOf('2024-09-01'),
            Start_Date__c = Date.valueOf('2024-09-01'),
            Welcome_Kit_Status__c = 'Unclaimed',
            Status__c = 'Canceled'
        );
        insert am;

        Practice_Level_Membership_Assignment__c pm = new Practice_Level_Membership_Assignment__c(
            Start_Date__c = Date.valueOf('2024-09-01'),
            Welcome_Kit_Status__c = 'Unclaimed',
            Membership__c = membershipId,
            Business_Account__c = accountId,
            Status__c = 'Canceled'
        );
        insert pm;

        Test.StartTest();
        System.schedule('B2BChargeCustomerInvoiceSchedulerTest', CRON_EXP, new B2BChargeCustomerInvoiceScheduler());
        Test.StopTest();
    }

    @isTest static void testGetInvoice() {
        String invoiceId = [SELECT Id FROM Invoice__c WHERE Name = 'IN-Test001' LIMIT 1].Id;
        Test.StartTest();
        B2BChargeCustomerInvoice.getInvoice(invoiceId);
        Test.StopTest();
    }
}