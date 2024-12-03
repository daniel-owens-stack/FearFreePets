@isTest
public class B2BFreightRateCalculatorTest {

    @isTest static void testCalculateShippingPrice() {

        Decimal result;
        Test.StartTest();
        result = B2BFreightRateCalculator.calculateShippingPrice(5000.0, 'US');
        Test.StopTest();
    }
}