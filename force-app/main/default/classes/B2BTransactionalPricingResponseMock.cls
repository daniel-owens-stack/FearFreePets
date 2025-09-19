@IsTest
public class B2BTransactionalPricingResponseMock extends commercestorepricing.PricingService{
 
    public static commercestorepricing.TransactionalPricingResponse processTransactionalPrice() {
        commercestorepricing.TransactionalPricingResponse response = new commercestorepricing.TransactionalPricingResponse(0, 0, 0, 0, 'USD');

        Product2 testProduct1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product1' LIMIT 1] ;

        commercestorepricing.TransactionalPricingResponseItem responseItem = new commercestorepricing.TransactionalPricingResponseItem(null, testProduct1.Id, null, 0, 0, 0, 0, 0, 0, 0, 1.0, 'USD');

        response.addTxnPricingResponseItem(responseItem);

        commercestorepricing.TxnPricingResponseItemCollection col = response.getTxnPricingResponseItems();
        System.debug('##Mock Response Items:'+ col);
        return response;
    }        
}