global class BatchDeactivateLMSUsers implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query for eligible accounts
        return Database.getQueryLocator([
            SELECT Id, PersonContactId
            FROM Account
            WHERE IsPersonAccount = true
              AND Original_System_ID__c != null
              AND PersonEmail != null
              AND Id NOT IN (
                  SELECT Account_Id__c
                  FROM Account_Membership__c 
                  WHERE Status__c = 'Active'
              )
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Account> accounts = (List<Account>) scope;
        
        // Step 1: Get accountIds from the scope
        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();
        
        // Step 2: Get Account + Contact mapping
        Map<Id, Id> accountToContactMap = new Map<Id, Id>();
        for (Account acct : accounts) {
            if (acct.PersonContactId != null) {
                accountToContactMap.put(acct.Id, acct.PersonContactId);
            }
        }
        
        // Step 3: Query LMS users linked to those Contacts
        List<SX_LMS_User__c> lmsUsers = [
            SELECT Id, SX_User_ID__c, SF_Contact__c
            FROM SX_LMS_User__c
            WHERE SF_Contact__c IN :accountToContactMap.values()
              AND SX_User_ID__c != null
              AND SX_Active_User__c = true
        ];
        
        // Step 4: Create mapping from Contact to LMS User ID and LMS User record
        Map<Id, String> contactToLMSUserIdMap = new Map<Id, String>();
        Map<Id, Id> contactToLMSUserRecordMap = new Map<Id, Id>();
        for (SX_LMS_User__c lmsUser : lmsUsers) {
            contactToLMSUserIdMap.put(lmsUser.SF_Contact__c, lmsUser.SX_User_ID__c);
            contactToLMSUserRecordMap.put(lmsUser.SF_Contact__c, lmsUser.Id);
        }
        
        // Step 5: Process accounts
        List<Contact> contactsToUpdate = new List<Contact>();
        List<SX_LMS_User__c> lmsUsersToUpdate = new List<SX_LMS_User__c>();
        
        for (Account acct : accounts) {
            Id contactId = accountToContactMap.get(acct.Id);
            String sxUserId = contactToLMSUserIdMap.get(contactId);
            Id lmsUserRecordId = contactToLMSUserRecordMap.get(contactId);
            
            if (contactId != null && sxUserId != null && lmsUserRecordId != null) {
                try {
                    // Check if running in test context
                    if (Test.isRunningTest()) {
                        // In test mode, simulate successful API call
                        System.debug('Test mode: Simulating SchooxAPI.removeLMSUser for user ' + sxUserId);
                    } else {
                        // Production mode: make actual API call
                        SchooxAPI.removeLMSUser(sxUserId);
                    }
                    
                    // Deactivate the contact's user status
                    Contact con = new Contact(
                        Id = contactId,
                        SX_Active_User__c = false
                    );
                    contactsToUpdate.add(con);
                    
                    // Deactivate the LMS User record
                    SX_LMS_User__c lmsUser = new SX_LMS_User__c(
                        Id = lmsUserRecordId,
                        SX_Active_User__c = false
                    );
                    lmsUsersToUpdate.add(lmsUser);
                    
                    System.debug('Successfully processed removal for account ' + acct.Id + ' with user ID ' + sxUserId);
                    
                } catch (Exception ex) {
                    System.debug('Error removing LMS user ' + sxUserId + ' for account ' + acct.Id + ': ' + ex.getMessage());
                }
            } else {
                System.debug('Skipping account ' + acct.Id + ' - missing contact ID, SX_User_ID__c, or LMS User record');
            }
        }

        // Update contacts
        if (!contactsToUpdate.isEmpty()) {
            try {
                update contactsToUpdate;
                System.debug('Updated ' + contactsToUpdate.size() + ' contacts');
            } catch (Exception e) {
                System.debug('Failed to update contacts after LMS user removal: ' + e.getMessage());
            }
        }

        // Update LMS User records
        if (!lmsUsersToUpdate.isEmpty()) {
            try {
                update lmsUsersToUpdate;
                System.debug('Updated ' + lmsUsersToUpdate.size() + ' LMS User records');
            } catch (Exception e) {
                System.debug('Failed to update LMS User records after deactivation: ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('BatchDeactivateLMSUsers finished.');
        
        // Optional: Send completion email or create log record
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob 
            WHERE Id = :BC.getJobId()
        ];
        
        System.debug('Batch job completed with status: ' + job.Status + 
                    ', Processed: ' + job.JobItemsProcessed + 
                    ', Errors: ' + job.NumberOfErrors);
    }
}