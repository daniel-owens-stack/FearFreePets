public class B2BSchooxAPIController {

    public static void handleJobAssignmnet(String accountId, List<Integer> jobIds) {
        Account account = B2BSchooxAPIServiceHelper.getAccountById(accountId);
        String studentId = account.SX_User_Id__pc;
        if (studentId == null) {
            SchooxAPI.handleLMSUser(accountId, jobIds);
            return;
        }
        B2BSchooxAPIWrapper.SchooxUser schooxUser = B2BSchooxAPIService.getSchooxUser(accountId);
        if (!schooxUser.isActive) {
            SchooxAPI.reActivateLMSUser(schooxUser.studentId);
        }
        List<Integer> existingJobs = schooxUser.jobs;
        List<Integer> combinedJobList = B2BSchooxAPIServiceHelper.combineIntegerLists(jobIds, existingJobs);
        SchooxAPI.updateLMSUser(accountId, combinedJobList);
    }

    public static void getAllJobs() {
        SchooxAPI.getAllJob();
    }

    @AuraEnabled
    public static void handleJobAssignmentManual(String recordId) {
        
        Account_Membership__c ilma = [
            SELECT Id, Membership__r.Job_Id__c, Account_Id__c FROM Account_Membership__c
            WHERE Id =: recordId
        ];
        System.debug('ILMA '+ ilma);

        String accountId = ilma.Account_Id__c;
        List<Integer> jobIdsToAdd = new List<Integer>();
        jobIdsToAdd.add(Integer.valueOf(ilma.Membership__r.Job_Id__c));
        handleJobAssignmnet(accountId,jobIdsToAdd);
    }

    @AuraEnabled
    public static void handleJobUnassignmentManual(String recordId) {
        
        Account_Membership__c ilma = [
            SELECT Id, Membership__r.Job_Id__c, Account_Id__c FROM Account_Membership__c
            WHERE Id =: recordId
        ];

        String accountId = ilma.Account_Id__c;
        List<Integer> jobIdsToAdd = new List<Integer>();
        jobIdsToAdd.add(Integer.valueOf(ilma.Membership__r.Job_Id__c));
        B2BMembershipEndHelper.unassignSchooxJobs(accountId, jobIdsToAdd);
    }

}