global class B2BRenewalInvoiceScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Integer batchSize = Integer.valueOf(System.Label.B2B_Invoice_Renewals_Batch_Size);
            
        B2BRenewalInvoiceBatch b = new B2BRenewalInvoiceBatch(); 
        Database.executeBatch(b, batchSize);
    }
}