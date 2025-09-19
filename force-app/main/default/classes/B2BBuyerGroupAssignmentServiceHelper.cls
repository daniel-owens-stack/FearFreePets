/**
 * @description       : 
 * @author            : Poojitha Anthati
 * @group             : 
 * @last modified on  : 09-18-2025
 * @last modified by  : Poojitha Anthati
**/
public class B2BBuyerGroupAssignmentServiceHelper {
    private static final String STANDARD_BUYER_GROUPS = System.Label.B2B_Standard_Buyer_Groups;

    public static List<Buyer_Group_Membership__c> getEligibleILMABuyerGroups(String membershipId, Boolean isCertified, Boolean isAdmin) {
        try {
            String role = getBuyerGroupRole(isAdmin);
            String query = 'SELECT Id, Membership__c, Buyer_Group__c' + 
                            ' FROM Buyer_Group_Membership__c' + 
                            ' WHERE (Membership__c =:membershipId OR Membership__c = NULL)' + 
                            ' AND (Role__c = \'All\' OR Role__c =:role)';

            if(!isCertified) {
                query += ' AND Certified__c = :isCertified';
            }

            return Database.query(query);
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BBuyerGroupAssignmentServiceHelper', 'getEligibleILMABuyerGroups');
            return null;
        }
    }

    public static List<Buyer_Group_Membership__c> getInEligibleILMABuyerGroups(String membershipId, Boolean isCertified, Boolean isAdmin) {
        try {
            String role = getBuyerGroupRole(isAdmin);
            String query = 'SELECT Id, Buyer_Group__c, Role__c' + 
                           ' FROM Buyer_Group_Membership__c' + 
                           ' WHERE (Membership__c =:membershipId OR Membership__c = NULL)' + 
                           ' AND Role__c =:role';

            if(!isCertified) {
                query += ' AND Certified__c = :isCertified';
            }

            return Database.query(query);
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BBuyerGroupAssignmentServiceHelper', 'getInEligibleILMABuyerGroups');
            return null;
        }
    }

    public static Account getAccountById(String accountId) {
        return [
            SELECT Id, Admin_Account__c
            FROM Account
            WHERE Id =:accountId
        ];
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
                SELECT Id, Name, Certified__c, Membership__c, Status__c, Account_Id__c 
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

    public static List<BuyerGroupMember> getExistingBuyerGroupAssignments(String accountId, List<String> buyerGroupIds) {

        List<BuyerGroupMember> buyerGroupMembers = [
            SELECT Id, BuyerGroupId, BuyerId
            FROM BuyerGroupMember
            WHERE BuyerGroupId IN :buyerGroupIds
            AND BuyerId = :accountId
        ];
        return buyerGroupMembers.isEmpty() ? null : buyerGroupMembers; 
    }

    public static List<BuyerGroupMember> getAllBuyerGroupAssignments(String accountId) {

        List<String> standardBuyerGroups = new List<String>();
        if (!String.isBlank(STANDARD_BUYER_GROUPS)) {
            standardBuyerGroups = new List<String>(STANDARD_BUYER_GROUPS.split(','));
        }
        
        List<BuyerGroupMember> buyerGroupMembers = [
            SELECT Id, BuyerGroupId, BuyerId
            FROM BuyerGroupMember
            WHERE BuyerId = :accountId
            AND BuyerGroup.Name  NOT IN :standardBuyerGroups
        ];
        return buyerGroupMembers.isEmpty() ? null : buyerGroupMembers; 
    }
}