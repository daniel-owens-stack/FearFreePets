trigger b2bHandleCertificationKitBeforeOrder on OrderItem (after insert) {
   
    if(B2BHandleCertificationKitBeforeOrder.runTrigger()) {
        String orderId;
        for (OrderItem oi : Trigger.new) {
            orderId = oi.OrderId;
        }
        B2BHandleCertificationKitBeforeOrder.updateOrderItems(orderId);
    }
}