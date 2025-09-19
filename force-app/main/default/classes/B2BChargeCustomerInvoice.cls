public class B2BChargeCustomerInvoice {

    // @AuraEnabled
    // public static Invoice__c getInvoice(String invoiceId) {
    //     Invoice__c invoice= [SELECT Id, Stripe_Invoice_Id__c, Status__c,Stripe_Payment_URL__c FROM Invoice__c WHERE Id =:invoiceId];

    //     List<Order> order = [SELECT Id, Account.Payment_Terms__c, IsRenewal__c FROM Order WHERE InvoiceId__c = :invoice.Stripe_Invoice_Id__c];
        
    //     if(order.size() > 0) {
    //         if(order[0].IsRenewal__c) {
    //             if(order[0].Account.Payment_Terms__c == 'Credit Card Only') {
    //                 return invoice;
    //             }
    //         }
    //     }
    //     return null;
    // }
    
    // @AuraEnabled
    // public static String chargeCustomerInvoice(List<String> invoiceIds) {
    //     try {
    //         if(!invoiceIds.isEmpty()) {
    //             for (String invoiceId : invoiceIds) {
    //                 B2BStripePaymentController.chargeCustomerInvoice(invoiceId);
    //             }
    //         }
    //         return 'success';
    //     }
    //     catch(Exception e) {
    //         B2BHandleCustomException.LogException(e, 'B2BChargeCustomerInvoiceInvocable', 'chargeCustomerInvoice');
    //         return e.getMessage();
    //     } 
    // } 
}