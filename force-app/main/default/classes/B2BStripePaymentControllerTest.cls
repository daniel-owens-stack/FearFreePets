@IsTest
public class B2BStripePaymentControllerTest {

    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String accountId = B2BTestDataFactory.createPersonAccount();

        String webStoreId  = [SELECT Id FROM WebStore WHERE Name = 'TestWebStore' LIMIT 1].Id;
        B2BTestDataFactory.createWebCart(webStoreId, accountId, null);

        String productId = B2BTestDataFactory.createProduct();

        String cartId = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1].Id;
        B2BTestDataFactory.createCartDeliveryGroup(cartId, productId);

        Product2 product = [SELECT Id, Name, Stripe_Product_Id__c FROM Product2 WHERE Id =: productId LIMIT 1];
        product.Stripe_Product_Id__c = 'prod_123456789';
        update product;

        CartItem ci = [SELECT Id, Type, SalesPrice FROM CartItem WHERE Name = :product.Name LIMIT 1];
        ci.Type = 'Product';
        ci.SalesPrice = 10;
        update ci;

        Account account = [SELECT Id, PersonEmail, Invoice_Billing_Email__c  FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.PersonEmail = 'customer@test.com';
        account.Invoice_Billing_Email__c = 'customer@test.com';
        update account;
    }
    
    @isTest static void testGetCustomerId_paynow() {

        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        String paymentOption = 'paynow';

        Test.StartTest();

        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('stripeCustomerGet', 200, true));

        B2BStripePaymentController.getCustomerId(accountId, paymentOption);
        Test.StopTest();
    }

    @isTest static void testGetCustomerId_paynow_null() {

        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        String paymentOption = 'paynow';

        Test.StartTest();

        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('stripeCustomerGet', 200, false));
        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('stripeCustomer', 200, true));
        try{
            B2BStripePaymentController.getCustomerId(accountId, paymentOption);
        }
        catch(Exception e) {}
        Test.StopTest();
    }

    @isTest static void testGetCustomerId_invoice() {

        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        String paymentOption = 'invoice';

        Test.StartTest();

        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('stripeCustomerGet', 200, true));

        B2BStripePaymentController.getCustomerId(accountId, paymentOption);
        Test.StopTest();
    }

    @isTest static void testGetCustomerId_invoice_null() {

        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        String paymentOption = 'invoice';

        Test.StartTest();

        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('stripeCustomerGet', 400, true));
        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('stripeCustomer', 200, true));

        try {
            B2BStripePaymentController.getCustomerId(accountId, paymentOption);
        }
        catch(Exception e) {}
        Test.StopTest();
    }

    @isTest static void testCanInvoice() {

        Account account = [SELECT Id, Payment_Terms__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.Payment_Terms__c = 'Credit Card Only';
        update account;

        Test.StartTest();
        B2BStripePaymentController.canInvoice(account.Id);
        Test.StopTest();
    }

    @isTest static void testCanInvoice_true() {

        Account account = [SELECT Id, Payment_Terms__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.Payment_Terms__c = 'Net 30';
        update account;

        Test.StartTest();
        B2BStripePaymentController.canInvoice(account.Id);
        Test.StopTest();
    }

    @isTest static void testCreateInvoice() {

        Account account = [SELECT Id, Invoice_Billing_Email__c, Invoice_Stripe_Id__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.Invoice_Billing_Email__c = 'customer@test.com';
        account.Invoice_Stripe_Id__c = 'cus01234567890';
        update account;

        Id webCartId = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1].Id;
        String customerId = 'cus01234567890';

        Test.StartTest();

        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('invoice', 200, true));
        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('invoiceItem', 200, true));

        try {
            B2BStripePaymentController.createInvoice(webCartId, customerId, account.Id);
        }
        catch(Exception e){
            System.debug('Exception in testCreateInvoice: ' + e.getMessage());
        }
        Test.StopTest();
    }

    @isTest static void testProcessPayments() {

        Id webCartId = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1].Id;
        String customerId = 'cus01234567890';
        String href = 'https://fearfree.my.site.com/PayNow/';

        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('checkoutSession', 200, true));
        B2BStripePaymentController.processPayments(webCartId, customerId, href);
        Test.StopTest();
    }
    
    @isTest static void testValidateSession() {

        String sessionId = 'ses01234567890';
        Id webCartId = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1].Id;

        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('checkoutSession', 200, true));
        B2BStripePaymentController.validateSession(sessionId, webCartId);
        Test.StopTest();
    }

    @isTest static void testConvertCartToOrder() {

        Id webCartId = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1].Id;
        String paymentIntent = 'pi_13451Sre2OxY3Au2';

        CartCheckoutSession session = new CartCheckoutSession(
            WebCartId = webCartId,
            State = 'Start',
            IsArchived = false,
            Name = 'Test'
        );
        insert session;

        Test.StartTest();

        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('paymentIntent', 200, true));

        try {
            B2BStripePaymentController.convertCartToOrder(webCartId, paymentIntent, null);
        }
        catch(Exception e){
            System.debug('Exception in testCreateInvoice: ' + e.getMessage());
        }
        Test.StopTest();
    }

    @isTest static void testCreatePaymentIntent() {

        String paymentMethod = 'pi_13451Sre2OxY3Au2';
        String customerId = 'cus01234567890';

        Test.StartTest();

        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('paymentIntent', 200, true));

        try {
            B2BStripeService.createPaymentIntent(customerId, paymentMethod, 12);
        }
        catch(Exception e){
            System.debug('Exception in testCreateInvoice: ' + e.getMessage());
        }
        Test.StopTest();
    }

    @isTest static void testCreateCoupon() {

        Integer discountedAmount = 10;
        String currencyCode = 'usd';

        Test.StartTest();

        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('coupon', 200, true));

        try {
            B2BStripeService.createCoupon(discountedAmount, currencyCode);
        }
        catch(Exception e){
            System.debug('Exception in createCoupon: ' + e.getMessage());
        }
        Test.StopTest();
    }
}