public class B2BSchooxJobAssignmentQueueable implements Queueable, Database.AllowsCallouts {
    private String accountId;
    private List<Integer> jobIds;

    // Constructor to pass the required parameters
    public B2BSchooxJobAssignmentQueueable(String accountId, List<Integer> jobIds) {
        this.accountId = accountId;
        this.jobIds = jobIds;
    }

    // The execute method that runs in the queueable context
    public void execute(QueueableContext context) {
        try {
            B2BSchooxAPIController.handleJobAssignmnet(accountId, jobIds);
        } catch (Exception ex) {
            // Handle exceptions here, e.g., log errors or send notifications
            System.debug('Error in Queueable Job Assignment: ' + ex.getMessage());
        }
    }
}
