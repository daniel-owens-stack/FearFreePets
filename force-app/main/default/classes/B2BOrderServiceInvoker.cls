public class B2BOrderServiceInvoker {

    @InvocableMethod(label='Call Order Service')
    public static List<OrderServiceResult> invokeOrderService(List<List<Id>> orderItemSummaryIds) {
    
        List<Id> orderItemIds = orderItemSummaryIds.get(0);
        B2BVeraCoreSendReq.sendOrderReq(orderItemIds);

        List<OrderServiceResult> results = new List<OrderServiceResult>();
        return results;
    }

    public class OrderServiceResult {
        @InvocableVariable
        public String statusCode;
        @InvocableVariable
        public Id orderId;
    }
}