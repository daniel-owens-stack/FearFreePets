global class B2BChargeCustomerInvoiceScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        List<Invoice__c> invoices = [SELECT Id, Due_Date__c, Status__c, Stripe_Invoice_Id__c
                                     FROM Invoice__c 
                                     WHERE Due_Date__c = TODAY AND Status__c = 'Active'
                                    ];

        List<String> stripeInvoiceIds = new List<String>();
        for(Invoice__c invoice : invoices) {
            stripeInvoiceIds.add(invoice.Stripe_Invoice_Id__c);
        }

        List<Order> orders = [SELECT Id, InvoiceId__c, Account.Payment_Terms__c FROM Order WHERE InvoiceId__c IN :stripeInvoiceIds];
        
        List<String> eligibleInvoiceIds = new List<String>();
        for(Order order : orders) {
            if(order.Account.Payment_Terms__c == 'Credit Card Only') {
                eligibleInvoiceIds.add(order.InvoiceId__c);
            }
        }

        if(!eligibleInvoiceIds.isEmpty()) {
            B2BChargeCustomerInvoice.chargeCustomerInvoice(eligibleInvoiceIds);
        }
    }
}