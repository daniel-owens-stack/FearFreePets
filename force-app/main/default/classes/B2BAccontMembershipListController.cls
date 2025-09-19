/**
 * @description       : 
 * @author            : Poojitha Anthati
 * @group             : 
 * @last modified on  : 09-18-2025
 * @last modified by  : Poojitha Anthati
**/
public without sharing class B2BAccontMembershipListController {

    @AuraEnabled(cacheable=true)
    public static List<List<AccountMembershipWrapper>> getAccountMemberships(String accountId) {
        List<List<AccountMembershipWrapper>> resultList = new List<List<AccountMembershipWrapper>>();
        if (String.isBlank(accountId)) {
            return resultList;
        }

        // Query memberships for the given account
        List<Account_Membership__c> accMemList = [
            SELECT Id,
                   Name,
                   Membership__c,
                   Membership__r.Name,
                   Account_Id__r.Name,
                   Parent_Id__c,
                   Account_Id__c,
                   Account_Assignment_Date__c,
                   Start_Date__c,
                   Expiration_Date__c,
                   Certified__c,
                   Related_Course_Completion__c,
                   Exemption_Status__c,
                   Status__c,
                   Account_Id__r.Business__c
            FROM Account_Membership__c
            WHERE ((Account_Id__c = null AND Parent_Id__c = :accountId)
                   OR (Account_Id__c != null AND Account_Id__r.Business__c = :accountId))
              AND Status__c != 'Voided'
            ORDER BY Membership__c, Account_Id__r.Name NULLS FIRST
        ];

        // Build wrappers
        List<AccountMembershipWrapper> wrapperList = new List<AccountMembershipWrapper>();
        for (Account_Membership__c am : accMemList) {
            String businessAccountIdStr = null;
            if (am.Account_Id__r != null && am.Account_Id__r.Business__c != null) {
                businessAccountIdStr = String.valueOf(am.Account_Id__r.Business__c);
            }
            String accountNameStr = (am.Account_Id__r != null && am.Account_Id__r.Name != null) ? am.Account_Id__r.Name : null;
            String membershipNameStr = (am.Membership__r != null && am.Membership__r.Name != null) ? am.Membership__r.Name : null;

            wrapperList.add(new AccountMembershipWrapper(
                businessAccountIdStr,
                accountNameStr,
                membershipNameStr,
                am.Parent_Id__c,
                am.Membership__c,
                am.Account_Id__c,
                am.Id,
                am.Account_Assignment_Date__c,
                am.Start_Date__c,
                am.Expiration_Date__c,
                am.Certified__c,
                am.Related_Course_Completion__c,
                am.Exemption_Status__c,
                am.Status__c
            ));
        }

        // Group by parentKey -> membershipKey -> list
        Map<String, Map<String, List<AccountMembershipWrapper>>> groupedMap = new Map<String, Map<String, List<AccountMembershipWrapper>>>();
        for (AccountMembershipWrapper w : wrapperList) {
            String pKey = w.parentKey != null ? w.parentKey : 'NO_PARENT';
            String mKey = w.membershipKey != null ? w.membershipKey : 'NO_MEMBERSHIP';

            if (!groupedMap.containsKey(pKey)) groupedMap.put(pKey, new Map<String, List<AccountMembershipWrapper>>());
            Map<String, List<AccountMembershipWrapper>> memMap = groupedMap.get(pKey);

            if (!memMap.containsKey(mKey)) memMap.put(mKey, new List<AccountMembershipWrapper>());
            memMap.get(mKey).add(w);
        }

        // For each parent & membership, group by account and apply selection rules
        for (String pKey : groupedMap.keySet()) {
            List<AccountMembershipWrapper> parentResult = new List<AccountMembershipWrapper>();
            Map<String, List<AccountMembershipWrapper>> memMap = groupedMap.get(pKey);

            for (String mKey : memMap.keySet()) {
                List<AccountMembershipWrapper> membershipList = memMap.get(mKey);

                // Group by account (use accId if present, otherwise accountName as fallback)
                Map<String, List<AccountMembershipWrapper>> accountGroup = new Map<String, List<AccountMembershipWrapper>>();
                for (AccountMembershipWrapper m : membershipList) {
                    String accGroupingKey = m.accId != null
                        ? String.valueOf(m.accId)
                        : 'UNASSIGNED_' + (m.accountName != null ? m.accountName : 'UNKNOWN');

                    if (!accountGroup.containsKey(accGroupingKey)) {
                        accountGroup.put(accGroupingKey, new List<AccountMembershipWrapper>());
                    }
                    accountGroup.get(accGroupingKey).add(m);
                }

                // For each account under this membership, collect Active/Early or latest Expired
                for (String accKey : accountGroup.keySet()) {
                    List<AccountMembershipWrapper> accMemberships = accountGroup.get(accKey);
                    List<AccountMembershipWrapper> activeEarly = new List<AccountMembershipWrapper>();
                    AccountMembershipWrapper latestExpired = null;

                    for (AccountMembershipWrapper amw : accMemberships) {
                        if (amw.status == 'Active' || amw.status == 'Early') {
                            activeEarly.add(amw);
                        } else if (amw.status == 'Expired') {
                            if (latestExpired == null) {
                                latestExpired = amw;
                            } else {
                                Date curExp = amw.expirationDate;
                                Date prevExp = latestExpired.expirationDate;
                                if (curExp != null && (prevExp == null || curExp > prevExp)) {
                                    latestExpired = amw;
                                }
                            }
                        }
                    }

                    if (!activeEarly.isEmpty()) {
                        parentResult.addAll(activeEarly);
                    } else if (latestExpired != null) {
                        parentResult.add(latestExpired);
                    }
                }
            }

            resultList.add(parentResult);
        }

        return resultList;
    }

    // Wrapper class used by client (Aura/LWC). keys are strings to avoid Id/String mixing.
    public class AccountMembershipWrapper {
        @AuraEnabled
        public String accountName { get; set; }

        @AuraEnabled
        public String membershipName { get; set; }

        // keys used for grouping (strings)
        public String parentKey { get; set; }
        public String membershipKey { get; set; }
        public Id accId { get; set; }

        @AuraEnabled
        public String accountLink { get; set; }

        @AuraEnabled
        public Id Id { get; set; }

        @AuraEnabled
        public Date accountAssignmentDate { get; set; }
        @AuraEnabled
        public Date purchaseDate { get; set; }
        @AuraEnabled
        public Date expirationDate{ get; set; }

        @AuraEnabled
        public String certificationStatus{ get; set; }
        @AuraEnabled
        public Decimal courseProgress{ get; set; }
        @AuraEnabled
        public String exemptionStatus{ get; set; }
        @AuraEnabled
        public String status { get; set; }

        public AccountMembershipWrapper(
            String businessAccountIdStr,
            String accountName,
            String membershipName,
            Id parentId,
            Id membershipId,
            Id accId,
            Id Id,
            Date accountAssignmentDate,
            Date purchaseDate,
            Date expirationDate,
            Boolean certified,
            Decimal courseProgress,
            String exemptionStatus,
            String status
        ) {
            this.accountName = accountName != null ? accountName : 'Unassigned';
            this.membershipName = membershipName;
            // parentKey is either the business account id (string) or the parentId (as string)
            this.parentKey = (accId == null)
                ? (parentId != null ? String.valueOf(parentId) : null)
                : businessAccountIdStr;
            this.membershipKey = membershipId != null ? String.valueOf(membershipId) : null;
            this.accId = accId;
            this.accountLink = '/' + Id;
            this.Id = Id;
            this.accountAssignmentDate = accountAssignmentDate;
            this.purchaseDate = purchaseDate;
            this.expirationDate = expirationDate;
            this.certificationStatus = certified ? 'Certified' : 'Not Certified';
            this.courseProgress = courseProgress;
            this.exemptionStatus = exemptionStatus;
            this.status = status == 'Complete' ? 'Expired' : status;
        }
    }
}