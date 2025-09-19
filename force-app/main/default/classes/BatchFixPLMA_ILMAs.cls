global with sharing class BatchFixPLMA_ILMAs
    implements Database.Batchable<SObject>, Database.Stateful {

    // Tracks (BusinessId-MembershipId) pairs already processed across scopes
    private Set<String> processedKeys;

    public BatchFixPLMA_ILMAs() {
        processedKeys = new Set<String>();
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id,
                   Business_Account__c,
                   Membership__c,
                   Expiration_Date__c,
                   Status__c,
                   Start_Date__c
            FROM Practice_Level_Membership_Assignment__c
            WHERE Status__c = 'Active'
              AND Business_Account__c != null
              AND Membership__c != null
            ORDER BY Business_Account__c,
                     Membership__c,
                     Expiration_Date__c DESC,
                     Start_Date__c DESC,
                     LastModifiedDate DESC
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Practice_Level_Membership_Assignment__c> scope) {
        // Step 1: pick the first (latest) PLMA per key, skipping keys handled in prior scopes
        Map<String, Practice_Level_Membership_Assignment__c> latestPLMAs = new Map<String, Practice_Level_Membership_Assignment__c>();
        for (Practice_Level_Membership_Assignment__c plma : scope) {
            String key = plma.Business_Account__c + '-' + plma.Membership__c;
            if (processedKeys.contains(key)) continue; // already done in a previous scope
            if (!latestPLMAs.containsKey(key)) {
                latestPLMAs.put(key, plma);  // first seen here is latest due to ORDER BY
                processedKeys.add(key);      // prevent older ones (later scopes) from overriding
            }
        }
        if (latestPLMAs.isEmpty()) return;

        // Step 2: Collect members for those businesses
        Set<Id> businessIds = new Set<Id>();
        for (Practice_Level_Membership_Assignment__c plma : latestPLMAs.values()) {
            businessIds.add(plma.Business_Account__c);
        }

        Map<Id, List<Account>> businessToMembers = new Map<Id, List<Account>>();
        List<Account> allMembers = [
            SELECT Id, Business__c
            FROM Account
            WHERE IsPersonAccount = true
              AND Business__c IN :businessIds
        ];
        for (Account pa : allMembers) {
            if (!businessToMembers.containsKey(pa.Business__c)) {
                businessToMembers.put(pa.Business__c, new List<Account>());
            }
            businessToMembers.get(pa.Business__c).add(pa);
        }

        // Step 3: Collect (memberId, membershipId) pairs
        Set<Id> memberIds = new Set<Id>();
        Set<Id> membershipIds = new Set<Id>();
        for (Practice_Level_Membership_Assignment__c plma : latestPLMAs.values()) {
            List<Account> members = businessToMembers.get(plma.Business_Account__c);
            if (members == null) continue;
            for (Account member : members) {
                memberIds.add(member.Id);
                membershipIds.add(plma.Membership__c);
            }
        }
        if (memberIds.isEmpty()) return;

        // Step 4: Query existing **Active** ILMAs (ignore canceled/expired → no resurrection)
        Map<String, Account_Membership__c> existingMap = new Map<String, Account_Membership__c>();
        for (Account_Membership__c ilma : [
            SELECT Id, Account_Id__c, Membership__c, Practice_Level_Membership_Assignment__c, Status__c
            FROM Account_Membership__c
            WHERE Account_Id__c IN :memberIds
              AND Membership__c IN :membershipIds
              AND Status__c = 'Active'
        ]) {
            String k = ilma.Account_Id__c + '-' + ilma.Membership__c;
            existingMap.put(k, ilma);
        }

        // Step 5: Insert/update as needed
        List<Account_Membership__c> toInsert = new List<Account_Membership__c>();
        List<Account_Membership__c> toUpdate = new List<Account_Membership__c>();

        for (Practice_Level_Membership_Assignment__c plma : latestPLMAs.values()) {
            List<Account> members = businessToMembers.get(plma.Business_Account__c);
            if (members == null) continue;

            for (Account member : members) {
                String k = member.Id + '-' + plma.Membership__c;
                Account_Membership__c existing = existingMap.get(k);

                if (existing == null) {
                    // Create new ILMA
                    toInsert.add(new Account_Membership__c(
                        Account_Id__c = member.Id,
                        Membership__c = plma.Membership__c,
                        Status__c = plma.Status__c, // Active
                        Account_Assignment_Date__c = plma.Start_Date__c,
                        Parent_Id__c = plma.Business_Account__c,
                        Purchaser_Account__c = plma.Business_Account__c,
                        Practice_Level_Membership_Assignment__c = plma.Id
                    ));
                } else {
                    // Update existing Active ILMA to point at the chosen (latest) PLMA
                    existing.Practice_Level_Membership_Assignment__c = plma.Id;
                    existing.Status__c = plma.Status__c; // keep in sync
                    existing.Account_Assignment_Date__c = plma.Start_Date__c;
                    existing.Parent_Id__c = plma.Business_Account__c;
                    // If you want Purchaser kept in sync on update, uncomment:
                    // existing.Purchaser_Account__c = plma.Business_Account__c;
                    toUpdate.add(existing);
                }
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('BatchFixPLMA_ILMAs completed. Job Id = ' + bc.getJobId());
    }
}