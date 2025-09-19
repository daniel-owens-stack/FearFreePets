public class B2BProcessHistoricalAccountGroupsBatch implements Database.Batchable<sObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, Name, Group_Id__c, Data__c, Role__c, User_Id__c
            FROM Historical_Account_Group__c
            WHERE Data__c = 'Pending'
        ]);
    }

    public void execute(Database.BatchableContext context, List<Historical_Account_Group__c> scope) {
        List<Historical_Account_Group__c> toUpdate = new List<Historical_Account_Group__c>();
        Set<String> userIds = new Set<String>();

        for (Historical_Account_Group__c hag : scope) {
            userIds.add(hag.User_Id__c);
        }

        // Preload all person accounts by User_Id__c (Original_System_ID__c on Person Account)
        Map<String, Account> personAccountsBySystemId = new Map<String, Account>();
        for (Account acc : [
            SELECT Id, Original_System_ID__c
            FROM Account
            WHERE RecordType.Name = 'Person Account'
            AND Original_System_ID__c IN :userIds
        ]) {
            personAccountsBySystemId.put(acc.Original_System_ID__c, acc);
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Historical_Account_Group__c hag : scope) {
            Account business = null;

            // Step 1: Try to find Business Account where Original_System_ID__c = Group_Id__c
            List<Account> directBusiness = [
                SELECT Id, Name, Original_System_ID__c, Historical_Admin__c, Historical_Primary_Group__c
                FROM Account
                WHERE RecordType.Name = 'Business Account'
                AND Original_System_ID__c = :hag.Group_Id__c
                LIMIT 1
            ];

            if (!directBusiness.isEmpty()) {
                Account firstResult = directBusiness[0];
                if (firstResult.Historical_Primary_Group__c) {
                    business = firstResult;
                } else {
                    // Step 2: If Primary Group is false, find by Historical_Admin__c
                    List<Account> adminBasedBusiness = [
                        SELECT Id, Name, RecordType.Name, Historical_Admin__c, Historical_Primary_Group__c
                        FROM Account
                        WHERE Historical_Admin__c = :firstResult.Historical_Admin__c
                        AND Historical_Primary_Group__c = true
                        AND RecordType.Name = 'Business Account'
                        LIMIT 1
                    ];

                    if (!adminBasedBusiness.isEmpty()) {
                        business = adminBasedBusiness[0];
                    }
                }
            }

            if (business == null) {
                hag.Data__c = 'Unsuccessful';
                hag.B2B_Custom_Exception__c = B2BHandleCustomException.LogException(
                    new HistoricalGroupException('No Business Account found for Group Id: ' + hag.Group_Id__c),
                    'Historical Account Groups',
                    'Business Lookup'
                );
                toUpdate.add(hag);
                continue;
            }

            // Lookup Person Account
            Account person = personAccountsBySystemId.get(hag.User_Id__c);
            if (person == null) {
                hag.Data__c = 'Unsuccessful';
                hag.B2B_Custom_Exception__c = B2BHandleCustomException.LogException(
                    new HistoricalGroupException('No Person Account found for User Id: ' + hag.User_Id__c),
                    'Historical Account Groups',
                    'Person Lookup'
                );
                toUpdate.add(hag);
                continue;
            }

            // Link person to business
            person.Business__c = business.Id;
            accountsToUpdate.add(person);

            // Mark as successful
            hag.Data__c = 'Successful';
            toUpdate.add(hag);
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {}

    public class HistoricalGroupException extends Exception {}
}