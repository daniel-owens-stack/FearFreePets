global class B2BCalculatePLMARenewalDatesScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        Map<String,String> minMaxDates = B2BUtils.calculateMinMaxRenewalOffsetRange();

        if(minMaxDates != null) {
            String minDate = minMaxDates.get('minDate');
            String maxDate = minMaxDates.get('maxDate');

            String query = 'SELECT Business_Account__c '+
                           'FROM Practice_Level_Membership_Assignment__c ' +
                           'WHERE Expiration_Date__c >= ' + minDate + ' AND Expiration_Date__c <= ' + maxDate +
                           ' AND Status__c = \'Active\'';

            Integer batchSize = Integer.valueOf(System.Label.B2B_Calculate_Renewal_Dates_Batch_Size);

            B2BCalculatePLMARenewalDatesBatch b = new B2BCalculatePLMARenewalDatesBatch(query); 
            Database.executeBatch(b, batchSize);
        }
    }
}