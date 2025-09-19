global with sharing class EnrollmentsDueScheduler implements Schedulable {
    private static final String JOB_NAME = 'EnrollmentsRolling';
    
    global void execute(SchedulableContext sc) {
        // 🔎 Cheap probe: only run the batch if at least one record is due
        List<SX_LMS_User__c> dueOne = [
            SELECT Id
            FROM SX_LMS_User__c
            WHERE SX_Process_Pending__c = true
              AND Enrollments_Due_At__c <= :Datetime.now()
            LIMIT 1
        ];
        if (!dueOne.isEmpty()) {
            Database.executeBatch(new BatchEnrollmentsSync_ProcessPendingDue(), 50);
        }
        scheduleNext(10);
    }
    
    // Start the rolling job and return the scheduled jobId (as Id)
    public static Id start() {
        abortExisting(JOB_NAME);
        return scheduleNext(10);
    }
    
    // Schedules the next run N minutes from now, returns jobId
    private static Id scheduleNext(Integer minutesFromNow) {
        if (minutesFromNow == null || minutesFromNow <= 0) minutesFromNow = 10;
        
        Datetime runTime = Datetime.now().addMinutes(minutesFromNow);
        String cronExp = String.format(
            '{0} {1} {2} {3} {4} ? {5}',
        new String[] {
            String.valueOf(runTime.second()),
            String.valueOf(runTime.minute()),
            String.valueOf(runTime.hour()),
            String.valueOf(runTime.day()),
            String.valueOf(runTime.month()),
            String.valueOf(runTime.year())
        }
        );
        
        abortExisting(JOB_NAME); // ensure single rolling job
        String jobId = System.schedule(JOB_NAME, cronExp, new EnrollmentsDueScheduler());
        return (Id)jobId;
    }
    
    public static void abortExisting(String jobName) {
        for (CronTrigger ct : [
            SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName
        ]) {
            System.abortJob(ct.Id);
        }
    }
}