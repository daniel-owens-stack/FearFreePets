global class B2BCalculatePLMARenewalDatesScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        Integer batchSize = Integer.valueOf(System.Label.B2B_Calculate_Renewal_Dates_Batch_Size);

        B2BCalculatePLMARenewalDatesBatch b = new B2BCalculatePLMARenewalDatesBatch(); 
        Database.executeBatch(b, batchSize);
    }
}