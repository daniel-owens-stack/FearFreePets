global class BatchSyncActiveMembersToSchoox implements Database.Batchable<SObject>, Database.AllowsCallouts {

    // Membership Id to Schoox Job Id map
    private Map<Id, Integer> membershipToJobId;

    // Constructor to accept default mapping
    public BatchSyncActiveMembersToSchoox() {
        membershipToJobId = new Map<Id, Integer>{
            'a04TR00000GtVQEYA3' => 1957821,
            'a04TR00000GtVQFYA3' => 1957823,
            'a04TR00000GtVQGYA3' => 1957822,
            'a04TR00000GtVQDYA3' => 1957825,
            'a04TR00000GtVQCYA3' => 1937025,
            'a04TR00000GtVQIYA3' => 1957820,
            'a04TR00000GtVQJYA3' => 2213608,
            'a04TR00000GtVQKYA3' => 2213609
        };
    }

    // Overloaded constructor for testing
    public BatchSyncActiveMembersToSchoox(Map<Id, Integer> customMap) {
        membershipToJobId = customMap;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, SX_User_Synced__c,
                (SELECT Id, Membership__c
                 FROM Account_Memberships__r
                 WHERE Status__c = 'Active')
            FROM Account
            WHERE IsPersonAccount = true
              AND PersonEmail != null
              AND SX_User_Synced__c = false
              AND Id IN (
                  SELECT Account_Id__c
                  FROM Account_Membership__c
                  WHERE Status__c = 'Active'
              )
            LIMIT 1000
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Account> accounts = (List<Account>)scope;
        List<Account> toUpdate = new List<Account>();

        for (Account acct : accounts) {
            Set<Integer> jobIds = new Set<Integer>();

            if (acct.Account_Memberships__r != null) {
                for (Account_Membership__c am : acct.Account_Memberships__r) {
                    if (am.Membership__c != null && membershipToJobId.containsKey(am.Membership__c)) {
                        jobIds.add(membershipToJobId.get(am.Membership__c));
                    }
                }
            }

            if (!jobIds.isEmpty()) {
                System.enqueueJob(new FFGetUserCourseWrapper.LMSUserQueueable(acct.Id, new List<Integer>(jobIds)));
                acct.SX_User_Synced__c = true;
                toUpdate.add(acct);
            } else {
                System.debug('No matching Membership__c found for account: ' + acct.Id);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('BatchSyncActiveMembersToSchoox finished.');
    }
}