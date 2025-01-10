public class B2BOrderServiceInvoker {

    @InvocableMethod(label='Call Order Service')
    public static void invokeOrderService(List<List<Id>> orderItemSummaryIds) {
    
        List<Id> orderItemIds = orderItemSummaryIds.get(0);
        B2BVeraCoreSendReq.sendOrderReq(orderItemIds);
    }
}