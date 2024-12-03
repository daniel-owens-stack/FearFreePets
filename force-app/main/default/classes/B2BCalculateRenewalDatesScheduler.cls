global class B2BCalculateRenewalDatesScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        String query = 'SELECT Id, IndividualLevelRenewalDate__c, PracticeLevelRenewalDate__c ' +
                       'FROM Account ' + 
                       'WHERE RecordTypeId = :businessRecordTypeId ' +
                       'OR (RecordTypeId = :personRecordTypeId AND Business__c = null)';

        Integer batchSize = Integer.valueOf(System.Label.B2B_Calculate_Renewal_Dates_Batch_Size);

        B2BCalculateRenewalDatesBatch b = new B2BCalculateRenewalDatesBatch(query); 
        Database.executeBatch(b, batchSize);
    }
}