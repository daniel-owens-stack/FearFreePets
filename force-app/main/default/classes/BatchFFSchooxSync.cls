public with sharing class BatchFFSchooxSync
implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    
    private final List<Id> seedAccountIds;
    public BatchFFSchooxSync(List<Id> seedAccountIds) {
        this.seedAccountIds = (seedAccountIds == null) ? new List<Id>() : seedAccountIds;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (!seedAccountIds.isEmpty()) {
            return Database.getQueryLocator([
                SELECT Id, IsPersonAccount, PersonContactId
                FROM Account
                WHERE Id IN :seedAccountIds
            ]);
        }
        return Database.getQueryLocator([
            SELECT Id, Name, PersonContactId, IsPersonAccount
            FROM Account
            WHERE IsPersonAccount = true
            AND PersonContactId != null
            AND PersonEmail != Null
            AND Original_System_ID__c != null
            AND PersonContactId NOT IN (
                SELECT SF_Contact_Lookup__c
                FROM SX_Enrollment__c
                WHERE SF_Contact_Lookup__c != null
            )
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // Cast safely to Accounts
        List<Account> accounts = new List<Account>(scope.size());
        for (SObject sob : scope) {
            if (sob == null || !(sob instanceof Account)) continue;
            accounts.add((Account)sob);
        }
        if (accounts.isEmpty()) return;
        
        // Collect ids for this chunk
        Set<Id> paIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for (Account a : accounts) {
            if (a != null && a.IsPersonAccount && a.PersonContactId != null) {
                paIds.add(a.Id);
                contactIds.add(a.PersonContactId);
            }
        }
        if (contactIds.isEmpty()) return;
        
        // ---------- Preload (SOQL only) ----------
        Map<Id, Contact> contacts = new Map<Id, Contact>([
        SELECT Id, Email, FirstName, LastName,
               SX_User_Id__c, SX_Active_User__c, SX_LMS_User__c,
               SX_Job_Lookup__r.SX_Job_ID__c,
               Account.SX_Unit_Lookup__r.SX_ID__c,
               Account.SX_Above_Unit_Lookup__r.SX_ID__c
        FROM Contact
        WHERE Id IN :contactIds
    ]);
        
        Map<Id, SX_LMS_User__c> existingLmsByContact = new Map<Id, SX_LMS_User__c>();
        for (SX_LMS_User__c l : [
        SELECT Id, SX_User_ID__c, SX_Active_User__c, SF_Contact__c
        FROM SX_LMS_User__c
        WHERE SF_Contact__c IN :contactIds
    ]) {
            existingLmsByContact.put(l.SF_Contact__c, l);
        }
        
        Map<Id, List<Integer>> jobIdsByAccount = FFGetSchooxJobIds.getForAccounts(paIds);
        if (jobIdsByAccount == null) jobIdsByAccount = new Map<Id, List<Integer>>();
        
        // ---------- PHASE A — CALLOUTS ONLY ----------
        List<SX_LMS_User__c> stagedNewLms = new List<SX_LMS_User__c>();
        Set<Id> contactsTouched = new Set<Id>();
        
        for (Account a : accounts) {
            if (a == null || !(a.IsPersonAccount && a.PersonContactId != null)) continue;
            
            Id cId = a.PersonContactId;
            Contact c = contacts.get(cId);
            if (c == null) continue;
            
            List<Integer> jobIds = jobIdsByAccount.get(a.Id);
            
            if (String.isBlank(c.SX_User_Id__c)) {
                // --- CREATE path ---
                try {
                    SX_LMS_User__c created = SchooxAPI.createLMSUser(cId, jobIds);
                    if (created != null) {
                        created.SF_Contact__c = cId;
                        if (created.RecordTypeId == null) {
                            created.RecordTypeId = Schema.SObjectType.SX_LMS_User__c
                                .getRecordTypeInfosByDeveloperName()
                                .get('External').getRecordTypeId();
                        }
                        stagedNewLms.add(created);
                        contactsTouched.add(cId);
                    }
                } catch (System.CalloutException e) {
                    String msg = String.valueOf(e.getMessage()).toLowerCase();
                    if (msg != null && msg.contains('external id already exists')) {
                        // Skip this contact (do not stage or touch)
                        System.debug(LoggingLevel.WARN,
                        'Skipping contact ' + cId + ' — LMS user already exists remotely.');
                    } else {
                        // Log other callout failures and continue
                        System.debug(LoggingLevel.ERROR,
                        'Create LMS user failed for ' + cId + ': ' + e.getMessage());
                    }
                } catch (Exception e) {
                    System.debug('Create LMS user failed for ' + cId + ': ' + e.getMessage());
                }
            } else {
                // --- UPDATE path ---
                try {
                    SchooxAPI.reActivateLMSUser(c.SX_User_Id__c);
                    SchooxAPI.updateLMSUser(cId, jobIds);
                    contactsTouched.add(cId);
                } catch (Exception e) {
                    System.debug('Update/reactivate failed for Contact ' + cId + ': ' + e.getMessage());
                }
            }
        }
        
        // ---------- PHASE B — DML ONLY ----------
        // 1) Insert newly created LMS users
        if (!stagedNewLms.isEmpty()) insert stagedNewLms;
        
        // 2) Update Contacts with LMS linkage/flags
        Map<Id, SX_LMS_User__c> newLmsByContact = new Map<Id, SX_LMS_User__c>();
        for (SX_LMS_User__c nl : stagedNewLms)
            if (nl.SF_Contact__c != null) newLmsByContact.put(nl.SF_Contact__c, nl);
        
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Id cId : contactsTouched) {
            Contact orig = contacts.get(cId);
            if (orig == null) continue;
            
            SX_LMS_User__c lms = existingLmsByContact.get(cId);
            if (lms == null) lms = newLmsByContact.get(cId);
            if (lms == null) continue;
            
            Contact upd = new Contact(Id = cId);
            if (String.isBlank(orig.SX_User_Id__c) && String.isNotBlank(lms.SX_User_ID__c)) {
                upd.SX_User_Id__c = lms.SX_User_ID__c;
            }
            if (orig.SX_Active_User__c != lms.SX_Active_User__c) {
                upd.SX_Active_User__c = lms.SX_Active_User__c;
            }
            try { upd.put('SX_LMS_User__c', lms.Id); } catch (Exception ignore) {}
            contactsToUpdate.add(upd);
        }
        if (!contactsToUpdate.isEmpty()) update contactsToUpdate;
        
        // 3) Flag LMS users for enrollments
        Datetime dueAt = Datetime.now().addHours(1);
        List<SX_LMS_User__c> lmsToFlag = new List<SX_LMS_User__c>();
        for (SX_LMS_User__c ex : existingLmsByContact.values()) {
            if (ex.Id != null && contactsTouched.contains(ex.SF_Contact__c)) {
                lmsToFlag.add(new SX_LMS_User__c(
                    Id = ex.Id,
                SX_Process_Pending__c = true,
                Enrollments_Due_At__c = dueAt
                    ));
            }
        }
        for (SX_LMS_User__c nl : stagedNewLms) {
            lmsToFlag.add(new SX_LMS_User__c(
                Id = nl.Id,
            SX_Process_Pending__c = true,
            Enrollments_Due_At__c = dueAt
                ));
        }
        if (!lmsToFlag.isEmpty()) update lmsToFlag;
    }
    
    public void finish(Database.BatchableContext bc) { }
}