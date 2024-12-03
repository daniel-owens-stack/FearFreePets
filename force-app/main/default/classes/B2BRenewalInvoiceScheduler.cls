global class B2BRenewalInvoiceScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
    
        Map<String,String> minMaxDates = B2BUtils.calculateMinMaxRenewalOffsetRange();

        if(minMaxDates != null) {
            String minDate = minMaxDates.get('minDate');
            String maxDate = minMaxDates.get('maxDate');
        
            String query = 
                'SELECT Id, AccountId, Account.StripeCustomerId__c, Account.Payment_Terms__c'
                + ' FROM Order'
                + ' WHERE EffectiveDate >= ' + minDate + ' AND EffectiveDate <= ' + maxDate +
                + ' AND IsRenewal__c = TRUE'
                + ' AND Status = \'Draft\'' ;
            
            Integer batchSize = Integer.valueOf(System.Label.B2B_Invoice_Renewals_Batch_Size);
            
            B2BRenewalInvoiceBatch b = new B2BRenewalInvoiceBatch(query); 
            Database.executeBatch(b, batchSize);
        }
    }
}