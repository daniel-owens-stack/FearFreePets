public class B2BHandleMembershipAssignmentInvokable {

    @InvocableMethod(label='Handle Commerce on Membership Assignment' description='Processes a list of Account Membership records and assigns commerce-related buyer groups.')
    public static void handleCommerceOnMembershipAssignment(List<List<Account_Membership__c>> accountMembershipLists) {
        for(List<Account_Membership__c> ilmaList : accountMembershipLists){
            List<Account_Membership__c> accountMembershipList = ilmaList;
            
            if (accountMembershipList == null || accountMembershipList.isEmpty()) {
                return; 
            }

            for (Account_Membership__c membership : accountMembershipList) {
                try {
                    B2BBuyerGroupAssignemntController.handleBuyerGroupsForILMA(membership);
                }
                catch (Exception e) {
                    B2BHandleCustomException.LogException(e, 'B2BHandleMembershipAssignmentInvokable', 'handleCommerceOnMembershipAssignment');
                }
            }
        }
    }
}