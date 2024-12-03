global class B2BPracticeLevelRenewalScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        Map<String,String> minMaxDates = B2BUtils.calculateMinMaxRenewalOffsetRange();

        if(minMaxDates != null) {
            String minDate = minMaxDates.get('minDate');
            String maxDate = minMaxDates.get('maxDate');

            String query = 'SELECT Id, Name, Billing_Email__c, Billing_Email_Verified__c, BillingAddress, Payment_Terms__c' 
                            + ' FROM Account'
                            + ' WHERE PracticeLevelRenewalDate__c >= ' + minDate + ' AND PracticeLevelRenewalDate__c <= ' + maxDate;

            Integer batchSize = Integer.valueOf(System.Label.B2B_Practice_Level_Auto_Renewals_Batch_Size);

            B2BPracticeLevelRenewalsBatch b = new B2BPracticeLevelRenewalsBatch(query); 
            Database.executeBatch(b, batchSize);
        }
    }
}