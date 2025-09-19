public class B2BMembershipEndController {

    public static void handleMembershipUnassignments(List<Account_Membership__c> accountMemberships) {
        try {
            Map<String, List<Id>> accountBuyerGroupIdsMap = new Map<String, List<Id>>();
            Map<String, List<Integer>> accountSXJobIdsMap = new Map<String, List<Integer>>();
            List<Account_Membership__c> expiredILMAs = new List<Account_Membership__c>();
            
            for (Account_Membership__c record : accountMemberships) {
                //Collect Expired ILMAs
                if(record.Expired__c) {
                    expiredILMAs.add(record);
                }

                Set<Id> membershipEndedAccounts = getMembershipEndedAccounts(record);

                if(membershipEndedAccounts != null) {

                    Map<String, List<Id>> tempBuyerGroupMap = handleBuyerGroupsUnassignment(record, membershipEndedAccounts);
                    for (String accountId : tempBuyerGroupMap.keySet()) {
                        if (!accountBuyerGroupIdsMap.containsKey(accountId)) {
                            accountBuyerGroupIdsMap.put(accountId, new List<Id>());
                        }
                        accountBuyerGroupIdsMap.get(accountId).addAll(tempBuyerGroupMap.get(accountId));
                    }

                    Map<String, List<Integer>> tempSXJobMap = handleSchooxJobsUnassignment(record, membershipEndedAccounts);
                    for (String accountId : tempSXJobMap.keySet()) {
                        if (!accountSXJobIdsMap.containsKey(accountId)) {
                            accountSXJobIdsMap.put(accountId, new List<Integer>());
                        }
                        accountSXJobIdsMap.get(accountId).addAll(tempSXJobMap.get(accountId));
                    }
                }
            }

            //Update ILMAs Status as Expired
            if(!expiredILMAs.isEmpty()) {
                B2BMembershipEndHelper.updateILMAsStatusAsExpired(expiredILMAs);
            }

            //Unassign BuyerGroups
            if(!accountBuyerGroupIdsMap.isEmpty()) {
                for (String accountId : accountBuyerGroupIdsMap.keySet()) {
                    List<Id> buyerGroupIds = accountBuyerGroupIdsMap.get(accountId);
                    if(buyerGroupIds != null) {
                        B2BMembershipEndHelper.unassignBuyerGroups(accountId, buyerGroupIds);
                    }
                }
            }

            // Unassign Schoox Jobs
            if (!accountSXJobIdsMap.isEmpty()) {
                System.enqueueJob(new B2BSchooxJobsUnassignmentQueueable(accountSXJobIdsMap));
            }
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BMembershipEndController', 'handleMembershipUnassignments');
        }
    }

    private static Map<String, List<Id>> handleBuyerGroupsUnassignment(Account_Membership__c ilma, Set<Id> membershipEndedAccounts) {
        Map<String, List<Id>> accountBuyerGroupIdsMap = new Map<String, List<Id>>();

        String membershipId = ilma.Membership__c;
        Boolean isCertified = ilma.Certified__c;

        for(Id accountId : membershipEndedAccounts) {
            Boolean isAdmin = B2BMembershipEndHelper.getAccountRole(accountId);
            List<Id> buyerGroupIds = B2BMembershipEndHelper.getBuyerGroupMemberships(membershipId, isCertified, isAdmin);

            //Check if account has any active memberships assigned
            Boolean hasActiveMemberships = B2BMembershipEndHelper.hasActiveILMAs(accountId);
            if(!hasActiveMemberships) {
                //get the generic buyer groups from the account -> add them to buyerGroupIds To Unassign
                List<Id> genericBuyerGroupIds = B2BMembershipEndHelper.getBuyerGroupsFromAccount(accountId);
                if(genericBuyerGroupIds != null) {
                    if(buyerGroupIds != null) {
                        buyerGroupIds.addAll(genericBuyerGroupIds);
                    }
                    else {
                        buyerGroupIds = genericBuyerGroupIds;
                    }
                }
            }

            if(buyerGroupIds != null) {
                //Check if account currently have an active ILMA of same membership
                List<Account_Membership__c> activeILMAs = B2BMembershipEndHelper.getActiveILMAofSameType(accountId, membershipId);
                if(activeILMAs == null) {
                    accountBuyerGroupIdsMap.put(accountId, buyerGroupIds);
                }
            }
        }
        return accountBuyerGroupIdsMap;
    }

    private static Map<String, List<Integer>> handleSchooxJobsUnassignment(Account_Membership__c ilma, Set<Id> membershipEndedAccounts) {
        Map<String, List<Integer>> accountSXJobIdsMap = new Map<String, List<Integer>>();

        //Collect Job Ids to Unassign Schoox Jobs
        List<Integer> jobIds = new List<Integer>();
        jobIds.add(Integer.valueOf(ilma.Job_Id__c));

        if(jobIds != null) {
            String membershipId = ilma.Membership__c;

            for(Id accountId : membershipEndedAccounts) {
                //Check if account currently have an active ILMA of same membership
                List<Account_Membership__c> activeILMAs = B2BMembershipEndHelper.getActiveILMAofSameType(accountId, membershipId);
                if(activeILMAs == null) {
                    accountSXJobIdsMap.put(accountId, jobIds);
                }
            }
        }
        return accountSXJobIdsMap;
    }

    private static Set<Id> getMembershipEndedAccounts(Account_Membership__c ilma) {
        Set<Id> membershipEndedAccounts = new Set<Id>();

        //Get AccountId(s) of complete or voided ILMAs
        if(ilma.Account_Id__c != null && (ilma.Expired__c || ilma.Status__c == 'Complete' || ilma.Status__c == 'Voided')) { 
            membershipEndedAccounts.add((Id)ilma.Account_Id__c);
        }

        //Get AccountId(s) of unassigned or unassigned and then reassigned ILMAs
        if(ilma.Account_Id__c == null || ilma.can_be_fully_reassigned__c) {

            List<Account_Membership__History> fieldHistory = [
                SELECT Field, OldValue, NewValue, CreatedDate
                FROM Account_Membership__History
                WHERE ParentId = :ilma.Id
                AND Field = 'Account_Id__c'
                AND DataType = 'EntityId'
                AND CreatedDate = YESTERDAY
                ORDER BY CreatedDate ASC
            ];

            if(fieldHistory.size() > 0) {
                for (Account_Membership__History amh : fieldHistory) {
                    if (amh.OldValue != null && amh.OldValue != amh.NewValue && amh.OldValue != ilma.Account_Id__c) {
                        membershipEndedAccounts.add((Id)amh.OldValue);
                    }
                }
            }
        }

        if(!membershipEndedAccounts.isEmpty()) {
            return membershipEndedAccounts;
        }
        return null;
    }
}