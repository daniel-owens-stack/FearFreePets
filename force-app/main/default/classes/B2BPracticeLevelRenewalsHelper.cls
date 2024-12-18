public with sharing class B2BPracticeLevelRenewalsHelper {

    public static List<Practice_Level_Membership_Assignment__c> getEligibleMembershipAssignments(String businessAccountId) {
        try {
            Map<String,String> minMaxDates = B2BUtils.calculateMinMaxRenewalOffsetRange();
            String minDate = minMaxDates.get('minDate');
            String maxDate = minMaxDates.get('maxDate');
            
            String queryString = 'SELECT Id, Business_Account__c, Membership__c, Renewal_DVM_Count__c' +
                                 ' FROM Practice_Level_Membership_Assignment__c' +
                                 ' WHERE Expiration_Date__c >= ' + minDate + ' AND Expiration_Date__c <= ' + maxDate + 
                                 ' AND Status__c != \'Canceled\' AND Status__c != \'Voided\'' +
                                 ' AND Business_Account__c = :businessAccountId';

            List<Practice_Level_Membership_Assignment__c> memberships = Database.query(queryString);
            
            return memberships.isEmpty() ? null : memberships;
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BPracticeLevelRenewalsHelper', 'getEligibleMembershipAssignments');
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
            B2BHandleCustomException.LogException(e, 'B2BPracticeLevelRenewalsHelper', 'getWebStoreIdByName');
            return null;
        }
    }

    public static String getRenewalProductId(String membershipId, Decimal renewalDVMCount) {
        try {
            return [
                SELECT Id, Membership__c 
                FROM Product2 
                WHERE Renewal_DVM_Count_MIN__c <= :renewalDVMCount 
                AND Renewal_DVM_Count_MAX__c >= :renewalDVMCount 
                AND Membership__c = :membershipId
                LIMIT 1
            ].Id;
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BPracticeLevelRenewalsHelper', 'getRenewalProductId');
            return null;
        }
    }

    public static Decimal getRenewalProductPrice(String productId, String businessAccountId) {
        try {
            String teamAdminId = [
                SELECT Id FROM
                Account
                WHERE Business__c =:businessAccountId
                AND IsPersonAccount = TRUE
                AND Admin_Account__c = TRUE
            ].Id;

            return B2BUtils.getProductPriceByAccountId(teamAdminId, productId);

        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BPracticeLevelRenewalsHelper', 'getRenewalProductPrice');
            return null;
        }
    }
    
    public static Date getEffectiveOrderDate(B2BPracticeLevelRenewalsWrapper.BusinessAccount businessAccount) {
        try {
            Date targetRenewalDate;
            if (businessAccount.payment_terms == 'Credit Card Only'){
                targetRenewalDate = businessAccount.practiceLevelRenewalDate;
            } 
            else {
                targetRenewalDate = B2BUtils.getTargetRenewalDate();
            }
            return targetRenewalDate;
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BPracticeLevelRenewalsHelper', 'getEffectiveOrderDate');
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
            B2BHandleCustomException.LogException(e, 'B2BPracticeLevelRenewalsHelper', 'getOrderDeliveryMethodId');
            return null;
        }
    }   
}