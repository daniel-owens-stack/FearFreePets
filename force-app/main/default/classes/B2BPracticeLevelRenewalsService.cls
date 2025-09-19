public class B2BPracticeLevelRenewalsService {
    // private static final String WEB_STORE_NAME = System.Label.B2B_WebStore_Name;
    
    // public static List<B2BPracticeLevelRenewalsWrapper.PracticeLevelMembershipAssignment> getPracticeLevelMembershipAssignments(String businessAccountId) {
        
    //     List<Practice_Level_Membership_Assignment__c> plmasSObjectList = B2BPracticeLevelRenewalsHelper.getEligibleMembershipAssignments(businessAccountId);
        
    //     if (plmasSObjectList == null || plmasSObjectList.isEmpty()) {
    //         return null;
    //     }
        
    //     List <B2BPracticeLevelRenewalsWrapper.PracticeLevelMembershipAssignment> plmaWrapperList = new List <B2BPracticeLevelRenewalsWrapper.PracticeLevelMembershipAssignment> ();

    //     for (Practice_Level_Membership_Assignment__c plmasSObject : plmasSObjectList) {
            
    //         B2BPracticeLevelRenewalsWrapper.PracticeLevelMembershipAssignment plmaWrapper = new B2BPracticeLevelRenewalsWrapper.PracticeLevelMembershipAssignment();
            
    //         plmaWrapper.id = plmasSObject.Id;
    //         plmaWrapper.business_account = plmasSObject.Business_Account__c;
    //         plmaWrapper.membership_id = plmasSObject.Membership__c;
    //         plmaWrapper.expirationDate = plmasSObject.Expiration_Date__c;
    //         plmaWrapper.renewal_dvm_count = plmasSObject.Renewal_DVM_Count__c == 0 ? 1 : plmasSObject.Renewal_DVM_Count__c;
            
    //         plmaWrapper.renewal_product_id = B2BPracticeLevelRenewalsHelper.getRenewalProductId( plmaWrapper.membership_id, plmaWrapper.renewal_dvm_count);
    //         plmaWrapper.renewal_price = B2BPracticeLevelRenewalsHelper.getRenewalProductPrice(plmaWrapper.renewal_product_id, plmaWrapper.business_account);
            
    //         plmaWrapperList.add(plmaWrapper);
    //     }
        
    //     return plmaWrapperList;
    // } 
    
    
    // public static B2BPracticeLevelRenewalsWrapper.BusinessAccount getBusinessAccount(Account businessAccountSObject, Date renewalDate) {
        
    //     B2BPracticeLevelRenewalsWrapper.BusinessAccount businessAccount = new B2BPracticeLevelRenewalsWrapper.BusinessAccount();
        
    //     businessAccount.account_id = businessAccountSObject.Id;
    //     businessAccount.name = businessAccountSObject.Name;
    //     businessAccount.billing_email = businessAccountSObject.Billing_Email__c;
    //     businessAccount.billing_email_verified = businessAccountSObject.Billing_Email_Verified__c;
    //     businessAccount.billing_address = businessAccountSObject.BillingAddress;
    //     businessAccount.shipping_address = businessAccountSObject.BillingAddress;
    //     businessAccount.payment_terms = businessAccountSObject.Payment_Terms__c;
    //     businessAccount.practiceLevelRenewalDate = renewalDate;//businessAccountSObject.PracticeLevelRenewalDate__c;
        
    //     return businessAccount;
    // }

    // public static  B2BPracticeLevelRenewalsWrapper.Order createOrder(B2BPracticeLevelRenewalsWrapper.BusinessAccount businessAccount) {
        
    //     Order order = new Order();
    //     order.Name = businessAccount.account_id + ' Membership Renewal';
    //     order.AccountId = businessAccount.account_id;
    //     order.OrderedDate = DateTime.now();
    //     order.PoNumber = 'Membership Renewal';
    //     order.EffectiveDate = B2BPracticeLevelRenewalsHelper.getEffectiveOrderDate(businessAccount);
    //     order.SalesStoreId = B2BPracticeLevelRenewalsHelper.getWebStoreIdByName(WEB_STORE_NAME);
    //     order.Status = 'Draft';
    //     order.BillingStreet = businessAccount.billing_address.street;
    //     order.BillingCity = businessAccount.billing_address.city;
    //     order.BillingState = businessAccount.billing_address.state;
    //     order.BillingPostalCode = businessAccount.billing_address.postalCode;
    //     order.BillingCountry = businessAccount.billing_address.country;
    //     order.ShippingStreet = businessAccount.shipping_address.street;
    //     order.ShippingCity = businessAccount.shipping_address.city;
    //     order.ShippingState = businessAccount.shipping_address.state;
    //     order.ShippingPostalCode = businessAccount.shipping_address.postalCode;
    //     order.ShippingCountry = businessAccount.shipping_address.country;
    //     order.IsRenewal__c = true;
        
    //     insert order;

    //     OrderDeliveryGroup odg = new OrderDeliveryGroup();
        
    //     odg.OrderId = order.Id;
    //     odg.DeliverToName = businessAccount.name;
    //     odg.DeliverToStreet = businessAccount.shipping_address.street;
    //     odg.DeliverToCity = businessAccount.shipping_address.city;
    //     odg.DeliverToState = businessAccount.shipping_address.state;
    //     odg.DeliverToPostalCode = businessAccount.shipping_address.postalCode;
    //     odg.DeliverToCountry = businessAccount.shipping_address.country;
    //     odg.OrderDeliveryMethodId = B2BPracticeLevelRenewalsHelper.getOrderDeliveryMethodId();
    
    //     insert odg;
        
    //     B2BPracticeLevelRenewalsWrapper.Order orderWrapper = new B2BPracticeLevelRenewalsWrapper.Order();

    //     orderWrapper.id = order.Id;
    //     orderWrapper.order_delivery_group_id = odg.Id;
        
    //     return orderWrapper;
    // }

    // public static void createOrderItems( List<B2BPracticeLevelRenewalsWrapper.PracticeLevelMembershipAssignment> plmaList, B2BPracticeLevelRenewalsWrapper.Order order) {
        
    //     List<OrderItem> orderItemList = new List<OrderItem>();

    //     for (B2BPracticeLevelRenewalsWrapper.PracticeLevelMembershipAssignment plma : plmaList) {
    //         OrderItem oi = new OrderItem();
            
    //         oi.OrderId = order.id;
    //         oi.OrderDeliveryGroupId = order.order_delivery_group_id;
    //         oi.Product2Id = plma.renewal_product_id;
    //         oi.Quantity = 1;
    //         oi.UnitPrice = plma.renewal_price;
    //         oi.ListPrice = plma.renewal_price;
    //         oi.TotalLineAmount = plma.renewal_price;
    //         oi.Type = 'Order Product';
    //         oi.Membership_Renewal__c = true;
    //         oi.Practice_Membership_Assignment__c = plma.id;

    //         orderItemList.add(oi);
    //     }
        
    //     insert orderItemList;
        
    // }
}