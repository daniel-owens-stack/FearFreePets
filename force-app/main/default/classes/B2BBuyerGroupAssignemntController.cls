/**
 * @description       : 
 * @author            : Poojitha Anthati
 * @group             : 
 * @last modified on  : 09-18-2025
 * @last modified by  : Poojitha Anthati
**/
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

    public static void handleBuyerGroupsSync(Account account) {
        List<String> existingBuyerGroupIds = B2BBuyerGroupAssignmentService.getAllBuyerGroupAssignments(account.Id);
        System.debug('## Existing Buyer Groups:' + existingBuyerGroupIds);

        List<Account_Membership__c> activeILMAs = B2BBuyerGroupAssignmentService.getActiveMemberships(account.Id);

        if(activeILMAs != null) {
            Set<String> eligibleBuyerGroupIdsSet = new Set<String>();

            for(Account_Membership__c am : activeILMAs) {
                eligibleBuyerGroupIdsSet.addAll(B2BBuyerGroupAssignmentService.getEligibleBuyerGroups(am));
            }
            List<String> buyerGroupIdsToAssign = new List<String>(eligibleBuyerGroupIdsSet);
            System.debug('## Buyer group ids to Assign:' + buyerGroupIdsToAssign);

            List<String> buyerGroupIdsToUnassign = new List<String>();
            for (String id : existingBuyerGroupIds) {
                if (!buyerGroupIdsToAssign.contains(id)) {
                    buyerGroupIdsToUnassign.add(id);
                }
            }
            System.debug('## Buyer group ids to Unassign:' + buyerGroupIdsToUnassign);
            if(buyerGroupIdsToUnassign != null) {
                B2BBuyerGroupAssignmentService.deleteBuyerGroupMembers(buyerGroupIdsToUnassign, account.Id); 
            }

            List<String> missedBuyerGroupIdsToAssign = new List<String>();
            for(String id : buyerGroupIdsToAssign) {
                if(!existingBuyerGroupIds.contains(id)) {
                    missedBuyerGroupIdsToAssign.add(id);
                }
            }
            System.debug('## Missed Buyer group ids to Assign:' + missedBuyerGroupIdsToAssign);
            if(missedBuyerGroupIdsToAssign != null){
                B2BBuyerGroupAssignmentService.createBuyerGroupMembers(missedBuyerGroupIdsToAssign, account.Id);
            }
        } 
        else if(existingBuyerGroupIds != null) {
            B2BBuyerGroupAssignmentService.deleteBuyerGroupMembers(existingBuyerGroupIds, account.Id);
        }
    }
}