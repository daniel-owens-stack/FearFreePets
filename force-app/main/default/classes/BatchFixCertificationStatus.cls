global class BatchFixCertificationStatus implements Database.Batchable<SObject>, Database.Stateful {
    
    global Integer updatedCount = 0;
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Basic query: non-certified, active Account_Membership__c
        String query = 'SELECT Id, Account_Id__c, Membership__c FROM Account_Membership__c WHERE Certified__c = false AND Status__c = \'Active\'';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Account_Membership__c> scope) {
        // Key = "<AccountId>-<MembershipId>"
        Map<String, Account_Membership__c> amMap = new Map<String, Account_Membership__c>();
        Set<String> keys = new Set<String>();
        Set<Id> membershipIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        
        // Collect initial data and build key map
        for (Account_Membership__c am : scope) {
            if (am.Account_Id__c != null && am.Membership__c != null) {
                String key = am.Account_Id__c + '-' + am.Membership__c;
                keys.add(key);
                amMap.put(key, am);
                membershipIds.add(am.Membership__c);
                accountIds.add(am.Account_Id__c);
            }
        }
        if (keys.isEmpty()) return;
        
        // Already-certified (skip)
        Set<String> certifiedKeys = new Set<String>();
        for (Account_Membership__c am : [
        SELECT Account_Id__c, Membership__c
        FROM Account_Membership__c
        WHERE Certified__c = true
          AND Status__c = 'Active'
          AND Account_Id__c IN :accountIds
          AND Membership__c IN :membershipIds
    ]) {
            certifiedKeys.add(am.Account_Id__c + '-' + am.Membership__c);
        }
        
        // ---- Support MULTIPLE courses per membership ----
        // membership -> set(course)
        Map<Id, Set<Id>> membershipToCourses = new Map<Id, Set<Id>>();
        for (Certification_Course__c cc : [
        SELECT Membership__c, SX_Course__c
        FROM Certification_Course__c
        WHERE Membership__c IN :membershipIds
          AND SX_Course__c != null
    ]) {
            if (!membershipToCourses.containsKey(cc.Membership__c)) {
                membershipToCourses.put(cc.Membership__c, new Set<Id>());
            }
            membershipToCourses.get(cc.Membership__c).add(cc.SX_Course__c);
        }
        
        // course -> set(membership) reverse map
        Map<Id, Set<Id>> courseToMemberships = new Map<Id, Set<Id>>();
        for (Id memId : membershipToCourses.keySet()) {
            for (Id courseId : membershipToCourses.get(memId)) {
                if (!courseToMemberships.containsKey(courseId)) {
                    courseToMemberships.put(courseId, new Set<Id>());
                }
                courseToMemberships.get(courseId).add(memId);
            }
        }
        if (courseToMemberships.isEmpty()) return;
        
        // Completions (>= 100) – match via either Student link or Contact lookup
        Set<String> completedKeys = new Set<String>();
        for (SX_Enrollment__c enroll : [
        SELECT SX_Course__c,
               SX_percent_Completed__c,
               SF_Contact_Lookup__r.AccountId,
               Student_ID__r.SF_Contact__r.AccountId
        FROM SX_Enrollment__c
        WHERE SX_percent_Completed__c >= 100
          AND SX_Course__c IN :courseToMemberships.keySet()
          AND (
                SF_Contact_Lookup__r.AccountId IN :accountIds
             OR Student_ID__r.SF_Contact__r.AccountId IN :accountIds
          )
    ]) {
            Id acctId =
                (enroll.SF_Contact_Lookup__r != null && enroll.SF_Contact_Lookup__r.AccountId != null)
                ? enroll.SF_Contact_Lookup__r.AccountId
                : (enroll.Student_ID__r != null && enroll.Student_ID__r.SF_Contact__r != null
                ? enroll.Student_ID__r.SF_Contact__r.AccountId
                : null);
            
            if (acctId == null) continue;
            
            Set<Id> memIds = courseToMemberships.get(enroll.SX_Course__c);
            if (memIds != null) {
                for (Id memId : memIds) {
                    completedKeys.add(acctId + '-' + memId);
                }
            }
        }
        
        // Determine updates
        List<Account_Membership__c> toUpdate = new List<Account_Membership__c>();
        for (String key : keys) {
            if (!certifiedKeys.contains(key) && completedKeys.contains(key)) {
                Account_Membership__c am = amMap.get(key);
                am.Certified__c = true;
                toUpdate.add(am);
            }
        }
        
        if (!toUpdate.isEmpty()) {
            update toUpdate;
            updatedCount += toUpdate.size();
        }
    }
    
    
    global void finish(Database.BatchableContext bc) {
        System.debug('BatchFixCertificationStatus finished. Total Account_Membership__c updated: ' + updatedCount);
        // Optional: send notification or log
    }
}