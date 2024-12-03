public class B2BHandleJobAssignmentInvokable {
    @InvocableMethod(label='Handle Job Assignment' description='Handles job assignment for a given Account Id and list of job IDs.')
    public static void handleJobAssignment(List<Request> requestList) {
        for (Request req : requestList) {
            handleJobAssignmentInternal(req.accountId, req.jobIds);
        }
    }
    
    public class Request {
        @InvocableVariable(required=true) 
        public String accountId;

        @InvocableVariable(required=true)
        public List<Integer> jobIds;
    }
    
    private static void handleJobAssignmentInternal(String accountId, List<Integer> jobIds) {
        Account account = B2BSchooxAPIServiceHelper.getAccountById(accountId);
        String studentId = account.SX_User_Id__pc;
        
        if (studentId == null) {
            SchooxAPI.handleLMSUser(accountId, jobIds);
            return;
        }
        
        B2BSchooxAPIWrapper.SchooxUser schooxUser = B2BSchooxAPIService.getSchooxUser(accountId);
        List<Integer> existingJobs = schooxUser.jobs;
        
        List<Integer> combinedJobList = B2BSchooxAPIServiceHelper.combineIntegerLists(jobIds, existingJobs);
        
        SchooxAPI.updateLMSUser(accountId, combinedJobList);
    }
}