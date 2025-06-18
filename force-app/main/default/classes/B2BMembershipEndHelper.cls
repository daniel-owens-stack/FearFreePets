public class B2BMembershipEndHelper {

    private static final List<String> GENERIC_BUYER_GROUPS = new List<String>{
        System.Label.B2B_Active_Member_All_BuyerGroup,
        System.Label.B2B_Certified_Member_All_BuyerGroup,
        System.Label.B2B_Certified_Individual_Veterinary_All_BuyerGroup
    };
    
    public static List<Id> getBuyerGroupMemberships(String membershipId, Boolean isCertified, Boolean isAdmin) {
        try {
            String role = isAdmin ? 'Admin' : 'Non Admin';
            String query = 'SELECT Id, Buyer_Group__c, Role__c' + 
                           ' FROM Buyer_Group_Membership__c' + 
                           ' WHERE Membership__c =:membershipId' + 
                           ' AND Role__c =:role';

            if(!isCertified) {
                query += ' AND Certified__c = :isCertified';
            }

            List<Buyer_Group_Membership__c> bgmList = Database.query(query);

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

    public static Boolean getAccountRole(String accountId) {
        return [SELECT Admin_Account__c FROM Account WHERE Id = :accountId LIMIT 1].Admin_Account__c;
    }

    public static Boolean hasActiveILMAs(String accountId) {
        try {
            List<Account_Membership__c> activeILMAs = [SELECT Id 
                                                       FROM Account_Membership__c 
                                                       WHERE Account_Id__c = :accountId
                                                       AND Status__c = 'Active'
                                                      ];

            if(activeILMAs.size() > 0) {
                return true;
            }
            return false;
        }
        catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BMembershipEndHelper', 'hasActiveILMAs');
            return false;
        }
    }

    public static List<Id> getBuyerGroupsFromAccount(String accountId) {
        try {
            List<BuyerGroupMember> bgmList = [
                SELECT Id, BuyerGroupId
                FROM BuyerGroupMember 
                WHERE BuyerGroup.Name IN :GENERIC_BUYER_GROUPS 
                AND BuyerId = :accountId
            ];

            List<Id> buyerGroupIds = new List<Id>();
            if(bgmList.size() > 0) {
                for(BuyerGroupMember bgm : bgmList) {
                    buyerGroupIds.add(bgm.BuyerGroupId);
                }
                return buyerGroupIds;
            }
            return null;
        } 
        catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BMembershipEndHelper', 'getBuyerGroupsFromAccount');
            return null;
        }
    }

    public static void updateILMAsStatusAsExpired(List<Account_Membership__c> ilmas) {
        try {
            List<Account_Membership__c> ilmasToUpdate = new List<Account_Membership__c>();

            for(Account_Membership__c ilma : ilmas) {
                ilma.Status__c = 'Complete';
                ilmasToUpdate.add(ilma);
            }
            
            if(ilmasToUpdate.size() > 0) {
                update ilmasToUpdate;
            }
        }
        catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BMembershipEndHelper', 'updateILMAsStatusAsExpired');
        }
    }
}