global class B2BCalculateILMARenewalDatesScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        Integer batchSize = Integer.valueOf(System.Label.B2B_Calculate_Renewal_Dates_Batch_Size);

        B2BCalculateILMARenewalDatesBatch b = new B2BCalculateILMARenewalDatesBatch(); 
        Database.executeBatch(b, batchSize);
    }
}