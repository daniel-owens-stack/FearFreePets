/**
 * @description       : 
 * @author            : Poojitha Anthati
 * @group             : 
 * @last modified on  : 10-16-2025
 * @last modified by  : Poojitha Anthati
**/
public class B2BHandleMembershipAssignmentQueueable implements Queueable, Database.AllowsCallouts {

    private List<Account_Membership__c> membershipList;

    public B2BHandleMembershipAssignmentQueueable(List<Account_Membership__c> membershipList) {
        this.membershipList = membershipList;
    }

    public void execute(QueueableContext context) {
        for (Account_Membership__c membership : membershipList) {
            try {
                B2BBuyerGroupAssignemntController.handleBuyerGroupsForILMA(membership);
            } catch (Exception e) {
                B2BHandleCustomException.LogException(e, 'B2BHandleMembershipAssignmentQueueable', 'execute');
            }
        }
    }
}