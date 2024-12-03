public class B2BScheduledApexInvocable {

    @InvocableMethod(label='Call Schedulable Class' description='Immediately executes  a SchedulableClass from Flow')
    public static void executeSchedulable(List<String> apexclassNames) {

        String apexClassName = apexclassNames[0];
        String jobName = 'Flow_Invoked_Schedulable_' + DateTime.now().getTime();
        String cronExpression = '0 ' + (DateTime.now().minute() + 1) + ' ' + DateTime.now().hour() + ' * * ?';

        // Schedule the job to execute immediately
        try {
            Type schedulableType = Type.forName('', apexClassName);

            if (schedulableType != null) {
                Schedulable schedulableInstance = (Schedulable) schedulableType.newInstance();
                System.schedule(jobName, cronExpression, schedulableInstance);
            } 
            else {
                throw new IllegalArgumentException('Class not found or is not Schedulable.');
            }
        } catch (Exception e) {
            System.debug('Error scheduling class: ' + e.getMessage());
        }
    }
}