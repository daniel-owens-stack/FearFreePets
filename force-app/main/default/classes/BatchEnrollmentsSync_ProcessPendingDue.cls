public with sharing class BatchEnrollmentsSync_ProcessPendingDue
implements Database.Batchable<SObject>, Database.AllowsCallouts {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, SX_User_ID__c, SF_Contact__c, SF_Contact__r.AccountId,
                   SX_Process_Pending__c, Enrollments_Due_At__c, SX_Active_User__c
            FROM SX_LMS_User__c
            WHERE SX_Process_Pending__c = true
              AND Enrollments_Due_At__c <= :Datetime.now()
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<SX_LMS_User__c> users = (List<SX_LMS_User__c>)scope;
        
        // -------------------- 1) CALLOUTS: fetch enrollments (no DML) --------------------
        List<SX_Enrollment__c> enrollmentsToUpsert = new List<SX_Enrollment__c>();
        for (SX_LMS_User__c lmsUser : users) {
            if (String.isBlank(lmsUser.SX_User_ID__c)) continue;
            try {
                // Callout + parse (no DML inside these helpers)
                List<SX_Enrollment__c> parsed = SchooxAPI.getUserCourseWithoutUpsert(lmsUser.SX_User_ID__c);
                if (!parsed.isEmpty()) {
                    for (SX_Enrollment__c e : parsed) {
                        e.Student_ID__c = lmsUser.Id;
                    }
                    enrollmentsToUpsert.addAll(parsed);
                }
            } catch (Exception e) {
                System.debug('Fetch error for ' + lmsUser.SX_User_ID__c + ': ' + e.getMessage());
            }
        }
        
        // -------------------- 2) CALLOUTS: optional removal (still no DML yet) --------------------
        // Bulkify: count active memberships by contact once
        Set<Id> accIds = new Set<Id>();
        for (SX_LMS_User__c u : users) if (u.SF_Contact__c != null) accIds.add(u.SF_Contact__r.AccountId);
        
        Map<Id, Integer> activeCountByContact = new Map<Id, Integer>();
        if (!accIds.isEmpty()) {
            for (AggregateResult ar : [
                SELECT Account_Id__c acct, COUNT(Id) cnt
                FROM Account_Membership__c
                WHERE Account_Id__c IN :accIds
                  AND Status__c = 'Active'
                GROUP BY Account_Id__c
            ]) {
                activeCountByContact.put((Id)ar.get('acct'), (Integer)ar.get('cnt'));
            }
        }
        
        List<Contact> contactsToUpdate = new List<Contact>();
        for (SX_LMS_User__c lmsUser : users) {
            try {
                if (lmsUser.SF_Contact__c != null) {
                    Integer c = activeCountByContact.get(lmsUser.SF_Contact__r.AccountId);
                    if (c == null || c == 0) {
                        // callout is still safe here — we've done no DML yet
                        SchooxAPI.removeLMSUser(lmsUser.SX_User_ID__c);
                    } else {
                        lmsUser.SX_Active_User__c = true;
                        Contact con = [SELECT Id, SX_Active_User__c FROM Contact WHERE Id = :lmsUser.SF_Contact__c LIMIT 1];
                        con.SX_Active_User__c = true;
                        contactsToUpdate.add(con);
                    }
                }
            } catch (Exception e) {
                System.debug('Removal error for ' + lmsUser.SX_User_ID__c + ': ' + e.getMessage());
            }
        }
        
        // -------------------- 3) DML: after ALL callouts --------------------
        try {
            if (!enrollmentsToUpsert.isEmpty()) {
                // If Student_Course_Id__c is External ID/Unique, this is idempotent
                Database.UpsertResult[] res = Database.upsert(enrollmentsToUpsert, SX_Enrollment__c.Fields.Student_Course_Id__c, /*allOrNone*/ false);
                for (Integer i = 0; i < res.size(); i++) {
                    if (!res[i].isSuccess()) {
                        for (Database.Error err : res[i].getErrors()) {
                            System.debug('Enrollment upsert failed: ' + err.getStatusCode() + ' - ' + err.getMessage());
                        }
                    }
                }
            }
        } catch (DmlException dmle) {
            System.debug('Enrollment upsert error: ' + dmle.getMessage());
        }
        
        // Clear flags on SX_LMS_User__c
        for (SX_LMS_User__c lmsUser : users) {
            lmsUser.SX_Process_Pending__c = false;
            lmsUser.Enrollments_Due_At__c = null;
        }
        update users;
        update contactsToUpdate;
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('BatchEnrollmentsSync_ProcessPendingDue finished.');
    }
}