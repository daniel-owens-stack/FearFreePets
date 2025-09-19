global class B2BPLMAMembershipEndScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        Integer batchSize = Integer.valueOf(System.Label.B2B_Membership_End_Batch_Size);

        B2BPLMAMembershipEndBatch b = new B2BPLMAMembershipEndBatch(); 
        Database.executeBatch(b, batchSize);
    }
}