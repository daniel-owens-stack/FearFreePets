global class B2BCalculateILMARenewalDatesScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        Map<String,String> minMaxDates = B2BUtils.calculateMinMaxRenewalOffsetRange();

        if(minMaxDates != null) {
            String minDate = minMaxDates.get('minDate');
            String maxDate = minMaxDates.get('maxDate');

            String query = 'SELECT Parent_Id__c '+
                           'FROM Account_Membership__c ' +
                           'WHERE Expiration_Date__c >= ' + minDate + ' AND Expiration_Date__c <= ' + maxDate;

            Integer batchSize = Integer.valueOf(System.Label.B2B_Calculate_Renewal_Dates_Batch_Size);

            B2BCalculateILMARenewalDatesBatch b = new B2BCalculateILMARenewalDatesBatch(query); 
            Database.executeBatch(b, batchSize);
        }
    }
}