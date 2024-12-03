public class B2BBuyerGroupAssignemntController {

    public static void handleBuyerGroupsForILMA(Account_Membership__c iLMA) {
        List<String> buyerGroupIdList = B2BBuyerGroupAssignmentService.getElibleILMABuyerGroups(iLMA);
        B2BBuyerGroupAssignmentService.createBuyerGroupMembers(buyerGroupIdList, iLMA.Account_Id__c);

    }

    public static void handleBuyerGroupsForAccount(Account account) {
        List<String> activeMembershipIds = B2BBuyerGroupAssignmentService.getActiveMemberships(account.Id);
        List<Buyer_Group_Membership__c> buyerGroupMembershipList = B2BBuyerGroupAssignmentServiceHelper.getBuyerGroupMemberships(activeMembershipIds);

        List<String> buyerGroupIdsToUnassign = B2BBuyerGroupAssignmentService.getBuyerGroupsToUnassign(account, buyerGroupMembershipList);
        List<String> buyerGroupIdsToAssign = B2BBuyerGroupAssignmentService.getBuyerGroupsToAssign(account, buyerGroupMembershipList);

        B2BBuyerGroupAssignmentService.deleteBuyerGroupMembers(buyerGroupIdsToUnassign, account.Id);
        B2BBuyerGroupAssignmentService.createBuyerGroupMembers(buyerGroupIdsToAssign, account.Id);
    }
}