@IsTest(SeeAllData=true)
public class B2BOrderServiceInvokerTest {
    
    @isTest static void testInvokeOrderService() {

        String accountId = B2BTestDataFactory.createAccount();
        String productId = B2BTestDataFactory.createProduct();
        Id orderId = B2BTestDataFactory.createOrder(accountId, productId);

        ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
        osir.orderId = orderId;
        osir.orderLifeCycleType = 'UNMANAGED';
        ConnectApi.OrderSummaryOutputRepresentation osor = ConnectApi.OrderSummaryCreation.createOrderSummary(osir);

        String orderSummaryId = osor.orderSummaryId;

        Test.StartTest();
        List<List<Id>> orderItemSummaryIds = new List<List<Id>>();
        List<Id> oisIds = new List<Id>();
        Id oisId = [SELECT Id FROM OrderItemSummary WHERE OrderSummaryId = :orderSummaryId LIMIT 1].Id;
        oisIds.add(oisId);
        orderItemSummaryIds.add(oisIds);
        
        Test.setMock(HttpCalloutMock.class, new B2BSOAPApiCallMock());
        B2BOrderServiceInvoker.invokeOrderService(orderItemSummaryIds);
        Test.StopTest();
    }
}