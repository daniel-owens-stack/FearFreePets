public class B2BHandleMembershipAssignmentInvokable {

    @InvocableMethod(label='Handle Commerce on Membership Assignment' description='Processes a list of Account Membership records and assigns commerce-related buyer groups.')
    public static void handleCommerceOnMembershipAssignment(List<List<Account_Membership__c>> accountMembershipLists) {
        List<Account_Membership__c> accountMembershipList = accountMembershipLists[0];
        
        if (accountMembershipList == null || accountMembershipList.isEmpty()) {
            return; 
        }

        for (Account_Membership__c membership : accountMembershipList) {
            try {

                B2BBuyerGroupAssignemntController.handleBuyerGroupsForILMA(membership);

                String accountId = membership.Account_Id__c;
                List<Integer> jobIdsToAdd = new List<Integer>();
                jobIdsToAdd.add(Integer.valueOf(membership.Job_Id__c));
                
               // System.enqueueJob(new B2BSchooxJobAssignmentQueueable(accountId, jobIdsToAdd));
                
            }
            catch (Exception e) {
                B2BHandleCustomException.LogException(e, 'B2BHandleMembershipAssignmentInvokable', 'handleCommerceOnMembershipAssignment');
            }
        }
    }
}