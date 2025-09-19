public class B2BCreateHistoricalPLMABatch implements Database.Batchable<SObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Membership__c, Start_Date__c, Account_Id__r.Business__c, 
                   Practice_Level_Membership_Assignment__c
            FROM Account_Membership__c
            WHERE Membership__r.Membership_Level__c = 'Practice'
            AND Status__c = 'Active'
            AND Account_Id__r.Business__c != null
        ]);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Account_Membership__c> ilmAs = (List<Account_Membership__c>)scope;

        Set<String> businessMembershipKeys = new Set<String>();
        Map<String, List<Account_Membership__c>> keyToIlmas = new Map<String, List<Account_Membership__c>>();

        for (Account_Membership__c am : ilmAs) {
            String key = am.Account_Id__r.Business__c + '_' + am.Membership__c;
            businessMembershipKeys.add(key);
            if (!keyToIlmas.containsKey(key)) {
                keyToIlmas.put(key, new List<Account_Membership__c>());
            }
            keyToIlmas.get(key).add(am);
        }

        Map<String, Practice_Level_Membership_Assignment__c> existingPlmas = new Map<String, Practice_Level_Membership_Assignment__c>();
        List<Practice_Level_Membership_Assignment__c> existing = [
            SELECT Id, Business_Account__c, Membership__c
            FROM Practice_Level_Membership_Assignment__c
            WHERE Business_Account__c != null AND Membership__c != null
        ];
        for (Practice_Level_Membership_Assignment__c plma : existing) {
            String key = plma.Business_Account__c + '_' + plma.Membership__c;
            if (businessMembershipKeys.contains(key)) {
                existingPlmas.put(key, plma);
            }
        }

        List<Practice_Level_Membership_Assignment__c> toInsert = new List<Practice_Level_Membership_Assignment__c>();
        Map<String, Practice_Level_Membership_Assignment__c> newPlmas = new Map<String, Practice_Level_Membership_Assignment__c>();

        for (String key : businessMembershipKeys) {
            if (!existingPlmas.containsKey(key)) {
                Account_Membership__c sampleIlma = keyToIlmas.get(key)[0];
                Practice_Level_Membership_Assignment__c newPlma = new Practice_Level_Membership_Assignment__c(
                    Membership__c = sampleIlma.Membership__c,
                    Start_Date__c = sampleIlma.Start_Date__c,
                    Business_Account__c = sampleIlma.Account_Id__r.Business__c,
                    Status__c = 'Active',
                    Welcome_Kit_Status__c = 'Unavailable',
                    Need_Historical_Review__c = true
                );
                toInsert.add(newPlma);
                newPlmas.put(key, newPlma);
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
            for (Practice_Level_Membership_Assignment__c plma : toInsert) {
                String key = plma.Business_Account__c + '_' + plma.Membership__c;
                existingPlmas.put(key, plma);
            }
        }

        List<Account_Membership__c> ilmAsToUpdate = new List<Account_Membership__c>();
        for (Account_Membership__c am : ilmAs) {
            String key = am.Account_Id__r.Business__c + '_' + am.Membership__c;
            if (existingPlmas.containsKey(key)) {
                Practice_Level_Membership_Assignment__c plma = existingPlmas.get(key);
                if (am.Practice_Level_Membership_Assignment__c != plma.Id) {
                    am.Practice_Level_Membership_Assignment__c = plma.Id;
                    ilmAsToUpdate.add(am);
                }
            }
        }

        if (!ilmAsToUpdate.isEmpty()) {
            update ilmAsToUpdate;
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('B2BCreateHistoricalPLMABatch completed successfully.');
    }
}