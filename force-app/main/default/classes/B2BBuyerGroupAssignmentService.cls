/**
 * @description       : 
 * @author            : Poojitha Anthati
 * @group             : 
 * @last modified on  : 09-18-2025
 * @last modified by  : Poojitha Anthati
**/
public class B2BBuyerGroupAssignmentService {
    public static List<String> getEligibleILMABuyerGroups(Account_Membership__c iLMA) {
        Account account = B2BBuyerGroupAssignmentServiceHelper.getAccountById(String.valueOf(iLMA.Account_Id__c));
        List<Buyer_Group_Membership__c> buyerGroupMembershipList = 
            B2BBuyerGroupAssignmentServiceHelper.getEligibleILMABuyerGroups(iLMA.Membership__c, iLMA.Certified__c, account.Admin_Account__c);
        
        Set<String> buyerGroupIdsSet = new Set<String>();
        for (Buyer_Group_Membership__c bgm : buyerGroupMembershipList) {
            buyerGroupIdsSet.add(bgm.Buyer_Group__c);
        }
        
        List<String> buyerGroupIds = new List<String>(buyerGroupIdsSet);
        List<BuyerGroupMember> duplicateBuyerGroupList = 
            B2BBuyerGroupAssignmentServiceHelper.getExistingBuyerGroupAssignments(String.valueOf(iLMA.Account_Id__c), buyerGroupIds);
        
        Set<String> duplicateBuyerGroupIds = new Set<String>();

        if(duplicateBuyerGroupList != null) {
            for (BuyerGroupMember duplicate : duplicateBuyerGroupList) {
                duplicateBuyerGroupIds.add(duplicate.BuyerGroupId);
            }
        }
        
        List<String> uniqueBuyerGroupIds = new List<String>();
        for (String buyerGroupId : buyerGroupIds) {
            if (!duplicateBuyerGroupIds.contains(buyerGroupId)) {
                uniqueBuyerGroupIds.add(buyerGroupId);
            }
        }
        
        return uniqueBuyerGroupIds;
    }

    public static List<String> getInEligibleILMABuyerGroups(Account_Membership__c iLMA) {
        Account account = B2BBuyerGroupAssignmentServiceHelper.getAccountById(String.valueOf(iLMA.Account_Id__c));
        List<Buyer_Group_Membership__c> buyerGroupMembershipList = 
            B2BBuyerGroupAssignmentServiceHelper.getInEligibleILMABuyerGroups(iLMA.Membership__c, iLMA.Certified__c, !account.Admin_Account__c);
        
        Set<String> buyerGroupIdsSet = new Set<String>();
        for (Buyer_Group_Membership__c bgm : buyerGroupMembershipList) {
            buyerGroupIdsSet.add(bgm.Buyer_Group__c);
        }
        
        List<String> buyerGroupIds = new List<String>(buyerGroupIdsSet);
        return buyerGroupIds;
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

    public static List<Account_Membership__c> getActiveMemberships(String accountId) {
        try {
            List<Account_Membership__c> activeILMAs = B2BBuyerGroupAssignmentServiceHelper.getActiveIndividualMembershipAssignments(accountId);
            
            if(activeILMAs != null) {
                Map<String, Account_Membership__c> uniqueMembershipMap = new Map<String, Account_Membership__c>();
    
                for (Account_Membership__c am : activeILMAs) {
                    if (!uniqueMembershipMap.containsKey(am.Membership__c)) {
                        uniqueMembershipMap.put(am.Membership__c, am);
                    }
                }
    
                List<Account_Membership__c> uniqueAccountMemberships = new List<Account_Membership__c>(uniqueMembershipMap.values());
                return uniqueAccountMemberships;
            }
            return activeILMAs;
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BBuyerGroupAssignmentService', 'getActiveMemberships');
            return null;
        }
    }

    public static List<String> getEligibleBuyerGroups(Account_Membership__c iLMA) {
        Account account = B2BBuyerGroupAssignmentServiceHelper.getAccountById(String.valueOf(iLMA.Account_Id__c));
        List<Buyer_Group_Membership__c> buyerGroupMembershipList = 
            B2BBuyerGroupAssignmentServiceHelper.getEligibleILMABuyerGroups(iLMA.Membership__c, iLMA.Certified__c, account.Admin_Account__c);
        
        Set<String> buyerGroupIdsSet = new Set<String>();
        for (Buyer_Group_Membership__c bgm : buyerGroupMembershipList) {
            buyerGroupIdsSet.add(bgm.Buyer_Group__c);
        }
        
        return new List<String>(buyerGroupIdsSet);
    }

    public static List<String> getAllBuyerGroupAssignments(String accountId) {
        try {
            List<BuyerGroupMember> allBuyerGroups = B2BBuyerGroupAssignmentServiceHelper.getAllBuyerGroupAssignments(accountId);
            List<String> buyerGroupIds = new List<String>();
            
            if(allBuyerGroups != null) {
                for (BuyerGroupMember bgm : allBuyerGroups) {
                    buyerGroupIds.add(bgm.BuyerGroupId);
                }
            }
            return buyerGroupIds; 
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BBuyerGroupAssignmentService', 'getAllBuyerGroupAssignments');
            return null;
        }
    }
}