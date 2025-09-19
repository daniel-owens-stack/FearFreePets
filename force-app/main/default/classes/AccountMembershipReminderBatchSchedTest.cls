@isTest
public class AccountMembershipReminderBatchSchedTest {
    @isTest
    static void testScheduler() {
        // Schedule the job to run one minute from now
        String cronExp = '0 0 0 1 1 ? 2099'; // Far future date, just for test
        Test.startTest();
        System.schedule('Test AccountMembershipReminderBatchScheduler', cronExp, new AccountMembershipReminderBatchScheduler());
        Test.stopTest();
        // Optionally, you can assert that the batch ran by checking AsyncApexJob or debug logs
    }
}