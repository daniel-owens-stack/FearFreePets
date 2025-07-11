public with sharing class B2BMembershipEndBatchRunner {
    @AuraEnabled
    public static String simulateRun(Date runDate) {
        Integer batchSize = 30;
        Integer offset = 0;
        Boolean hasMoreRecords = true;
        Integer totalProcessed = 0;

        try {
            while (hasMoreRecords) {
                List<Account_Membership__c> expiredMemberships = [
                    SELECT Id, Status__c, Account_Id__c, can_be_fully_reassigned__c, Membership__c, Job_Id__c, Certified__c, Expired__c
                    FROM Account_Membership__c
                    WHERE Status__c != 'Complete'
                    AND (Expiration_Date__c = :runDate OR LastModifiedDate = :runDate)
                    ORDER BY LastModifiedDate ASC
                    LIMIT :batchSize OFFSET :offset
                ];

                if (expiredMemberships.isEmpty()) {
                    hasMoreRecords = false;
                } else {
                    B2BMembershipEndController.handleMembershipUnassignments(expiredMemberships);
                    offset += batchSize;
                    totalProcessed += expiredMemberships.size();
                }
            }

            return totalProcessed > 0
                ? 'Batch ran successfully. Total records processed: ' + totalProcessed
                : 'No memberships found for the selected date.';
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BMembershipEndBatchRunner', 'simulateRun');
            return 'Batch failed due to error: ' + e.getMessage();
        }
    }
}