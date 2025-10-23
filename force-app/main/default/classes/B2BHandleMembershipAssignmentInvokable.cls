/**
 * @description       : 
 * @author            : Poojitha Anthati
 * @group             : 
 * @last modified on  : 10-16-2025
 * @last modified by  : Poojitha Anthati
**/
public class B2BHandleMembershipAssignmentInvokable {

    @InvocableMethod(label='Handle Commerce on Membership Assignment' description='Processes a list of Account Membership records and assigns commerce-related buyer groups.')
    public static void handleCommerceOnMembershipAssignment(List<List<Account_Membership__c>> accountMembershipLists) {
        for(List<Account_Membership__c> ilmaList : accountMembershipLists){
            List<Account_Membership__c> accountMembershipList = ilmaList;
            
            if (accountMembershipList == null || accountMembershipList.isEmpty()) {
                return; 
            }

            Integer chunkSize = 20;
            Integer total = accountMembershipList.size();

            // Split into chunks to avoid hitting governor limits
            for (Integer i = 0; i < total; i += chunkSize) {
                Integer endIndex = Math.min(i + chunkSize, total);
                List<Account_Membership__c> membershipsList = new List<Account_Membership__c>();

                for (Integer j = i; j < endIndex; j++) {
                    membershipsList.add(accountMembershipList[j]);
                }

                System.enqueueJob(new B2BHandleMembershipAssignmentQueueable(membershipsList));
            }
        }
    }
}