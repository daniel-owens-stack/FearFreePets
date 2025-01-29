public class B2BMembershipEndController {
    
    public static void handleMembershipUnassignment(Account_Membership__c ilma) {

        try {
            String membershipId = ilma.Membership__c;
            Set<Id> membershipEndedAccounts = new Set<Id>(); 

            //Get AccountId(s) of canceled or complete or voided ILMAs
            if(ilma.Account_Id__c != null && (ilma.Status__c == 'Canceled' || ilma.Status__c == 'Complete' || ilma.Status__c == 'Voided')) {
                membershipEndedAccounts.add((Id)ilma.Account_Id__c);
            }

            //Get AccountId(s) of unassigned or unassigned and then reassigned ILMAs
            if(ilma.Account_Id__c == null || ilma.can_be_fully_reassigned__c) {

                List<Account_Membership__History> fieldHistory = [
                    SELECT Field, OldValue, NewValue, CreatedDate
                    FROM Account_Membership__History
                    WHERE ParentId = :ilma.Id
                    AND Field = 'Account_Id__c'
                    AND DataType = 'EntityId'
                    AND CreatedDate = TODAY
                    ORDER BY CreatedDate ASC
                ];

                if(fieldHistory.size() > 0) {
                    for (Account_Membership__History amh : fieldHistory) {
                        if (amh.OldValue != null && amh.OldValue != amh.NewValue) {
                            membershipEndedAccounts.add((Id)amh.OldValue);
                        }
                    }
                }
            }

            if(!membershipEndedAccounts.isEmpty()) {

                List<Id> buyerGroupIds = B2BMembershipEndHelper.getBuyerGroupMemberships(membershipId);
                List<Integer> jobIds = new List<Integer>();

                for(Id accountId : membershipEndedAccounts) {
                    //Check if account currently have an active ILMA of same membership
                    List<Account_Membership__c> activeILMAs = B2BMembershipEndHelper.getActiveILMAofSameType(accountId, membershipId);

                    if(activeILMAs == null) {
                        //Unassign buyer groups
                        if(buyerGroupIds != null) {
                            B2BMembershipEndHelper.unassignBuyerGroups(accountId, buyerGroupIds);
                        }

                        //Unassign Schoox Jobs
                        jobIds.add(Integer.valueOf(ilma.Job_Id__c));
                        if(jobIds != null) {
                            B2BMembershipEndHelper.unassignSchooxJobs(accountId, jobIds);
                        }
                    }
                }
            }
        }
        catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BMembershipEndController', 'handleMembershipUnassignment');
        }
    }
}