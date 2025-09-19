public class B2BSchooxJobAssignmentQueueable implements Queueable, Database.AllowsCallouts {
    private String accountId;
    private List<Integer> jobIds;

    public B2BSchooxJobAssignmentQueueable(String accountId, List<Integer> jobIds) {
        this.accountId = accountId;
        this.jobIds = jobIds;
    }

    public void execute(QueueableContext context) {
        B2BSchooxAPIController.handleJobAssignmnet(accountId, jobIds);
    }
}