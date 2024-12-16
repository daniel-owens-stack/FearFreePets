public class B2BBuyerGroupAssignmentServiceHelper {
    public static List<Buyer_Group_Membership__c> getElibleILMABuyerGroups(String membershipId, Boolean isCertified, Boolean isAdmin) {
        String role = getBuyerGroupRole(isAdmin);
        return [
            SELECT Id, Membership__c, Buyer_Group__c 
            FROM Buyer_Group_Membership__c 
            WHERE Certified__c =: isCertified 
            AND (Membership__c =:membershipId OR Membership__c = NULL)
            AND (Role__c = 'All' OR Role__c =:role)
        ];
    }

    public static Account getAccountById(String accountId) {
        return [
            SELECT Id, Admin_Account__c
            FROM Account
            WHERE Id =:accountId
        ];
    }

    public static List<BuyerGroupMember> getExistingBuyerAccounts(List<String> buyerGroupIds) {

        List<BuyerGroupMember> buyerGroupMembers = [
            SELECT Id, BuyerGroupId
            FROM BuyerGroupMember
            WHERE BuyerGroupId IN:buyerGroupIds
        ];
        return buyerGroupMembers.isEmpty() ? null : buyerGroupMembers; 
    }

    public static String getBuyerGroupRole(Boolean isAdmin) {
        if (isAdmin == true) {
            return 'Admin';
        }
        return 'Non Admin';
    }

    public static List<Account_Membership__c> getActiveIndividualMembershipAssignments(String accountId) {
        try {
            List<Account_Membership__c> accountMemberships = [
                SELECT Id, Name, Certified__c, Membership__c, Status__c 
                FROM Account_Membership__c 
                WHERE Account_Id__c = :accountId
                AND Status__c = 'Active'
                ORDER BY CreatedDate DESC
            ];
            return accountMemberships.isEmpty() ? null : accountMemberships;
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BBuyerGroupAssignmentServiceHelper', 'getActiveIndividualMembershipAssignments');
            return null;
        }
    }

    public static List<Buyer_Group_Membership__c> getBuyerGroupMemberships(String membershipId, Boolean isCertified) {
        try {
            return [
                SELECT Id, Buyer_Group__c, Role__c 
                FROM Buyer_Group_Membership__c
                WHERE Role__c != 'All'
                AND Certified__c = :isCertified 
                AND (Membership__c = :membershipId OR Membership__c = NULL)
            ];
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BBuyerGroupAssignmentServiceHelper', 'getBuyerGroupMemberships');
            return null;
        }
    }

    public static List<BuyerGroupMember> getExistingBuyerGroupAssignments(String accountId, List<String> buyerGroupIds) {

        List<BuyerGroupMember> buyerGroupMembers = [
            SELECT Id, BuyerGroupId, BuyerId
            FROM BuyerGroupMember
            WHERE BuyerGroupId IN :buyerGroupIds
            AND BuyerId = :accountId
        ];
        return buyerGroupMembers.isEmpty() ? null : buyerGroupMembers; 
    }

    public static List<String> getRoleSpecificBuyerGroups(List<Buyer_Group_Membership__c> buyerGroupMembershipList, Boolean isAdmin) {

        List<String> adminBuyerGroupIds = new List<String>();
        List<String> nonAdminBuyerGroupIds =  new List<String>();

        for(Buyer_Group_Membership__c buyerGroupMembership : buyerGroupMembershipList) {
            if(buyerGroupMembership.Role__c == 'Admin') {
                adminBuyerGroupIds.add(buyerGroupMembership.Buyer_Group__c);
            }
            else if(buyerGroupMembership.Role__c == 'Non Admin') {
                nonAdminBuyerGroupIds.add(buyerGroupMembership.Buyer_Group__c);
            }
        }
        return isAdmin ? adminBuyerGroupIds : nonAdminBuyerGroupIds;
    }
}