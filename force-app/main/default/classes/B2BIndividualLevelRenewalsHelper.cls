public class B2BIndividualLevelRenewalsHelper {

    public static List<Account_Membership__c> getEligibleMembershipAssignments(String parentAccountId) {
        try {
            Map<String,String> minMaxDates = B2BUtils.calculateMinMaxRenewalOffsetRange();
            String minDate = minMaxDates.get('minDate');
            String maxDate = minMaxDates.get('maxDate');

            String queryString = 'SELECT Id, Account_Id__c, Membership__c, Practice_Level_Membership_Assignment__c, Parent_Id__c ' +
                                 'FROM Account_Membership__c ' +
                                 'WHERE Expiration_Date__c >= ' + minDate + ' AND Expiration_Date__c <= ' + maxDate +
                                 ' AND Status__c != \'Canceled\' AND Status__c != \'Voided\'' +
                                 ' AND Parent_Id__c = :parentAccountId';

            List<Account_Membership__c> memberships = Database.query(queryString);

            return memberships.isEmpty() ? null : memberships;
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BIndividualLevelRenewalsHelper', 'getEligibleMembershipAssignments');
            return null;
        }
    }

    public static String getWebStoreIdByName(String storeName) {
        try {
            return [
                SELECT Id 
                FROM WebStore 
                WHERE Name = :storeName 
                LIMIT 1
            ].Id;
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BIndividualLevelRenewalsHelper', 'getWebStoreIdByName');
            return null;
        }
    }

    public static Date getEffectiveOrderDate(String paymentTerms) {
        try {
            return B2BUtils.getTargetRenewalDate();
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BIndividualLevelRenewalsHelper', 'getEffectiveOrderDate');
            return null;
        }
    }

    public static String getOrderDeliveryMethodId() {
        try {
            return [
                SELECT Id, Name 
                FROM OrderDeliveryMethod
                LIMIT 1
            ].Id;
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BIndividualLevelRenewalsHelper', 'getOrderDeliveryMethodId');
            return null;
        }
    }

    public static String getRenewalProductId(String membershipId) {
        try {
            return [
                SELECT Id, Membership__c 
                FROM Product2 
                WHERE Membership__c = :membershipId
            ].Id;
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BIndividualLevelRenewalsHelper', 'getRenewalProductId');
            return null;
        }
    }

    public static Decimal getRenewalProductPrice(String accountId, String productId) {

        try {
            return B2BUtils.getProductPriceByAccountId(accountId, productId);
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BIndividualLevelRenewalsHelper', 'getRenewalProductPrice');
            return null;
        }
    }

    public static String getExistingOrderId(Account account) {
        try {
            List<Order> orders = [
                SELECT Id 
                FROM Order 
                WHERE AccountId = :account.Id 
                AND IsRenewal__c = true 
                AND CreatedDate = TODAY
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            return orders.size() > 0 ? orders[0].Id : null;
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BIndividualLevelRenewalsHelper', 'getExistingOrderId');
            return null;
        }
    }

    public static String getOrderDeliveryGroupId(String orderId) {
        try {
            return [
                SELECT Id
                FROM OrderDeliveryGroup
                WHERE OrderId = :orderId
                LIMIT 1
            ].Id;
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BIndividualLevelRenewalsHelper', 'getOrderDeliveryGroupId');
            return null;
        }
    }
}