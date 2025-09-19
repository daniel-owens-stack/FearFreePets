public with sharing class FFSchooxSyncController {
    
    // Map Membership__c Id -> Schoox Job Id
    @TestVisible
    private static Map<Id, Integer> membershipToJobId = new Map<Id, Integer>{
        'a04TR00000GtVQEYA3' => 1957821,
        'a04TR00000GtVQFYA3' => 1957823,
        'a04TR00000GtVQGYA3' => 1957822,
        'a04TR00000GtVQDYA3' => 1957825,
        'a04TR00000GtVQCYA3' => 1937025,
        'a04TR00000GtVQIYA3' => 2213608,
        'a04TR00000GtVQJYA3' => 2224301,
        'a04TR00000GtVQKYA3' => 2213609
    };
    
    @TestVisible private static Map<Id, Integer> testOverrideMap;
    
    // Add this setter once
    @TestVisible
    public static void setTestMembershipToJobId(Map<Id,Integer> m) {
        testOverrideMap = m;
    }
    
    // Safe accessor (used by batches or other classes)
    public static Map<Id, Integer> getMembershipToJobId() {
        return new Map<Id, Integer>(membershipToJobId);
    }
    
    // Process a single Account from UI (person or business)
    @AuraEnabled
    public static void runSync(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('Account Id is required.');
        }
        
        Account root = [
            SELECT Id, IsPersonAccount
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        
        // Resolve target Person Accounts (self if PA, or children if business)
        List<Account> targetAccounts = root.IsPersonAccount
            ? [SELECT Id, PersonContactId FROM Account WHERE Id = :root.Id]
            : [SELECT Id, PersonContactId
               FROM Account
               WHERE IsPersonAccount = true
                 AND Business__c = :root.Id
                 AND PersonEmail != null];
        
        if (targetAccounts.isEmpty()) {
            throw new AuraHandledException('No valid Person Accounts found.');
        }
        
        // Build helper maps
        Set<Id> personAccountIds = new Map<Id, Account>(targetAccounts).keySet();
        
        Map<Id, Id> accountToContactId = new Map<Id, Id>();
        for (Account a : targetAccounts) {
            if (a.PersonContactId != null) accountToContactId.put(a.Id, a.PersonContactId);
        }
        
        // Active memberships → job ids per Account
        Map<Id, Set<Integer>> accountToJobIds = new Map<Id, Set<Integer>>();
        for (Account_Membership__c am : [
            SELECT Account_Id__c, Membership__c, Status__c
            FROM Account_Membership__c
            WHERE Account_Id__c IN :personAccountIds
        ]) {
            if (am.Status__c == 'Active' && membershipToJobId.containsKey(am.Membership__c)) {
                if (!accountToJobIds.containsKey(am.Account_Id__c)) {
                    accountToJobIds.put(am.Account_Id__c, new Set<Integer>());
                }
                accountToJobIds.get(am.Account_Id__c).add(membershipToJobId.get(am.Membership__c));
            }
        }
        
        // Existing LMS users by Account
        Map<Id, SX_LMS_User__c> accountToLms = new Map<Id, SX_LMS_User__c>();
        for (SX_LMS_User__c u : [
            SELECT Id, SF_Contact__r.AccountId, SF_Contact__c, SX_User_ID__c,
                   SX_Process_Pending__c, Enrollments_Due_At__c
            FROM SX_LMS_User__c
            WHERE SF_Contact__c IN :accountToContactId.values()
        ]) {
            if (u.SF_Contact__r != null) accountToLms.put(u.SF_Contact__r.AccountId, u);
        }
        
        List<SX_LMS_User__c> toUpdateFlags = new List<SX_LMS_User__c>();
        
        // For each target PA: create/update LMS user via SchooxAPI, then flag +1h
        for (Id accId : personAccountIds) {
            List<Integer> jobIds = accountToJobIds.containsKey(accId)
                ? new List<Integer>(accountToJobIds.get(accId))
                : null;
            
            SX_LMS_User__c lmsUser = accountToLms.get(accId);
            
            if (lmsUser == null) {
                // Create in Schoox + local record (callout + DML done inside SchooxAPI.handleLMSUser)
                lmsUser = SchooxAPI.handleLMSUser(accId, jobIds);
                if (lmsUser == null) {
                    // If API returns null, re-query by contact to obtain the record for flagging
                    Id contactId = accountToContactId.get(accId);
                    if (contactId != null) {
                        List<SX_LMS_User__c> created = [
                            SELECT Id, SX_User_ID__c
                            FROM SX_LMS_User__c
                            WHERE SF_Contact__c = :contactId
                            LIMIT 1
                        ];
                        if (!created.isEmpty()) lmsUser = created[0];
                    }
                }
            } else {
                // Update/reactivate in Schoox (two callouts inline inside SchooxAPI)
                SchooxAPI.updateAndReactivateLMSUser(accId, jobIds);
                
                // Ensure fresh copy for flagging
                lmsUser = [
                    SELECT Id, SX_User_ID__c
                    FROM SX_LMS_User__c
                    WHERE Id = :lmsUser.Id
                ];
            }
            
            if (lmsUser != null && !String.isBlank(lmsUser.SX_User_ID__c)) {
                lmsUser.SX_Process_Pending__c = true;
                lmsUser.Enrollments_Due_At__c = Datetime.now().addHours(1);
                toUpdateFlags.add(lmsUser);
            } else {
                System.debug('Warning: No LMS user for Account ' + accId);
            }
        }
        
        if (!toUpdateFlags.isEmpty()) {
            update toUpdateFlags;
        }
    }
}