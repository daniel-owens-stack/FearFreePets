global class B2BPracticeLevelRenewalScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        Integer batchSize = Integer.valueOf(System.Label.B2B_Practice_Level_Auto_Renewals_Batch_Size);

        B2BPracticeLevelRenewalsBatch b = new B2BPracticeLevelRenewalsBatch(); 
        Database.executeBatch(b, batchSize);
    }
}