@isTest
public class B2BCartCalc_DigitalShippingTest extends CartExtension.CartCalculate {

    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String webStoreId  = [SELECT Id FROM WebStore WHERE Name = 'TestWebStore' LIMIT 1].Id;
        String accountId = B2BTestDataFactory.createAccount();
        String contactId = B2BTestDataFactory.createContact(accountId);
        User user = B2BTestDataFactory.createCommunityUser(contactId);
        B2BTestDataFactory.createWebCart(webStoreId, accountId, user.Id);

        B2BTestDataFactory.createProduct();
        B2BTestDataFactory.createShippingProduct();

        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Product1' LIMIT 1].Id;
        B2BTestDataFactory.createOrderDeliveryMethod(productId);

    }

    @isTest static void testCalculate() {

        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();
        cart.setName('Test Cart');

        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(
            cart,
            CartExtension.OptionalBuyerActionDetails.empty()
        );
    
        B2BCartCalc_DigitalShipping shippingClass = new B2BCartCalc_DigitalShipping();
        Test.StartTest();
        shippingClass.calculate(request);
        Test.StopTest();

        System.assertEquals('Test Cart', cart.getName(), 'Cart Name should match');
    }

    @isTest static void testCalculate_reCheckout() {
        Id cartId = [SELECT Id FROM WebCart WHERE Name = 'Test Cart' LIMIT 1].Id;
        CartExtension.Cart cart = CartExtension.CartTestUtil.getCart(cartId);
    
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(
            cart,
            CartExtension.OptionalBuyerActionDetails.empty()
        );
    
        B2BCartCalc_DigitalShipping shippingClass = new B2BCartCalc_DigitalShipping();
        Test.StartTest();
        shippingClass.calculate(request);
        Test.StopTest();

        System.assertEquals('Test Cart', cart.getName(), 'Cart Name should match');
    }
}