global class ContactToPersonAccountBatch {

    // global Database.QueryLocator start(Database.BatchableContext BC) {
    //     // Query orphan Contacts (Contacts without an associated Account)
    //     return Database.getQueryLocator([
    //         SELECT Id, FirstName, LastName, Email
    //         FROM Contact
    //         WHERE AccountId = null
    //     ]);
    // }

    // global void execute(Database.BatchableContext BC, List<Contact> orphanContacts) {
    //     List<Account> businessAccountsToInsert = new List<Account>();
    //     Map<Id, Account> contactIdToAccountMap = new Map<Id, Account>();

    //     Id businessAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
    //     Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

    //     if (businessAccountRTId == null || personAccountRTId == null) {
    //         System.debug('Error: Record Type IDs not found.');
    //         return;
    //     }

    //     // Loop through orphan Contacts and create Business Accounts
    //     for (Contact contact : orphanContacts) {
    //         // Create a new Business Account with the concatenated Name from Contact
    //         Account businessAccount = new Account(
    //             RecordTypeId = businessAccountRTId,
    //             Name = (contact.FirstName != null ? contact.FirstName + ' ' : '') + (contact.LastName != null ? contact.LastName : '')
    //         );

    //         businessAccountsToInsert.add(businessAccount);
    //         contactIdToAccountMap.put(contact.Id, businessAccount);
    //     }

    //     // Set DML options to ignore duplicate rules
    //     Database.DMLOptions dmlOpts = new Database.DMLOptions();
    //     dmlOpts.DuplicateRuleHeader.allowSave = true;
    //     dmlOpts.DuplicateRuleHeader.runAsCurrentUser = true;

    //     // Insert Business Accounts
    //     if (!businessAccountsToInsert.isEmpty()) {
    //         Database.SaveResult[] srList = Database.insert(businessAccountsToInsert, dmlOpts);

    //         // Collect IDs of successfully inserted accounts and map them to contacts
    //         List<Contact> contactsToUpdate = new List<Contact>();
    //         Set<Id> uniqueAccountIds = new Set<Id>();

    //         for (Integer i = 0; i < srList.size(); i++) {
    //             if (srList[i].isSuccess()) {
    //                 Account insertedAccount = businessAccountsToInsert[i];
    //                 insertedAccount.Id = srList[i].getId();
    //                 uniqueAccountIds.add(insertedAccount.Id);
    //                 for (Contact contact : orphanContacts) {
    //                     if (contactIdToAccountMap.get(contact.Id) == insertedAccount) {
    //                         contact.AccountId = insertedAccount.Id;
    //                         contactsToUpdate.add(contact);
    //                         break;
    //                     }
    //                 }
    //             } else {
    //                 System.debug('Failed to insert business account: ' + srList[i].getErrors()[0].getMessage());
    //             }
    //         }

    //         // Update Contacts with new AccountId
    //         if (!contactsToUpdate.isEmpty()) {
    //             Database.update(contactsToUpdate, dmlOpts);
    //         }

    //         // Convert Business Accounts to Person Accounts
    //         if (!uniqueAccountIds.isEmpty()) {
    //             AccountConversionHelper helper = new AccountConversionHelper();
    //             helper.convertToPersonAccounts(uniqueAccountIds, personAccountRTId, dmlOpts);
    //         }
    //     }
    // }

    // global void finish(Database.BatchableContext BC) {
    //     // Log completion
    //     System.debug('Batch job completed.');
    // }

    // public class AccountConversionHelper {
    //     public void convertToPersonAccounts(Set<Id> accountIds, Id personAccountRTId, Database.DMLOptions dmlOpts) {
    //         List<Account> accountsToUpdate = new List<Account>();

    //         for (Id accountId : accountIds) {
    //             Account businessAccount = new Account(
    //                 Id = accountId,
    //                 RecordTypeId = personAccountRTId
    //             );
    //             accountsToUpdate.add(businessAccount);
    //         }

    //         // Update Person Account Record Types
    //         if (!accountsToUpdate.isEmpty()) {
    //             try {
    //                 Database.SaveResult[] updateResults = Database.update(accountsToUpdate, dmlOpts);

    //                 // Handle success and failure messages for updating to Person Accounts
    //                 for (Integer j = 0; j < updateResults.size(); j++) {
    //                     if (!updateResults[j].isSuccess()) {
    //                         System.debug('Failed to update account to Person Account. Id: ' + accountsToUpdate[j].Id + ', Error: ' + updateResults[j].getErrors()[0].getMessage());
    //                     } else {
    //                         System.debug('Successfully updated account to Person Account. Id: ' + accountsToUpdate[j].Id);
    //                     }
    //                 }
    //             } catch (Exception e) {
    //                 System.debug('Exception occurred while updating accounts to Person Accounts: ' + e.getMessage());
    //             }
    //         }
    //     }
    // }
}