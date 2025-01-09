public class B2BHandleSchooxJobAssignmentInvokable {

    @InvocableMethod(label='Handle Schoox Job Assignment' description='Processes a list of Account Membership records and make callouts to Schoox API.')
    public static void handleSchooxJobAssignment(List<List<Account_Membership__c>> accountMembershipLists) {
        List<Account_Membership__c> accountMembershipList = accountMembershipLists[0];
        
        if (accountMembershipList == null || accountMembershipList.isEmpty()) {
            return; 
        }

        for (Account_Membership__c membership : accountMembershipList) {
            try {
                String accountId = membership.Account_Id__c;

                List<Integer> jobIdsToAdd = new List<Integer>();
                jobIdsToAdd.add(Integer.valueOf(membership.Job_Id__c));
                
                System.enqueueJob(new B2BSchooxJobAssignmentQueueable(accountId, jobIdsToAdd));
            }
            catch (Exception e) {
                B2BHandleCustomException.LogException(e, 'B2BHandleSchooxJobAssignmentInvokable', 'handleSchooxJobAssignment');
            }
        }
    }
}