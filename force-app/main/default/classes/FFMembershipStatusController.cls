public with sharing class FFMembershipStatusController {

    public class MembershipStatus {
        @AuraEnabled public Boolean isAdmin { get; set; }
        @AuraEnabled public Boolean hasExpiredPLMA { get; set; }
        @AuraEnabled public Boolean hasExpiredAcademia { get; set; }
        @AuraEnabled public Boolean hasExpiredVet { get; set; }
        @AuraEnabled public Boolean hasExpiredVPC { get; set; }
        @AuraEnabled public Boolean hasExpiredGroomer { get; set; }
        @AuraEnabled public Boolean hasExpiredSitter { get; set; }
        @AuraEnabled public Boolean hasExpiredBDC { get; set; }
        @AuraEnabled public Boolean hasExpiredTrainer { get; set; }
        @AuraEnabled public Boolean hasActiveAcademia { get; set; }
        @AuraEnabled public Boolean hasActiveVet { get; set; }
        @AuraEnabled public Boolean hasActiveVPC { get; set; }
        @AuraEnabled public Boolean hasActiveGroomer { get; set; }
        @AuraEnabled public Boolean hasActiveSitter { get; set; }
        @AuraEnabled public Boolean hasActiveBDC { get; set; }
        @AuraEnabled public Boolean hasActiveTrainer { get; set; }
    }

    // Removed cacheable=true because we are using context-specific data (UserInfo) and multiple related object queries.
    @AuraEnabled
    public static MembershipStatus getMembershipStatus() {
        MembershipStatus status = new MembershipStatus();

        // Initialize defaults
        status.isAdmin = false;
        status.hasExpiredPLMA = false;
        status.hasExpiredAcademia = false;
        status.hasExpiredVet = false;
        status.hasExpiredVPC = false;
        status.hasExpiredGroomer = false;
        status.hasExpiredSitter = false;
        status.hasExpiredBDC = false;
        status.hasExpiredTrainer = false;
        status.hasActiveAcademia = false;
        status.hasActiveVet = false;
        status.hasActiveVPC = false;
        status.hasActiveGroomer = false;
        status.hasActiveSitter = false;
        status.hasActiveBDC = false;
        status.hasActiveTrainer = false;

        System.debug('Starting getMembershipStatus at ' + Datetime.now() + ' for UserId: ' + UserInfo.getUserId());

        // Get the current logged-in user ID and AccountId
        Id currentUserId = UserInfo.getUserId();
        System.debug('Current User ID: ' + currentUserId);
        User currentUser = [SELECT AccountId FROM User WHERE Id = :currentUserId LIMIT 1];
        Id currentUserAccountId = currentUser.AccountId;
        System.debug('Current User AccountId: ' + currentUserAccountId);

        if (currentUserAccountId == null) {
            System.debug('No AccountId found for user, aborting membership check');
            return status;
        }

        System.debug('Processing memberships for AccountId: ' + currentUserAccountId);

        // Check for regular memberships
        List<Account_Membership__c> memberships = [
            SELECT Id, Status__c, Membership__r.Name
            FROM Account_Membership__c
            WHERE Account_Id__c = :currentUserAccountId
        ];
        System.debug('Found ' + memberships.size() + ' Account_Membership__c records: ' + JSON.serialize(memberships));

        for (Account_Membership__c m : memberships) {
            if (m.Membership__r == null || String.isBlank(m.Membership__r.Name)) {
                System.debug('Skipping blank or null membership relationship for record: ' + m.Id);
                continue;
            }

            String name = m.Membership__r.Name;
            String statusValue = m.Status__c != null ? m.Status__c.toLowerCase() : '';

            System.debug('Processing membership: Id=' + m.Id + ', Name=' + name + ', Status=' + m.Status__c);

            if (statusValue == 'Complete') {
                if (name.contains('Veterinary Practice Certification')) {
                    status.hasExpiredPLMA = true;
                    status.hasExpiredVPC = true;
                    System.debug('Set hasExpiredPLMA and hasExpiredVPC to true for: ' + name);
                } else if (name.contains('Academia Membership')) {
                    status.hasExpiredAcademia = true;
                    System.debug('Set hasExpiredAcademia to true for: ' + name);
                } else if (name.contains('Veterinary Professional Membership')) {
                    status.hasExpiredVet = true;
                    System.debug('Set hasExpiredVet to true for: ' + name);
                } else if (name.contains('Groomer Membership')) {
                    status.hasExpiredGroomer = true;
                    System.debug('Set hasActiveGroomer to true for: ' + name);
                } else if (name.contains('Pet Sitter Membership')) {
                    status.hasExpiredSitter = true;
                    System.debug('Set hasActiveSitter to true for: ' + name);
                } else if (name.contains('Boarding & Daycare')) {
                    status.hasExpiredBDC = true;
                    System.debug('Set hasActiveBDC to true for: ' + name);
                } else if (name.contains('Trainer Membership')) {
                    status.hasExpiredTrainer = true;
                    System.debug('Set hasActiveTrainer to true for: ' + name);
                }
            } else if (statusValue == 'Active') {
                if (name.contains('Veterinary Practice Certification')) {
                    status.hasActiveVPC = true;
                    System.debug('Set hasActiveVPC to true for: ' + name);
                } else if (name.contains('Academia Membership')) {
                    status.hasActiveAcademia = true;
                    System.debug('Set hasActiveAcademia to true for: ' + name);
                } else if (name.contains('Veterinary Professional Membership')) {
                    status.hasActiveVet = true;
                    System.debug('Set hasActiveVet to true for: ' + name);
                } else if (name.contains('Groomer Membership')) {
                    status.hasActiveGroomer = true;
                    System.debug('Set hasActiveGroomer to true for: ' + name);
                } else if (name.contains('Pet Sitter Membership')) {
                    status.hasActiveSitter = true;
                    System.debug('Set hasActiveSitter to true for: ' + name);
                } else if (name.contains('Boarding & Daycare')) {
                    status.hasActiveBDC = true;
                    System.debug('Set hasActiveBDC to true for: ' + name);
                } else if (name.contains('Trainer Membership')) {
                    status.hasActiveTrainer = true;
                    System.debug('Set hasActiveTrainer to true for: ' + name);
                }
            } else {
                System.debug('Unexpected Status__c value: ' + m.Status__c + ' for membership: ' + name);
            }
        }

        // Admin check
        List<Account> matchingAccounts = [
            SELECT Id, Admin_Account__c, Business__c 
            FROM Account 
            WHERE Id = :currentUserAccountId 
            AND Admin_Account__c = TRUE 
            AND Business__c != null 
            LIMIT 1
        ];
        System.debug('Found ' + matchingAccounts.size() + ' admin accounts: ' + JSON.serialize(matchingAccounts));

        if (!matchingAccounts.isEmpty()) {
            Account adminAccount = matchingAccounts[0];
            status.isAdmin = true;
            System.debug('Set isAdmin to true for Business__c: ' + adminAccount.Business__c);

            List<Practice_Level_Membership_Assignment__c> plmaList = [
                SELECT Membership__r.Name, Status__c 
                FROM Practice_Level_Membership_Assignment__c 
                WHERE Business_Account__c = :adminAccount.Business__c
            ];
            System.debug('Found ' + plmaList.size() + ' PLMA records: ' + JSON.serialize(plmaList));

            for (Practice_Level_Membership_Assignment__c plma : plmaList) {
                if (plma.Membership__r == null || String.isBlank(plma.Membership__r.Name)) {
                    System.debug('Skipping blank or null PLMA membership relationship');
                    continue;
                }

                String name = plma.Membership__r.Name;
                String statusValue = plma.Status__c != null ? plma.Status__c.toLowerCase() : '';

                System.debug('Processing PLMA: Name=' + name + ', Status=' + plma.Status__c);

                if (statusValue == 'Complete' && name.toLowerCase().contains('veterinary practice certification')) {
                    status.hasExpiredPLMA = true;
                    System.debug('Set hasExpiredPLMA to true from PLMA for: ' + name);
                } else if (statusValue == 'Active' && name.toLowerCase().contains('veterinary practice certification')) {
                    status.hasActiveVPC = true;
                    System.debug('Set hasActiveVPC to true from PLMA for: ' + name);
                }
            }
        }

        System.debug('Returning status: ' + JSON.serialize(status));
        return status;
    }
}