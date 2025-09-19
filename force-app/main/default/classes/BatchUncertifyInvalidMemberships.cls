global class BatchUncertifyInvalidMemberships implements Database.Batchable<SObject>, Database.Stateful {

    global Integer updatedCount = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Only look at Certified records
        String query = 'SELECT Id, Account_Id__c, Membership__c ' +
                       'FROM Account_Membership__c ' +
                       'WHERE Certified__c = true AND Status__c = \'Active\'';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Account_Membership__c> scope) {
        Map<String, Account_Membership__c> amMap = new Map<String, Account_Membership__c>();
        Set<String> keys = new Set<String>();
        Set<Id> membershipIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        for (Account_Membership__c am : scope) {
            if (am.Account_Id__c != null && am.Membership__c != null) {
                String key = am.Account_Id__c + '-' + am.Membership__c;
                keys.add(key);
                amMap.put(key, am);
                membershipIds.add(am.Membership__c);
                accountIds.add(am.Account_Id__c);
            }
        }

        // Link memberships → courses
        Map<Id, Id> membershipToCourse = new Map<Id, Id>();
        for (Certification_Course__c cc : [
            SELECT Membership__c, SX_Course__c
            FROM Certification_Course__c
            WHERE Membership__c IN :membershipIds
              AND SX_Course__c != null
        ]) {
            membershipToCourse.put(cc.Membership__c, cc.SX_Course__c);
        }

        // Reverse map: courseId → Set of membershipIds
        Map<Id, Set<Id>> courseToMemberships = new Map<Id, Set<Id>>();
        for (Id memId : membershipToCourse.keySet()) {
            Id courseId = membershipToCourse.get(memId);
            if (!courseToMemberships.containsKey(courseId)) {
                courseToMemberships.put(courseId, new Set<Id>());
            }
            courseToMemberships.get(courseId).add(memId);
        }

        // Gather keys that truly have completions
        Set<String> validKeys = new Set<String>();
        for (SX_Enrollment__c enroll : [
            SELECT Student_ID__r.SF_Contact__r.AccountId, SX_Course__c, SX_percent_Completed__c
            FROM SX_Enrollment__c
            WHERE SX_percent_Completed__c = 100
              AND SX_Course__c IN :courseToMemberships.keySet()
              AND Student_ID__r.SF_Contact__r.AccountId IN :accountIds
        ]) {
            Set<Id> memIds = courseToMemberships.get(enroll.SX_Course__c);
            if (memIds != null) {
                for (Id memId : memIds) {
                    String key = enroll.Student_ID__r.SF_Contact__r.AccountId + '-' + memId;
                    validKeys.add(key);
                }
            }
        }

        // Any certified record whose key is NOT in validKeys → should be flipped to false
        List<Account_Membership__c> toUpdate = new List<Account_Membership__c>();
        for (String key : keys) {
            if (!validKeys.contains(key)) {
                Account_Membership__c am = amMap.get(key);
                am.Certified__c = false;
                toUpdate.add(am);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
            updatedCount += toUpdate.size();
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('BatchUncertifyInvalidMemberships finished. Total records uncertified: ' + updatedCount);
    }
}