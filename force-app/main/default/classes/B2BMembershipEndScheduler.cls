global class B2BMembershipEndScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        String query = 'SELECT Id, Status__c, Account_Id__c, can_be_fully_reassigned__c, Membership__c ' +
                       'FROM Account_Membership__c ' + 
                       'WHERE Expiration_Date__c =  TODAY OR LastModifiedDate = TODAY';

        Integer batchSize = Integer.valueOf(System.Label.B2B_Membership_End_Batch_Size);

        B2BMembershipEndBatch b = new B2BMembershipEndBatch(query); 
        Database.executeBatch(b, batchSize);
    }
}