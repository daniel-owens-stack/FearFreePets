public class B2BSchooxJobsUnassignmentQueueable implements Queueable, Database.AllowsCallouts {
    
    private Map<String, List<Integer>> accountJobMap;

    public B2BSchooxJobsUnassignmentQueueable(Map<String, List<Integer>> accountJobMap) {
        this.accountJobMap = accountJobMap;
    }

    public void execute(QueueableContext context) {
        for (String accountId : accountJobMap.keySet()) {
            B2BSchooxAPIController.handleJobUnassignment(accountId, accountJobMap.get(accountId));
        }
    }
}