@IsTest
public class B2BGetProductPriceInvokableTest {
    
    @isTest static void testGetProductPriceByAccount() {

        String accountId = B2BTestDataFactory.createAccount();
        String productId = B2BTestDataFactory.createProduct();

        B2BGetProductPriceInvokable.Input input= new B2BGetProductPriceInvokable.Input();
        input.accountId = accountId;
        input.productId = productId;

        List<B2BGetProductPriceInvokable.Input> inputs = new List<B2BGetProductPriceInvokable.Input>{input};

        Test.StartTest();
        B2BGetProductPriceInvokable.getProductPriceByAccount(inputs);
        Test.StopTest();
    }
}