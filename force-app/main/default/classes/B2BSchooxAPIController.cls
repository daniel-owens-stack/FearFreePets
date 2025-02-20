public class B2BSchooxAPIController {
    @future(callout = true)
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

    public static void handleJobUnassignment(String accountId, List<Integer> jobIdsToRemove) {
        B2BSchooxAPIWrapper.SchooxUser schooxUser = B2BSchooxAPIService.getSchooxUser(accountId);

        if (!schooxUser.isActive) {
           return;
        }

        List<Integer> existingJobs = schooxUser.jobs;

        for (Integer jobIdToRemove : jobIdsToRemove) {
            if (existingJobs.contains(jobIdToRemove)) {
                existingJobs.remove(existingJobs.indexOf(jobIdToRemove));
            }
        }

        SchooxAPI.updateLMSUser(accountId, existingJobs);
        
        if(existingJobs.isEmpty() || existingJobs == null) {
            SchooxAPI.removeLMSUser(schooxUser.studentId);
        } 
    }

    public static void getAllJobs() {
        SchooxAPI.getAllJob();
    }

    /**
     * This class is used to test schoox job assignment from ILMA record page manually
     */
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

    /**
     * This class is used to test schoox job unassignment from ILMA record page manually
     */
    @AuraEnabled
    public static void handleJobUnassignmentManual(String recordId) {
        
        Account_Membership__c ilma = [
            SELECT Id, Membership__r.Job_Id__c, Account_Id__c FROM Account_Membership__c
            WHERE Id =: recordId
        ];

        String accountId = ilma.Account_Id__c;
        List<Integer> jobIdsToRemove = new List<Integer>();
        jobIdsToRemove.add(Integer.valueOf(ilma.Membership__r.Job_Id__c));
        handleJobUnassignment(accountId, jobIdsToRemove);
    }

}