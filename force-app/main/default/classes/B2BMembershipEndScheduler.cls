global class B2BMembershipEndScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        Integer batchSize = Integer.valueOf(System.Label.B2B_Membership_End_Batch_Size);

        B2BMembershipEndBatch b = new B2BMembershipEndBatch(); 
        Database.executeBatch(b, batchSize);
    }
}