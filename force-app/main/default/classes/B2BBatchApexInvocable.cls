public class B2BBatchApexInvocable {

    @InvocableMethod(label='Call Batch Class' description='Immediately executes a Batch Class from Flow')
    public static void executeBatchable(List<String> apexclassNames) {

        String apexClassName = apexclassNames[0];

        // Call the batch to execute immediately
        try {
            Type batchType = Type.forName(apexClassName);

                if (batchType != null) {
                    Object batchInstance = batchType.newInstance();

                    if (batchInstance instanceof Database.Batchable<sObject>) {
                        // Cast to Batchable and execute the batch
                        Database.Batchable<sObject> batchableInstance = (Database.Batchable<sObject>) batchInstance;

                        Integer batchSize = 50; 
                        Database.executeBatch(batchableInstance, batchSize);
                    } else {
                        throw new IllegalArgumentException(apexClassName + ' does not implement the Batchable interface.');
                    }
                } else {
                    throw new IllegalArgumentException('Class not found: ' + apexClassName);
                }
        } catch (Exception e) {
            System.debug('Error executing batch: ' + e.getMessage());
        }
    }
}