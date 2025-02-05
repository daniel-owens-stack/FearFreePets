public class B2BHandleSchooxJobAssignmentInvokable {

    @InvocableMethod(label='B2B Handle Schoox Job Assignment' description='Processes a list of Account Membership records and make callouts to Schoox API.')
    public static void handleSchooxJobAssignment(List<B2BSchooxAccountJobWrapper> accountJobWrapperLists) { 

        List<Account_Membership__c> accountMembershipList = accountJobWrapperLists[0].accountMemberships;
        List<Integer> permanentMembershipJobIds = accountJobWrapperLists[0].permanentMembershipJobIds;
        String orderSummary_AccountId = accountJobWrapperLists[0].orderSummary_AccountId;

        if(accountMembershipList == null && permanentMembershipJobIds == null) {
            return;
        }

        try {

            Map<String, List<Integer>> accountJobMap = new Map<String, List<Integer>>();

            if(accountMembershipList != null && !accountMembershipList.isEmpty()) {
                for (Account_Membership__c am : accountMembershipList) {
                    if (am.Account_Id__c != null && am.Job_Id__c != null) {
                        if (!accountJobMap.containsKey(am.Account_Id__c)) {
                            accountJobMap.put(am.Account_Id__c, new List<Integer>());
                        }
                        accountJobMap.get(am.Account_Id__c).add(Integer.valueOf(am.Job_Id__c));
                    }
                }
            }

            if(permanentMembershipJobIds != null && !permanentMembershipJobIds.isEmpty()) {
                for (Integer jobId : permanentMembershipJobIds) {
                    if (orderSummary_AccountId != null && jobId != null) {
                        if (!accountJobMap.containsKey(orderSummary_AccountId)) {
                            accountJobMap.put(orderSummary_AccountId, new List<Integer>());
                        }
                        accountJobMap.get(orderSummary_AccountId).add(jobId);
                    }
                }
            }
            
            for (String accountId : accountJobMap.keySet()) {
                B2BSchooxAPIController.handleJobAssignmnet(accountId, accountJobMap.get(accountId));
            }
        }
        catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BHandleSchooxJobAssignmentInvokable', 'handleSchooxJobAssignment');
        }
    }
}