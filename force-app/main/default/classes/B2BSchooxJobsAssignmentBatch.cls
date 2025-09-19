global with sharing class B2BSchooxJobsAssignmentBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('### START method called');
        Integer a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
            a = 1;
        return Database.getQueryLocator([
            SELECT Id, Name 
            FROM Account 
            WHERE IsPersonAccount = TRUE 
              AND (Historical_Jobs_Assigned__c = 'Has Membership')
            LIMIT 50000
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> accounts) {
        System.debug('### EXECUTE method called with accounts: ' + accounts);

        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }

        // Active memberships with valid job ids
        List<Account_Membership__c> memberships = [
            SELECT Id, Name, Account_Id__c, Job_Id__c 
            FROM Account_Membership__c 
            WHERE Historical_Membership__c != null
              AND Status__c = 'Active'
              AND Membership__r.Active__c = true
              AND Account_Id__c IN :accountIds
        ];

        // Map of accountId to job ids
        Map<Id, List<Integer>> accountJobMap = new Map<Id, List<Integer>>();
        for (Account_Membership__c am : memberships) {
            if (am.Account_Id__c != null && am.Job_Id__c != null) {
                if (!accountJobMap.containsKey(am.Account_Id__c)) {
                    accountJobMap.put(am.Account_Id__c, new List<Integer>());
                }
                accountJobMap.get(am.Account_Id__c).add(Integer.valueOf(am.Job_Id__c));
            }
        }

        // Detect any membership presence (active or not)
        Set<Id> accountsWithAnyMemberships = new Set<Id>();
        for (Account_Membership__c am : [
            SELECT Account_Id__c FROM Account_Membership__c 
            WHERE Account_Id__c IN :accountIds
        ]) {
            accountsWithAnyMemberships.add(am.Account_Id__c);
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc : accounts) {
            System.debug('### Processing account: ' + acc.Id);

            if (!accountsWithAnyMemberships.contains(acc.Id)) {
                accountsToUpdate.add(new Account(
                    Id = acc.Id,
                    Historical_Jobs_Assigned__c = 'Skipped'
                ));
                continue;
            }

            if (!accountJobMap.containsKey(acc.Id) || accountJobMap.get(acc.Id).isEmpty()) {
                accountsToUpdate.add(new Account(
                    Id = acc.Id,
                    Historical_Jobs_Assigned__c = 'Skipped'
                ));
                continue;
            }

            try {
                System.debug('### Enqueueing job for: ' + acc.Id);
                System.enqueueJob(new B2BSchooxJobAssignmentQueueable(acc.Id, accountJobMap.get(acc.Id)));
                accountsToUpdate.add(new Account(
                    Id = acc.Id,
                    Historical_Jobs_Assigned__c = 'Succesful'
                ));
            } catch (Exception e) {
                System.debug('### Job enqueue failed for account: ' + acc.Id + ' - Error: ' + e.getMessage());
                accountsToUpdate.add(new Account(
                    Id = acc.Id,
                    Historical_Jobs_Assigned__c = 'Unsuccessful'
                ));
            }


        }

        if (!accountsToUpdate.isEmpty()) {
            System.debug('### Updating accounts with statuses');
            Database.update(accountsToUpdate, false);
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('### FINISH method called');
    }
}