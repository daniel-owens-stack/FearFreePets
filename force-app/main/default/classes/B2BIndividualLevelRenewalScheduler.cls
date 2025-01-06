global class B2BIndividualLevelRenewalScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        String query = 'SELECT Id, Name, Billing_Email__c, Billing_Email_Verified__c, BillingAddress, Payment_Terms__c ' +
                       'FROM Account ' + 
                       'WHERE IndividualLevelRenewalDate__c = TODAY';

        Integer batchSize = Integer.valueOf(System.Label.B2B_Individual_Level_Auto_Renewals_Batch_Size);

        B2BIndividualLevelRenewalsBatch b = new B2BIndividualLevelRenewalsBatch(query); 
        Database.executeBatch(b, batchSize);
    }
}