public class B2BPLAutoRenewalsBatch_Deprecated implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    private String queryString;
    private String renewalType;
    public List<Order> orders = new List<Order>();
    public Map<String, String> accountToStripeIdMap = new Map<String, String>();

    public B2BPLAutoRenewalsBatch_Deprecated(String query) {
        queryString = query;
        renewalType = null;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String businessAccount;
        if(renewalType == 'invoice') {
            businessAccount = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Business_Account' AND IsActive = true].Id;
        }
        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext bc, List<Practice_Level_Membership_Assignment__c> scope){
        try {
            List<Map<String, List<Membership__c>>> practiceMemberships = new List<Map<String, List<Membership__c>>>();
            Map<Id, Practice_Level_Membership_Assignment__c> membershipToPracticeAssignmentMap = new Map<Id, Practice_Level_Membership_Assignment__c>();

            for(Practice_Level_Membership_Assignment__c s : scope){
                Map<String, List<Membership__c>> practiceMembership = null;
                    
                for (Map<String, List<Membership__c>> existingMap : practiceMemberships) {
                    if (existingMap.containsKey(s.Business_Account__c)) {
                        practiceMembership = existingMap;
                        break;
                    }
                }
                
                if (practiceMembership == null) {
                    practiceMembership = new Map<String, List<Membership__c>>();
                    practiceMembership.put(s.Business_Account__c, new List<Membership__c>());
                    practiceMemberships.add(practiceMembership);
                }
        
                practiceMembership.get(s.Business_Account__c).add(s.Membership__r);
                membershipToPracticeAssignmentMap.put(s.Membership__c, s); 
            }

            //Get WebStore Id
            String storeName = System.Label.B2B_WebStore_Name;
            String storeId = [SELECT Id FROM WebStore WHERE Name = :storeName LIMIT 1]?.Id;

            //Get Default Order Delivery Method
            String deliveryMethodId;
            List<OrderDeliveryMethod> deliveryMethod = [SELECT Id FROM OrderDeliveryMethod WHERE IsActive = true];

            if(deliveryMethod.size() > 0) {
                deliveryMethodId = deliveryMethod[0].Id;
            }
            else {
                //Get Shipping Product
                String shippingProductId;
                List<Product2> shippingProduct = [SELECT Id FROM Product2 WHERE Name = 'Delivery Charge' AND IsActive = true];

                if(shippingProduct.size() > 0) {
                    shippingProductId = shippingProduct[0].Id;
                }
                else {
                    //Create a Shipping Product
                    Product2 p = new Product2(
                        Name = 'Delivery Charge'
                    );
                    insert p;

                    shippingProductId = p.Id;
                }
                    
                //Create Default Delivery Method
                OrderDeliveryMethod odm = new OrderDeliveryMethod();
                odm.Name = 'Default Delivery Method';
                odm.Carrier = 'Fedex';
                odm.ClassOfService = 'Digital Shipping';
                odm.IsActive = true;
                odm.ProductId = shippingProductId;

                insert odm;

                deliveryMethodId = odm.Id;
            }
            
            //List of records to insert
            List<OrderDeliveryGroup> odgs = new List<OrderDeliveryGroup>();
            List<OrderItem> orderItems = new List<OrderItem>();

            // Query Accounts to get required fields
            Set<String> accountIds = new Set<String>();
            for(Map<String, List<Membership__c>> am : practiceMemberships) {
                accountIds.addAll(am.keySet());
            }

            // Fetch Account records
            Map<String, Account> accountMap = new Map<String, Account>([
                SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                      ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, 
                      (SELECT Stripe_Id__c FROM Contacts)
                FROM Account
                WHERE Id IN :accountIds
            ]);

            //Create Orders for each Account
            for (Map<String, List<Membership__c>> practiceMembershipMap : practiceMemberships) {
                for (String accountId : practiceMembershipMap.keySet()) {
                    Account account = accountMap.get(accountId);

                    //Map AccountId -> StripeId
                    for(Contact contact: account.Contacts) {
                        accountToStripeIdMap.put(accountId, contact.Stripe_Id__c);
                    }
                    
                    // Create a new Order for the Account
                    Order order = new Order();
                    order.Name = account.Name + ' Membership Renewal';
                    order.AccountId = accountId;
                    order.OrderedDate = DateTime.now();
                    order.PoNumber = 'Membership Renewal';
                    order.EffectiveDate = System.Today();
                    order.SalesStoreId = storeId;
                    order.Status = 'Draft';
                    order.BillingStreet = account.BillingStreet;
                    order.BillingCity = account.BillingCity;
                    order.BillingState = account.BillingState;
                    order.BillingPostalCode = account.BillingPostalCode;
                    order.BillingCountry = account.BillingCountry;
                    order.ShippingStreet = account.ShippingStreet;
                    order.ShippingCity = account.ShippingCity;
                    order.ShippingState = account.ShippingState;
                    order.ShippingPostalCode = account.ShippingPostalCode;
                    order.ShippingCountry = account.ShippingCountry;
        
                    orders.add(order);
                }
            }
            // Mapping to store AccountId -> OrderId for referencing later
            Map<String, String> accountToOrderMap = new Map<String, String>();

            if (!orders.isEmpty()) {
                insert orders;

                for (Order order : orders) {
                    accountToOrderMap.put(order.AccountId, order.Id);
                }
            }

            // Create Order Delivery Groups and Order Items
            for (Map<String, List<Membership__c>> practiceMembershipMap : practiceMemberships) {
                for (String accountId : practiceMembershipMap.keySet()) {
                    // Retrieve the OrderId for the current Account
                    String orderId = accountToOrderMap.get(accountId);
                    Account account = accountMap.get(accountId);

                    // Create Order Delivery Group for each Order
                    OrderDeliveryGroup odg = new OrderDeliveryGroup();
                    odg.orderId = orderId;
                    odg.DeliverToName = account.Name;
                    odg.DeliverToStreet = account.ShippingStreet;
                    odg.DeliverToCity = account.ShippingCity;
                    odg.DeliverToState = account.ShippingState;
                    odg.DeliverToPostalCode = account.ShippingPostalCode;
                    odg.DeliverToCountry = account.ShippingCountry;
                    odg.OrderDeliveryMethodId = deliveryMethodId;

                    odgs.add(odg);

                    //Create Order Items for each Membership
                    List<Membership__c> memberships = practiceMembershipMap.get(accountId);

                    //Get Product2 records for the Memberships
                        Decimal productPrice;
                        Product2 product = new Product2();
                        Id membershipId = product.Membership__c;

                        if (membershipToPracticeAssignmentMap.containsKey(membershipId)) {
                            Practice_Level_Membership_Assignment__c plma = membershipToPracticeAssignmentMap.get(membershipId);
                            productPrice = B2BUtils.getPracticeMembershipRenewalPrice(plma.Id);
                            Integer renewalDVMCount = 1;//plma.Renewal_DVM_Count__c;
                            product = getRenewalProduct(memberships[0].Id, renewalDVMCount);
                        }

                        //Create Order Item for each product
                        OrderItem oi = new OrderItem();
                        oi.OrderDeliveryGroupId = null; //will assign after odgs are inserted
                        oi.OrderId = orderId;
                        oi.Product2Id = product.Id;
                        oi.Quantity = 1;
                        oi.UnitPrice = productPrice;
                        oi.ListPrice = productPrice;
                        oi.Type = 'Order Product';
                        oi.Membership_Renewal__c = true;
                        oi.TotalLineAmount = productPrice;

                        orderItems.add(oi);
                }
            }

            if (!odgs.isEmpty()) {
                insert odgs;

                // After inserting Delivery Groups, map OrderId -> DeliveryGroupId
                Map<String, String> orderToDeliveryGroupMap = new Map<String, String>();
                for (OrderDeliveryGroup odg : odgs) {
                    orderToDeliveryGroupMap.put(odg.orderId, odg.Id);
                }

                // Update the Order Items to have the orderDeliveryGroup
                for (OrderItem orderItem : orderItems) {
                    orderItem.OrderDeliveryGroupId = orderToDeliveryGroupMap.get(orderItem.OrderId);
                }

                // Insert Order Items
                if (!orderItems.isEmpty()) {
                    insert orderItems;
                }
            }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BPracticeLevelAutoRenewalsBatch', 'execute');
        }
    }

    public void finish(Database.BatchableContext bc){
        //Create Invoice & update InvoiceId on Orders
        for (Order order : orders) {
            String customerId = accountToStripeIdMap.get(order.AccountId);
            String stripeInvoiceId = B2BStripePaymentController.createInvoiceByOrderId(order.Id, customerId);
            order.InvoiceId__c = stripeInvoiceId;
        }
        update orders;
    }

    private static Product2 getRenewalProduct(String membershipId, Integer renewalDVMCount) {
        Product2 product = [SELECT Id, Membership__c FROM Product2 WHERE Renewal_DVM_Count_MIN__c <=:renewalDVMCount AND Renewal_DVM_Count_MAX__c >=:renewalDVMCount AND Membership__c =:membershipId];
        
        return product;
        
    }
}