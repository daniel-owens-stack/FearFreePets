public class B2BBuyerGroupAssignmentService {
    public static List<String> getElibleILMABuyerGroups(Account_Membership__c iLMA) {
        Account account = B2BBuyerGroupAssignmentServiceHelper.getAccountById(String.valueOf(iLMA.Account_Id__c));
        List<Buyer_Group_Membership__c> buyerGroupMembershipList = 
            B2BBuyerGroupAssignmentServiceHelper.getElibleILMABuyerGroups(iLMA.Membership__c, iLMA.Certified__c, account.Admin_Account__c);
        
        Set<String> buyerGroupIdsSet = new Set<String>();
        for (Buyer_Group_Membership__c bgm : buyerGroupMembershipList) {
            buyerGroupIdsSet.add(bgm.Buyer_Group__c);
        }
        
        List<String> buyerGroupIds = new List<String>(buyerGroupIdsSet);
        List<BuyerGroupMember> duplicateBuyerGroupList = 
            B2BBuyerGroupAssignmentServiceHelper.getExistingBuyerGroupAssignments(String.valueOf(iLMA.Account_Id__c), buyerGroupIds);
        
        Set<String> duplicateBuyerGroupIds = new Set<String>();
        for (BuyerGroupMember duplicate : duplicateBuyerGroupList) {
            duplicateBuyerGroupIds.add(duplicate.BuyerGroupId);
        }
        
        List<String> uniqueBuyerGroupIds = new List<String>();
        for (String buyerGroupId : buyerGroupIds) {
            if (!duplicateBuyerGroupIds.contains(buyerGroupId)) {
                uniqueBuyerGroupIds.add(buyerGroupId);
            }
        }
        
        return uniqueBuyerGroupIds;
    }

    public static void createBuyerGroupMembers(List<String> buyerGroupIdList, String accountId) {
        
        List<BuyerGroupMember> buyerGroupMembersToCreate = new List<BuyerGroupMember>();
        for (String buyerGroupId : buyerGroupIdList) {
            BuyerGroupMember buyerGroupMember = new BuyerGroupMember();
            buyerGroupMember.BuyerId = accountId;
            buyerGroupMember.BuyerGroupId = buyerGroupId;
            buyerGroupMembersToCreate.add(buyerGroupMember);
        }

        insert buyerGroupMembersToCreate;
    }

    public static void deleteBuyerGroupMembers(List<String> buyerGroupIdsToUnassign, String accountId) {
        
        List<BuyerGroupMember> buyerGroupMembersToDelete = B2BBuyerGroupAssignmentServiceHelper.getExistingBuyerGroupAssignments(accountId, buyerGroupIdsToUnassign);

        if(buyerGroupMembersToDelete != null) {
            delete buyerGroupMembersToDelete;
        }
    }

    public static List<String> getBuyerGroupsToUnassign(Account account, List<Buyer_Group_Membership__c> buyerGroupMembershipList) {

        List<String> roleSpecificBuyerGroupIds = B2BBuyerGroupAssignmentServiceHelper.getRoleSpecificBuyerGroups(buyerGroupMembershipList, !(account.Admin_Account__c));
        return roleSpecificBuyerGroupIds;
    }

    public static List<String> getBuyerGroupsToAssign(Account account, List<Buyer_Group_Membership__c> buyerGroupMembershipList) {

        Set<String> buyerGroupIdsSet = new Set<String>();
        for(Buyer_Group_Membership__c buyerGroupMembership : buyerGroupMembershipList) {
            buyerGroupIdsSet.add(buyerGroupMembership.Buyer_Group__c);
        }
        
        List<String> buyerGroupIds = new List<String>(buyerGroupIdsSet);
        List<BuyerGroupMember> existingBuyerGroupList = B2BBuyerGroupAssignmentServiceHelper.getExistingBuyerGroupAssignments(account.Id, buyerGroupIds);
        
        Set<String> existingBuyerGroupIds = new Set<String>();
        if(existingBuyerGroupList != null) {
            for (BuyerGroupMember existing : existingBuyerGroupList) {
                existingBuyerGroupIds.add(existing.BuyerGroupId);
            }
        }

        List<String> roleSpecificBuyerGroupIds = B2BBuyerGroupAssignmentServiceHelper.getRoleSpecificBuyerGroups(buyerGroupMembershipList, account.Admin_Account__c);
        
        Set<String> uniqueBuyerGroupSet = new Set<String>();

        for (String buyerGroupId : roleSpecificBuyerGroupIds) {
            if (!existingBuyerGroupIds.contains(buyerGroupId)) {
                uniqueBuyerGroupSet.add(buyerGroupId);
            }
        }

        List<String> uniqueBuyerGroupIds = new List<String>(uniqueBuyerGroupSet);

        System.debug('Final List of Unique Buyer Group IDs: ' + uniqueBuyerGroupIds);

        return uniqueBuyerGroupIds;
    }

    public static List<String> getActiveMemberships(String accountId) {
        try {
            List<Account_Membership__c> activeILMAs = B2BBuyerGroupAssignmentServiceHelper.getActiveIndividualMembershipAssignments(accountId);

            List<String> membershipIds = new List<String>();
            if(activeILMAs != null) {
                for(Account_Membership__c am : activeILMAs) {
                    if (!membershipIds.contains(am.Membership__c)) {
                        membershipIds.add(am.Membership__c);
                    }
                }
            }
            return membershipIds;
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BBuyerGroupAssignmentService', 'getActiveMemberships');
            return null;
        }
    }
}