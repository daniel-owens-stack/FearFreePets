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

}