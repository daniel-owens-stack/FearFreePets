public class RemoveLMSUserQueueable implements Queueable, Database.AllowsCallouts {
    private String userId;

    public RemoveLMSUserQueueable(String userId) {
        this.userId = userId;
    }

    public void execute(QueueableContext context) {
        try {
            SchooxAPI.removeLMSUser(userId);
        } catch (Exception e) {
            System.debug('Error removing LMS user in queueable for userId ' + userId + ': ' + e.getMessage());
        }
    }
}