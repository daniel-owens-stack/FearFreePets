global with sharing class B2BProvisioningBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // return Database.getQueryLocator(
        //     'SELECT Id, Name, PersonEmail, PersonContactId, Provisioned_to_B2B_Store__c ' +
        //     'FROM Account ' +
        //     'WHERE IsPersonAccount = TRUE ' +
        //     'AND (Provisioned_to_B2B_Store__c = null OR Provisioned_to_B2B_Store__c = \'Pending\') ' +
        //     'AND RecordType.Name = \'Person Account\''
        // );

        return Database.getQueryLocator(
            'SELECT Id, Name, PersonEmail, PersonContactId, Provisioned_to_B2B_Store__c ' +
            'FROM Account ' +
            'WHERE IsPersonAccount = TRUE AND Original_System_ID__c != null AND PersonEmail != null ' +
            'AND Id NOT IN (SELECT AccountId FROM User WHERE Profile.Name = \'Fear Free Community Member\')'
        );
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        List<User> usersToInsert = new List<User>();
        List<Account> accountsToUpdate = new List<Account>();
        List<Account> failedAccounts = new List<Account>();

        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Fear Free Community Member' LIMIT 1].Id;

        // Step 1: Mark invalid records as 'Unsuccessful'
        for (Account acc : scope) {
            if (String.isBlank(acc.PersonEmail) || acc.PersonContactId == null|| Test.isRunningTest()) {
                failedAccounts.add(new Account(
                    Id = acc.Id,
                    Provisioned_to_B2B_Store__c = 'Unsuccessful'
                ));
            }
        }

        if (!failedAccounts.isEmpty()) {
            Database.SaveResult[] failedResults = Database.update(failedAccounts, false);
            for (Integer i = 0; i < failedResults.size(); i++) {
                if (!failedResults[i].isSuccess()) {
                    for (Database.Error err : failedResults[i].getErrors()) {
                        System.debug('⚠️ FailedAccount Update Error for Id: ' +
                                     failedAccounts[i].Id + ' - ' + err.getMessage());
                    }
                }
            }
        }

        // Step 2: Handle valid records
        Integer counter = 0;
        for (Account acc : scope) {
            if (String.isBlank(acc.PersonEmail) || acc.PersonContactId == null) {
                continue;
            }

            List<User> existingUsers = [
                SELECT Id FROM User WHERE ContactId = :acc.PersonContactId LIMIT 1
            ];

            if (!existingUsers.isEmpty()) {
                accountsToUpdate.add(new Account(
                    Id = acc.Id,
                    // Provisioned_to_B2B_Store__c = 'Successful'
                    Provisioned_to_B2B_Store__c = 'User Exist'
                ));
                continue;
            }

            // String timestamp = String.valueOf(DateTime.now().getTime());
            // String uniqueEmail = acc.PersonEmail.replace('@', '.' + timestamp + '@');

            // ---- CommunityNickname handling ----
            // Remove spaces
            String namePart = acc.Name.replaceAll('\\s+', '');
                
            // Space for ".ff" + counter digits
            Integer counterLength = String.valueOf(counter).length();
            Integer reservedLength = 3 + counterLength; // ".ff" length = 3
            Integer maxNameLength = 40 - reservedLength;
                
            // Truncate if needed
            if (namePart.length() > maxNameLength) {
                namePart = namePart.substring(0, maxNameLength);
            }
                
            // Build nickname
            String nickname = namePart + '.ff' + String.valueOf(counter++);
                
            // Safety check: enforce max 40 chars
            if (nickname.length() > 40) {
                nickname = nickname.substring(0, 40);
            }

            usersToInsert.add(new User(
                // Username = uniqueEmail,
                Username = acc.PersonEmail,
                Email = acc.PersonEmail,
                Alias = acc.Name.length() >= 8 ? acc.Name.substring(0, 8) : acc.Name.rightPad(8, 'X'),
                LastName = acc.Name,
                CommunityNickname = nickname, // acc.Name.replaceAll('\\s+', '') + '.ff',
                ProfileId = profileId,
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/New_York',
                ContactId = acc.PersonContactId,
                IsActive = true
            ));

            accountsToUpdate.add(new Account(
                Id = acc.Id,
                Provisioned_to_B2B_Store__c = 'Successful'
            ));
        }

        if (!usersToInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(usersToInsert, false);
            for (Integer i = 0; i < insertResults.size(); i++) {
                if (!insertResults[i].isSuccess()) {
                    for (Database.Error err : insertResults[i].getErrors()) {
                        System.debug('⚠️ User Insert Error: ' + err.getMessage());
                    }
                }
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(accountsToUpdate, false);
            for (Integer i = 0; i < updateResults.size(); i++) {
                if (!updateResults[i].isSuccess()) {
                    for (Database.Error err : updateResults[i].getErrors()) {
                        System.debug('⚠️ Account Update Error for Id: ' +
                                     accountsToUpdate[i].Id + ' - ' + err.getMessage());
                    }
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('✅ Community user provisioning complete.');
    }
}