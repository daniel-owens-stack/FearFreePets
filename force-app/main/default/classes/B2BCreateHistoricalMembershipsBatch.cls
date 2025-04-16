public class B2BCreateHistoricalMembershipsBatch implements Database.Batchable<sObject>, Database.Stateful {

    public B2BCreateHistoricalMembershipsBatch() { }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, post_id__c, Post_Parent__c, Start_Date__c, End_Date__c, Cancelled_Date__c, User_Email__c FROM Historical_Membership__c WHERE Data_Status__c = \'Pending\'';
        System.debug('Start method - Query: ' + query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Historical_Membership__c> scope) {
        System.debug('Execute method - Scope size: ' + scope.size());

        try {
            Set<String> userEmails = new Set<String>();
            Set<String> postParentIds = new Set<String>();
            Map<String, Account> emailToAccountMap = new Map<String, Account>();
            Map<String, Id> wcIdToMembershipIdMap = new Map<String, Id>();

            List<Historical_Membership__c> validMembershipsToInsert = new List<Historical_Membership__c>();
            List<Historical_Membership__c> unsuccessfulMembershipsToUpdate = new List<Historical_Membership__c>();

            for (Historical_Membership__c hm : scope) {
                if (hm.User_Email__c != null) {
                    userEmails.add(hm.User_Email__c.trim().toLowerCase());
                }
                if (hm.Post_Parent__c != null) {
                    postParentIds.add(hm.Post_Parent__c.trim());
                }
            }

            System.debug('Collected userEmails: ' + userEmails);
            System.debug('Collected postParentIds: ' + postParentIds);

            List<Account> matchingAccounts = [
                SELECT Id, PersonEmail
                FROM Account 
                WHERE PersonEmail IN :userEmails
            ];
            for (Account acc : matchingAccounts) {
                if (acc.PersonEmail != null) {
                    emailToAccountMap.put(acc.PersonEmail.trim().toLowerCase(), acc);
                }
            }

            System.debug('emailToAccountMap: ' + emailToAccountMap);

            List<Membership__c> matchingMemberships = [
                SELECT Id, WC_Id__c
                FROM Membership__c
                WHERE WC_Id__c IN :postParentIds
            ];
            for (Membership__c mem : matchingMemberships) {
                if (mem.WC_Id__c != null) {
                    wcIdToMembershipIdMap.put(mem.WC_Id__c.trim(), mem.Id);
                }
            }

            System.debug('wcIdToMembershipIdMap: ' + wcIdToMembershipIdMap);

            for (Historical_Membership__c hm : scope) {
                String emailKey = hm.User_Email__c != null ? hm.User_Email__c.trim().toLowerCase() : null;
                String wcId = hm.Post_Parent__c != null ? hm.Post_Parent__c.trim() : null;

                System.debug('Processing Historical Membership: ' + hm.Id);

                if (hm.Start_Date__c == null) {
                    System.debug('Missing Start_Date__c for Historical Membership: ' + hm.Id);
                    hm.Exception__c = B2BHandleCustomException.LogException(
                        new HistoricalMembershipException('Missing required field Start Date'),
                        'Historical Memberships',
                        'Membership Creation'
                    );
                    hm.Data_Status__c = 'Unsuccessful';
                    unsuccessfulMembershipsToUpdate.add(hm);
                    continue;
                }

                if (!emailToAccountMap.containsKey(emailKey)) {
                    System.debug('No Account match for email: ' + emailKey);
                    hm.Exception__c = B2BHandleCustomException.LogException(
                        new HistoricalMembershipException('No matching Account found for User Email: ' + hm.User_Email__c),
                        'Historical Memberships',
                        'Membership Creation'
                    );
                    hm.Data_Status__c = 'Unsuccessful';
                    unsuccessfulMembershipsToUpdate.add(hm);
                    continue;
                }

                if (!wcIdToMembershipIdMap.containsKey(wcId)) {
                    System.debug('No Membership match for WC_Id__c: ' + wcId);
                    hm.Exception__c = B2BHandleCustomException.LogException(
                        new HistoricalMembershipException('No matching Membership found for WC_Id__c: ' + wcId),
                        'Historical Memberships',
                        'Membership Creation'
                    );
                    hm.Data_Status__c = 'Unsuccessful';
                    unsuccessfulMembershipsToUpdate.add(hm);
                    continue;
                }

                validMembershipsToInsert.add(hm);
            }

            System.debug('Valid Memberships Count: ' + validMembershipsToInsert.size());
            System.debug('Unsuccessful Memberships Count: ' + unsuccessfulMembershipsToUpdate.size());

            List<Account_Membership__c> ilmasToInsert = new List<Account_Membership__c>();

            for (Historical_Membership__c hm : validMembershipsToInsert) {
                try {
                    String emailKey = hm.User_Email__c.trim().toLowerCase();
                    String wcId = hm.Post_Parent__c.trim();
                    Account matchedAccount = emailToAccountMap.get(emailKey);
                    Id membershipId = wcIdToMembershipIdMap.get(wcId);

                    ilmasToInsert.add(new Account_Membership__c(
                        Historical_Membership__c = hm.Id,
                        Membership__c = membershipId,
                        Start_Date__c = hm.Start_Date__c,
                        Account_Id__c = matchedAccount.Id,
                        Status__c = (hm.Cancelled_Date__c != null || hm.End_Date__c != null) ? 'Complete' : 'Active',
                        Welcome_Kit_Status__c = 'Unavailable',
                        Account_Assignment_Date__c = hm.Start_Date__c
                    ));

                    hm.Data_Status__c = 'Successful';
                    System.debug('Created ILMA for Historical Membership: ' + hm.Id);

                } catch (Exception e) {
                    System.debug('Exception during ILMA creation: ' + e.getMessage());
                    hm.Exception__c = B2BHandleCustomException.LogException(
                        new HistoricalMembershipException('Membership creation failed: ' + e.getMessage()),
                        'Historical Memberships',
                        'Membership Creation'
                    );
                    hm.Data_Status__c = 'Unsuccessful';
                    unsuccessfulMembershipsToUpdate.add(hm);
                }
            }

            if (!ilmasToInsert.isEmpty()) {
                insert ilmasToInsert;
                System.debug('Inserted ILMAs: ' + ilmasToInsert.size());
            }

            if (!unsuccessfulMembershipsToUpdate.isEmpty()) {
                update unsuccessfulMembershipsToUpdate;
                System.debug('Updated Unsuccessful Memberships: ' + unsuccessfulMembershipsToUpdate.size());
            }

            if (!validMembershipsToInsert.isEmpty()) {
                update validMembershipsToInsert;
                System.debug('Updated Valid Memberships: ' + validMembershipsToInsert.size());
            }

        } catch (Exception e) {
            System.debug('Batch-level exception: ' + e.getMessage());
            B2BHandleCustomException.LogException(e, 'Historical Memberships', 'Membership Creation - Batch Level Failure');
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Finish method called');
    }

    public class HistoricalMembershipException extends Exception {}
}