@IsTest
private class EnrollmentsDueSchedulerTest {
    @IsTest
    static void test_installEvery10Min_schedulesCron() {
        Test.startTest();
        Id jobId = EnrollmentsDueScheduler.start();  // schedules job and returns Id

        // ✅ Assert while the trigger still exists
        CronTrigger ct = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
            LIMIT 1
        ];
        System.assertEquals('EnrollmentsRolling', ct.CronJobDetail.Name,
            'Expected the rolling scheduler job to be created.');

        Test.stopTest(); // now it will execute + chain the next run
    }
}