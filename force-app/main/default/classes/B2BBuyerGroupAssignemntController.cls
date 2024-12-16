public class B2BBuyerGroupAssignemntController {

    public static void handleBuyerGroupsForILMA(Account_Membership__c iLMA) {
        List<String> buyerGroupIdList = B2BBuyerGroupAssignmentService.getElibleILMABuyerGroups(iLMA);
        B2BBuyerGroupAssignmentService.createBuyerGroupMembers(buyerGroupIdList, iLMA.Account_Id__c);

        List<String> buyerGroupIdList_ToUnassign = B2BBuyerGroupAssignmentService.getInElibleILMABuyerGroups(iLMA);
        B2BBuyerGroupAssignmentService.deleteBuyerGroupMembers(buyerGroupIdList_ToUnassign, iLMA.Account_Id__c);
    }

    public static void handleBuyerGroupsForAccount(Account account) {
        List<Account_Membership__c> activeMemberships = B2BBuyerGroupAssignmentService.getActiveMemberships(account.Id);

        List<Buyer_Group_Membership__c> buyerGroupMembershipList = new List<Buyer_Group_Membership__c>();

        if(activeMemberships != null) {
            for(Account_Membership__c am : activeMemberships) {
                List<Buyer_Group_Membership__c> bgmList = B2BBuyerGroupAssignmentServiceHelper.getBuyerGroupMemberships(am.Membership__c, am.Certified__c);
                for(Buyer_Group_Membership__c bgm : bgmList) {
                    buyerGroupMembershipList.add(bgm);
                }
            }
        }
        else {
            List<Buyer_Group_Membership__c> bgmList = B2BBuyerGroupAssignmentServiceHelper.getBuyerGroupMemberships(null, false);
            for(Buyer_Group_Membership__c bgm : bgmList) {
                buyerGroupMembershipList.add(bgm);
            }
        }

        List<String> buyerGroupIdsToUnassign = B2BBuyerGroupAssignmentService.getBuyerGroupsToUnassign(account, buyerGroupMembershipList);
        List<String> buyerGroupIdsToAssign = B2BBuyerGroupAssignmentService.getBuyerGroupsToAssign(account, buyerGroupMembershipList);

        B2BBuyerGroupAssignmentService.deleteBuyerGroupMembers(buyerGroupIdsToUnassign, account.Id);
        B2BBuyerGroupAssignmentService.createBuyerGroupMembers(buyerGroupIdsToAssign, account.Id);
    }
}