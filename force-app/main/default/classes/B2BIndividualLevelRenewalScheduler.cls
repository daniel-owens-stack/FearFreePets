global class B2BIndividualLevelRenewalScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        Map<String,String> minMaxDates = B2BUtils.calculateMinMaxRenewalOffsetRange();

        if(minMaxDates != null) {
            String minDate = minMaxDates.get('minDate');
            String maxDate = minMaxDates.get('maxDate');

            String query = 'SELECT Id, Name, Billing_Email__c, Billing_Email_Verified__c, BillingAddress, Payment_Terms__c ' +
                        'FROM Account ' + 
                        'WHERE IndividualLevelRenewalDate__c >= ' + minDate + ' AND IndividualLevelRenewalDate__c <= ' + maxDate;

            Integer batchSize = Integer.valueOf(System.Label.B2B_Individual_Level_Auto_Renewals_Batch_Size);

            B2BIndividualLevelRenewalsBatch b = new B2BIndividualLevelRenewalsBatch(query); 
            Database.executeBatch(b, batchSize);
        }
    }
}