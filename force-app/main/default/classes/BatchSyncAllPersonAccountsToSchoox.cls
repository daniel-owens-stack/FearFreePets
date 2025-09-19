global class BatchSyncAllPersonAccountsToSchoox 
    implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
        
        private Map<Id, Integer> membershipToJobId;
        List<Account> accountsToUpdateSyncStatus = new List<Account>();
        
        public BatchSyncAllPersonAccountsToSchoox() {
            membershipToJobId = new Map<Id, Integer>{
                'a04TR00000GtVQEYA3' => 1957821,
                'a04TR00000GtVQFYA3' => 1957823,
                'a04TR00000GtVQGYA3' => 1957822,
                'a04TR00000GtVQDYA3' => 1957825,
                'a04TR00000GtVQCYA3' => 1937025,
                'a04TR00000GtVQIYA3' => 2213608,
                'a04TR00000GtVQJYA3' => 1957820,
                'a04TR00000GtVQKYA3' => 2213609
            };
        }
        
        public BatchSyncAllPersonAccountsToSchoox(Map<Id, Integer> customMap) {
            membershipToJobId = customMap;
        }
        
        global Database.QueryLocator start(Database.BatchableContext BC) {
            return Database.getQueryLocator([
            SELECT Id,
                (SELECT Id, Membership__c, Status__c
                 FROM Account_Memberships__r
                 WHERE Status__c = 'Active'),
                PersonContactId
            FROM Account
            WHERE IsPersonAccount = true
              AND PersonEmail != null
              AND Original_System_ID__c != null
              AND SX_User_Synced__c != true
              LIMIT 5000
        ]);
        }
        
        global void execute(Database.BatchableContext BC, List<SObject> scope) {
            List<Account> accounts = (List<Account>) scope;
            List<Id> contactIds = new List<Id>();
            Map<Id, Account> accountsById = new Map<Id, Account>();
            
            for (Account acct : accounts) {
                if (acct.PersonContactId != null) {
                    contactIds.add(acct.PersonContactId);
                    accountsById.put(acct.Id, acct);
                }
            }
            
            Map<Id, Contact> contactsById = new Map<Id, Contact>(
                [SELECT Id, Email, FirstName, LastName, SX_Active_User__c, 
            SX_User_Id__c, SX_Job_Lookup__r.SX_Job_ID__c,
            Account.SX_Unit_Lookup__r.SX_ID__c,
            Account.SX_Above_Unit_Lookup__r.SX_ID__c
     FROM Contact WHERE Id IN :contactIds]
                );
            
            List<Account> accountsToUpdate = new List<Account>();
            List<Account> createLMSUserAccounts = new List<Account>();
            
            // Pass 1: Only callouts with no DML (update existing LMS users)
            for (Account acct : accounts) {
                Contact con = contactsById.get(acct.PersonContactId);
                if (con == null || String.isBlank(con.Email)) continue;
                
                Set<Integer> jobIds = new Set<Integer>();
                if (acct.Account_Memberships__r != null) {
                    for (Account_Membership__c am : acct.Account_Memberships__r) {
                        if (am.Membership__c != null && membershipToJobId.containsKey(am.Membership__c)) {
                            jobIds.add(membershipToJobId.get(am.Membership__c));
                        }
                    }
                }
                
                try {
                    if (!Test.isRunningTest()) {
                        if (!String.isBlank(con.SX_User_Id__c)) {
                            // Only callout — no DML
                            SchooxAPI.updateAndReactivateLMSUser(con.Id, jobIds.isEmpty() ? null : new List<Integer>(jobIds));
                        }
                    }
                    
                    // If LMS user already exists, mark for update
                    if (!String.isBlank(con.SX_User_Id__c)) {
                        acct.SX_User_Synced__c = true;
                        accountsToUpdate.add(acct);
                    } else {
                        // Save this for next pass (callout + DML)
                        createLMSUserAccounts.add(acct);
                    }
                    
                } catch (Exception ex) {
                    System.debug('Error in update path for ' + acct.Id + ': ' + ex.getMessage());
                }
            }
            
            // Pass 2: Do callouts for new users, then DML
            for (Account acct : createLMSUserAccounts) {
                Set<Integer> jobIds = new Set<Integer>();
                if (acct.Account_Memberships__r != null) {
                    for (Account_Membership__c am : acct.Account_Memberships__r) {
                        if (am.Membership__c != null && membershipToJobId.containsKey(am.Membership__c)) {
                            jobIds.add(membershipToJobId.get(am.Membership__c));
                        }
                    }
                }
                
                try {
                    if (!Test.isRunningTest()) {
                        // Callout that includes DML (in createLMSUser)
                        SchooxAPI.handleLMSUser(acct.Id, jobIds.isEmpty() ? null : new List<Integer>(jobIds));
                    }
                    
                    acct.SX_User_Synced__c = true;
                    accountsToUpdateSyncStatus.add(acct);
                    //accountsToUpdate.add(acct);
                    
                } catch (Exception ex) {
                    System.debug('Error in create path for ' + acct.Id + ': ' + ex.getMessage());
                }
            }
            
            // Final update
            if (!accountsToUpdate.isEmpty()) {
                for (Account acct : accountsToUpdate) {
                    Set<Integer> jobIds = new Set<Integer>();
                    if (acct.Account_Memberships__r != null) {
                        for (Account_Membership__c am : acct.Account_Memberships__r) {
                            if (am.Membership__c != null && membershipToJobId.containsKey(am.Membership__c)) {
                                jobIds.add(membershipToJobId.get(am.Membership__c));
                            }
                        }
                    }
                    
                    try {
                        if (!Test.isRunningTest()) {
                            // Callout that includes DML (in createLMSUser)
                            SchooxAPI.handleLMSUser(acct.Id, jobIds.isEmpty() ? null : new List<Integer>(jobIds));
                        }
                        
                        acct.SX_User_Synced__c = true;
                        accountsToUpdateSyncStatus.add(acct);
                        //accountsToUpdate.add(acct);
                        
                    } catch (Exception ex) {
                        System.debug('Error in create path for ' + acct.Id + ': ' + ex.getMessage());
                    }
                }
            }
    }
    
    global void finish(Database.BatchableContext BC) {
        update accountsToUpdateSyncStatus;
        System.debug('BatchSyncAllPersonAccountsToSchoox finished.');
    }
}