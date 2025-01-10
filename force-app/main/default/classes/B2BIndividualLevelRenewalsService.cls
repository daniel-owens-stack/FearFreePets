public class B2BIndividualLevelRenewalsService {
    private static final String WEB_STORE_NAME = System.Label.B2B_WebStore_Name;
    
    public static List<B2BIndividualLevelRenewalsWrapper.IndividualLevelMembershipAssignment> getIndividualLevelMembershipAssignments(String parentAccountId) {
        
        List<Account_Membership__c> ilmasSObjectList = B2BIndividualLevelRenewalsHelper.getEligibleMembershipAssignments(parentAccountId);
        
        if (ilmasSObjectList == null || ilmasSObjectList.isEmpty()) {
            return null;
        }
        
        List <B2BIndividualLevelRenewalsWrapper.IndividualLevelMembershipAssignment> ilmaWrapperList = new List <B2BIndividualLevelRenewalsWrapper.IndividualLevelMembershipAssignment> ();

        for (Account_Membership__c ilmasSObject : ilmasSObjectList) {
            
            B2BIndividualLevelRenewalsWrapper.IndividualLevelMembershipAssignment ilmaWrapper = new B2BIndividualLevelRenewalsWrapper.IndividualLevelMembershipAssignment();
            
            ilmaWrapper.id = ilmasSObject.Id;
            ilmaWrapper.parent_account = ilmasSObject.Account_Id__c;
            ilmaWrapper.membership_id = ilmasSObject.Membership__c;
            ilmaWrapper.expirationDate = ilmasSObject.Expiration_Date__c;
            ilmaWrapper.renewal_product_id = B2BIndividualLevelRenewalsHelper.getRenewalProductId(ilmaWrapper.membership_id);
            ilmaWrapper.renewal_price = B2BIndividualLevelRenewalsHelper.getRenewalProductPrice(ilmasSObject.Account_Id__c, ilmaWrapper.renewal_product_id);
            
            ilmaWrapper.invoice_exempt = false;
            if (ilmasSObject.Practice_Level_Membership_Assignment__c != null) {
                ilmaWrapper.invoice_exempt = true;
            }

            ilmaWrapperList.add(ilmaWrapper);
        }
        
        return ilmaWrapperList;
    } 
    
    
    public static B2BIndividualLevelRenewalsWrapper.parentAccount getParentAccount(Account parentAccountSObject, Date renewalDate) {
        
        B2BIndividualLevelRenewalsWrapper.parentAccount parentAccount = new B2BIndividualLevelRenewalsWrapper.parentAccount();
        
        parentAccount.account_id = parentAccountSObject.Id;
        parentAccount.name = parentAccountSObject.Name;
        parentAccount.billing_email = parentAccountSObject.Billing_Email__c;
        parentAccount.billing_email_verified = parentAccountSObject.Billing_Email_Verified__c;
        parentAccount.billing_address = parentAccountSObject.BillingAddress;
        parentAccount.shipping_address = parentAccountSObject.BillingAddress;
        parentAccount.payment_terms = parentAccountSObject.Payment_Terms__c;
        parentAccount.business = parentAccountSObject.Business__c;
        parentAccount.individualLevelRenewalDate = renewalDate; //parentAccountSObject.IndividualLevelRenewalDate__c;
        
        return parentAccount;
    }

    public static  B2BIndividualLevelRenewalsWrapper.Order createOrder(B2BIndividualLevelRenewalsWrapper.ParentAccount parentAccount) {
        
        Order order = new Order();
        order.Name = parentAccount.account_id + ' Membership Renewal';
        order.AccountId = parentAccount.account_id;
        order.OrderedDate = DateTime.now();
        order.PoNumber = 'Membership Renewal';
        order.EffectiveDate = B2BIndividualLevelRenewalsHelper.getEffectiveOrderDate(parentAccount);
        order.SalesStoreId = B2BIndividualLevelRenewalsHelper.getWebStoreIdByName(WEB_STORE_NAME);
        order.Status = 'Draft';
        order.BillingStreet = parentAccount.billing_address.street;
        order.BillingCity = parentAccount.billing_address.city;
        order.BillingState = parentAccount.billing_address.state;
        order.BillingPostalCode = parentAccount.billing_address.postalCode;
        order.BillingCountry = parentAccount.billing_address.country;
        order.ShippingStreet = parentAccount.shipping_address.street;
        order.ShippingCity = parentAccount.shipping_address.city;
        order.ShippingState = parentAccount.shipping_address.state;
        order.ShippingPostalCode = parentAccount.shipping_address.postalCode;
        order.ShippingCountry = parentAccount.shipping_address.country;
        order.IsRenewal__c = true;
        
        insert order;
        System.debug('ORDER ID' + order.Id);

        OrderDeliveryGroup odg = new OrderDeliveryGroup();
        
        odg.OrderId = order.Id;
        odg.DeliverToName = parentAccount.name;
        odg.DeliverToStreet = parentAccount.shipping_address.street;
        odg.DeliverToCity = parentAccount.shipping_address.city;
        odg.DeliverToState = parentAccount.shipping_address.state;
        odg.DeliverToPostalCode = parentAccount.shipping_address.postalCode;
        odg.DeliverToCountry = parentAccount.shipping_address.country;
        odg.OrderDeliveryMethodId = B2BIndividualLevelRenewalsHelper.getOrderDeliveryMethodId();
    
        insert odg;
        
        B2BIndividualLevelRenewalsWrapper.Order orderWrapper = new B2BIndividualLevelRenewalsWrapper.Order();

        orderWrapper.id = order.Id;
        orderWrapper.order_delivery_group_id = odg.Id;
        
        return orderWrapper;
    }

    public static void createOrderItems( List<B2BIndividualLevelRenewalsWrapper.IndividualLevelMembershipAssignment> ilmaList, B2BIndividualLevelRenewalsWrapper.Order order) {
        
        List<OrderItem> orderItemList = new List<OrderItem>();

        for (B2BIndividualLevelRenewalsWrapper.IndividualLevelMembershipAssignment ilma : ilmaList) {
            OrderItem oi = new OrderItem();
            
            oi.OrderId = order.id;
            oi.OrderDeliveryGroupId = order.order_delivery_group_id;
            oi.Product2Id = ilma.renewal_product_id;
            oi.Quantity = 1;
            oi.UnitPrice = ilma.renewal_price;
            oi.ListPrice = ilma.renewal_price;
            oi.TotalLineAmount = ilma.renewal_price;
            oi.Type = 'Order Product';
            oi.Membership_Renewal__c = true;
            oi.Individual_Membership_Assignment__c = ilma.id;
            oi.InvoiceExempt__c = ilma.invoice_exempt;

            orderItemList.add(oi);
        }
        
        insert orderItemList;

    }

    public static B2BIndividualLevelRenewalsWrapper.Order getExistingOrder(Account account) {

        String orderId = B2BIndividualLevelRenewalsHelper.getExistingOrderId(account);

        if(orderId == null) {
            return null;
        }

        B2BIndividualLevelRenewalsWrapper.Order existingOrder = new B2BIndividualLevelRenewalsWrapper.Order();
        existingOrder.id = orderId;
        existingOrder.order_delivery_group_id = B2BIndividualLevelRenewalsHelper.getOrderDeliveryGroupId(orderId);

        return existingOrder;
    }
}