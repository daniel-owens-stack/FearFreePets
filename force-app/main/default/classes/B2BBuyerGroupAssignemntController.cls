public class B2BBuyerGroupAssignemntController {

    public static void handleBuyerGroupsForILMA(Account_Membership__c iLMA) {
        if(iLMA.Account_Id__c != null) {
            List<String> buyerGroupIdList = B2BBuyerGroupAssignmentService.getEligibleILMABuyerGroups(iLMA);
        
            B2BBuyerGroupAssignmentService.createBuyerGroupMembers(buyerGroupIdList, iLMA.Account_Id__c);
        }
    }

    public static void handleBuyerGroupsForAccount(Account account) {
        List<Account_Membership__c> activeMemberships = B2BBuyerGroupAssignmentService.getActiveMemberships(account.Id);

        if(activeMemberships != null) {

            Set<String> buyerGroupIdsToAssignSet = new Set<String>();
            Set<String> buyerGroupIdsToUnassignSet = new Set<String>();

            for(Account_Membership__c am : activeMemberships) {
                buyerGroupIdsToAssignSet.addAll(B2BBuyerGroupAssignmentService.getEligibleILMABuyerGroups(am));
                buyerGroupIdsToUnassignSet.addAll(B2BBuyerGroupAssignmentService.getInEligibleILMABuyerGroups(am));
            }

            List<String> buyerGroupIdsToAssign = new List<String>(buyerGroupIdsToAssignSet);
            List<String> buyerGroupIdsToUnassign = new List<String>(buyerGroupIdsToUnassignSet);

            B2BBuyerGroupAssignmentService.deleteBuyerGroupMembers(buyerGroupIdsToUnassign, account.Id);
            B2BBuyerGroupAssignmentService.createBuyerGroupMembers(buyerGroupIdsToAssign, account.Id);
        }
    }
}