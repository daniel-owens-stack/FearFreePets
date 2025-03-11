public class B2BSchooxJobsUnassignmentQueueable implements Queueable, Database.AllowsCallouts {
    private String accountId;
    private List<Integer> jobIdsToRemove;

    public B2BSchooxJobsUnassignmentQueueable(String accountId, List<Integer> jobIdsToRemove) {
        this.accountId = accountId;
        this.jobIdsToRemove = jobIdsToRemove;
    }

    public void execute(QueueableContext context) {
        B2BSchooxAPIController.handleJobUnassignment(accountId, jobIdsToRemove);
    }
}