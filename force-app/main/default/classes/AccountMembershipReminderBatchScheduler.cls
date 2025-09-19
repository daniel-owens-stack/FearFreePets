global class AccountMembershipReminderBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        AccountMembershipReminderBatch batch = new AccountMembershipReminderBatch();
        Database.executeBatch(batch, 200);
    }
}