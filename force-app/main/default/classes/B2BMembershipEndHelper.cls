public class B2BMembershipEndHelper {

    public static List<Id> getBuyerGroupMemberships(String membershipId) {
        try {
            List<Buyer_Group_Membership__c> bgmList = [
                SELECT Id, Buyer_Group__c 
                FROM Buyer_Group_Membership__c 
                WHERE Membership__c = :membershipId
            ];

            List<Id> buyerGroupIds = new List<Id>();
            if(bgmList.size() > 0) {
                for(Buyer_Group_Membership__c bgm : bgmList) {
                    buyerGroupIds.add(bgm.Buyer_Group__c);
                }
                return buyerGroupIds;
            }
            return null;
        } 
        catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BMembershipEndHelper', 'getBuyerGroupMembership');
            return null;
        }
    }
    
    public static List<Account_Membership__c> getActiveILMAofSameType(String accountId, String membershipId) {
        try {
            List<Account_Membership__c> activeILMAs = [SELECT Id 
                                                       FROM Account_Membership__c 
                                                       WHERE Account_Id__c = :accountId  
                                                       AND Membership__c = :membershipId
                                                       AND Status__c = 'Active'
                                                      ];

            if(activeILMAs.size() > 0) {
                return activeILMAs;
            }
            return null;
        }
        catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BMembershipEndHelper', 'getActiveILMAofSameType');
            return null;
        }
    }

    public static void unassignBuyerGroups(String accountId, List<Id> buyerGroupIds) {
        try {
            List<BuyerGroupMember> buyerGroupsAssignments = [
                SELECT Id 
                FROM BuyerGroupMember 
                WHERE BuyerId = :accountId 
                AND BuyerGroupId IN :buyerGroupIds
            ];

            if(buyerGroupsAssignments.size() > 0) {
                delete buyerGroupsAssignments;
            }
        } 
        catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BMembershipEndHelper', 'unassignBuyerGroups');
        }
    }
}