@isTest
public class B2BCartCalculateSampleTest extends CartExtension.CartCalculate {
    @isTest static void testCalculate_runPricing() {

        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();
        cart.setName('Test Webcart');

        CartExtension.BuyerActionsMock buyerActions = new CartExtension.BuyerActionsMock(cart);
        buyerActions.setCartItemChanged(true);

        CartExtension.BuyerActionDetails buyerActionDetails;

        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(
            cart,
            new CartExtension.BuyerActionsMock(cart),
            CartExtension.OptionalBuyerActionDetails.of(buyerActionDetails)
        );
    
        B2BCartCalculateSample cartCalulate = new B2BCartCalculateSample();
        Test.StartTest();
        cartCalulate.calculate(request);
        Test.StopTest();

        System.assertEquals('Test Webcart', cart.getName(), 'Cart Name should match');
    }

    @isTest static void testCalculate_runPromotions() {

        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();
        cart.setName('Test Webcart');

        CartExtension.BuyerActionsMock buyerActions = new CartExtension.BuyerActionsMock(cart);
        buyerActions.setCouponChanged(true);

        CartExtension.BuyerActionDetails buyerActionDetails;

        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(
            cart,
            new CartExtension.BuyerActionsMock(cart),
            CartExtension.OptionalBuyerActionDetails.of(buyerActionDetails)
        );
    
        B2BCartCalculateSample cartCalulate = new B2BCartCalculateSample();
        Test.StartTest();
        cartCalulate.calculate(request);
        Test.StopTest();

        System.assertEquals('Test Webcart', cart.getName(), 'Cart Name should match');
    }

    @isTest static void testCalculate_runShipping() {

        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();
        cart.setName('Test Webcart');

        CartExtension.BuyerActionsMock buyerActions = new CartExtension.BuyerActionsMock(cart);
        buyerActions.setDeliveryGroupChanged(true);

        CartExtension.BuyerActionDetails buyerActionDetails;

        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(
            cart,
            new CartExtension.BuyerActionsMock(cart),
            CartExtension.OptionalBuyerActionDetails.of(buyerActionDetails)
        );
    
        B2BCartCalculateSample cartCalulate = new B2BCartCalculateSample();
        Test.StartTest();
        cartCalulate.calculate(request);
        Test.StopTest();

        System.assertEquals('Test Webcart', cart.getName(), 'Cart Name should match');
    }

    @isTest static void testCalculate_runPostShipping() {

        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();
        cart.setName('Test Webcart');

        CartExtension.BuyerActionsMock buyerActions = new CartExtension.BuyerActionsMock(cart);
        buyerActions.setDeliveryMethodSelected(true);

        CartExtension.BuyerActionDetails buyerActionDetails;

        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(
            cart,
            new CartExtension.BuyerActionsMock(cart),
            CartExtension.OptionalBuyerActionDetails.of(buyerActionDetails)
        );
    
        B2BCartCalculateSample cartCalulate = new B2BCartCalculateSample();
        Test.StartTest();
        cartCalulate.calculate(request);
        Test.StopTest();

        System.assertEquals('Test Webcart', cart.getName(), 'Cart Name should match');
    }
}