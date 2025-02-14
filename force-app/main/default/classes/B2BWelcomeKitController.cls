public without sharing class B2BWelcomeKitController {

    @AuraEnabled(cacheable=true)
    public static List<WelcomeKitWrapper> getUnclaimedKits() {
        String accountId = B2BUtils.getUserAccountID();

        List<Account_Membership__c> accountMembershipList = [SELECT Membership__r.Individual_Certification_Kit__c,  Membership__r.Individual_Certification_Kit__r.Name,  Membership__r.Individual_Certification_Kit__r.Id
                                                             FROM Account_Membership__c 
                                                             WHERE Welcome_Kit_Status__c ='Unclaimed' AND Account_Id__c =:accountId
                                                            ];
                                                            
        if (accountMembershipList.isEmpty()) {
            return null;
        }
        List<WelcomeKitWrapper> welcomeKitWrapperList = new List <WelcomeKitWrapper>();

        // will check this list against items in cart currently
        String cartId = B2BUtils.getAccountActiveOrCheckoutWebCart(); 
        for (Account_Membership__c accountMembership : accountMembershipList) {
            
            WelcomeKitWrapper welcomeKitWrapper = new WelcomeKitWrapper();
            welcomeKitWrapper.productName = accountMembership.Membership__r.Individual_Certification_Kit__r.Name;
            welcomeKitWrapper.productId = accountMembership.Membership__r.Individual_Certification_Kit__r.Id;
            if (cartId == null) {
                welcomeKitWrapperList.add(welcomeKitWrapper);
                continue;
            }
            List<cartItem> cartItems = [SELECT Id FROM CartItem WHERE CartId =: cartId AND Product2Id=:welcomeKitWrapper.productId];
            if (cartItems.isEmpty()) {
                welcomeKitWrapperList.add(welcomeKitWrapper);
            }
        }
        if (welcomeKitWrapperList.isEmpty()) {
            return null;
        }
        return welcomeKitWrapperList;
    }

    @AuraEnabled
    public static AddressWrapper getShippingAddress() {

        AddressWrapper shippingAddress = new AddressWrapper();
        String accountId = B2BUtils.getUserAccountID();

        List<Account> account = [SELECT Business__c FROM Account WHERE Id = :accountId];

        if(account.size() > 0) {
            if(account[0].Business__c != null) {
                List<Account> businessAccount = [SELECT Id, ShippingAddress, ShippingStreet,
                                                 ShippingCity, ShippingStateCode, 
                                                 ShippingPostalCode, ShippingCountryCode
                                                 FROM Account WHERE Id = :account[0].Business__c];
                if(businessAccount.size() > 0) {
                    if(businessAccount[0].ShippingAddress != null) {
                        shippingAddress.street = businessAccount[0].ShippingStreet;
                        shippingAddress.city = businessAccount[0].ShippingCity;
                        shippingAddress.state = businessAccount[0].ShippingStateCode;
                        shippingAddress.postalCode = businessAccount[0].ShippingPostalCode;
                        shippingAddress.country = businessAccount[0].ShippingCountryCode;

                        return shippingAddress;
                    }
                }
            }
        }
        return null;
    }

    @AuraEnabled
    public static void addWelcomeKitToCart(String productId) {
        try {
            String cartId = B2BUtils.getAccountActiveOrCheckoutWebCart();
            if (cartId == null) {
            cartId = B2BUtils.createWebCart();
            }
            String cartDeliveryGroupId = B2BUtils.getCartDeliveryGroupId(cartId);
            String productName = [SELECT Name FROM Product2 WHERE Id=:productId].Name;
            CartItem ci = new CartItem();
            ci.Product2Id = productId;
            ci.CartId = cartId;
            ci.CartDeliveryGroupId = cartDeliveryGroupId;
            ci.Name = productName;
            ci.Quantity = 1;
            insert ci;
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BWelcomeKitController', 'addWelcomeKitToCart');
        }
    }

    public class WelcomeKitWrapper {
        @AuraEnabled
        public String productName {get; set;}

        @AuraEnabled
        public String productImageUrl {get; set;}

        @AuraEnabled 
        public String productId {get; set;}
    }

    public class AddressWrapper {

        @AuraEnabled
        public String street {get; set;}

        @AuraEnabled
        public String city {get; set;}

        @AuraEnabled
        public String state {get; set;}

        @AuraEnabled
        public String postalCode {get; set;}

        @AuraEnabled
        public String country {get; set;}
    }

    @AuraEnabled
    public static void saveShippingAddress(AddressWrapper shippingAddress) {
        try {
            String accountId = B2BUtils.getUserAccountID();
            List<Account> account = [SELECT Business__c FROM Account WHERE Id = :accountId];

            if(account.size() > 0) {
                List<Account> businessAccount = [SELECT ShippingAddress, ShippingStreet,
                                                ShippingCity, ShippingStateCode, 
                                                ShippingPostalCode, ShippingCountryCode
                                                FROM Account 
                                                WHERE Id = :account[0].Business__c
                                                ];

                if(businessAccount.size() > 0) {
                    businessAccount[0].ShippingStreet = shippingAddress.street;
                    businessAccount[0].ShippingCity = shippingAddress.city;
                    businessAccount[0].ShippingStateCode = shippingAddress.state;
                    businessAccount[0].ShippingPostalCode = shippingAddress.postalCode;
                    businessAccount[0].ShippingCountryCode = shippingAddress.country;

                    update businessAccount;
                }
            }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BWelcomeKitController', 'saveShippingAddress');
        }
    }

    @AuraEnabled
    public static List<Practice_Level_Membership_Assignment__c> getUnclaimedPracticeLevelKits() {
        String accountId = B2BUtils.getUserAccountID();

        List<Account> account = [SELECT Business__c FROM Account WHERE Id = :accountId];

        if(account.size() > 0) {
            if(account[0].Business__c != null) {
                List<Account> businessAccount = [SELECT Id FROM Account WHERE Id = :account[0].Business__c];

                List<Practice_Level_Membership_Assignment__c> unclaimedPracticeLevelKits = [SELECT Membership__c 
                                                                                            FROM Practice_Level_Membership_Assignment__c 
                                                                                            WHERE Welcome_Kit_Status__c = 'Unclaimed' 
                                                                                            AND Business_Account__c = :businessAccount[0].Id 
                                                                                            AND Status__c = 'Active'
                                                                                           ];
                return unclaimedPracticeLevelKits;
            }
        }
        return null;
    }

    @AuraEnabled
    public static Boolean createOrderSummary(List<String> membershipIds, AddressWrapper shippingAddress) {

        String accountId = B2BUtils.getUserAccountID();
        Account account = [SELECT Name, Business__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
                           FROM Account 
                           WHERE Id = :accountId];

        List<Membership__c> memberships = [SELECT Practice_Certification_Kit__r.Id FROM Membership__c WHERE Id IN :membershipIds];

        if(memberships.size() > 0) {
            try {
                //Get WebStore Id
                String storeName = System.Label.B2B_WebStore_Name;
                if(Test.isRunningTest()) {storeName = 'TestWebStore';}
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

                // Create Order
                Order order = new Order();
                order.Name = account.Name + 'Practice Level Certification Kit';
                order.AccountId = accountId;
                order.OrderedDate = DateTime.now();
                order.PoNumber = account.Name + 'Kit';
                order.EffectiveDate = System.Today();
                order.SalesStoreId = storeId;
                order.Status = 'Draft';
                order.BillingStreet = account.BillingStreet;
                order.BillingCity = account.BillingCity;
                order.BillingState = account.BillingState;
                order.BillingPostalCode = account.BillingPostalCode;
                order.BillingCountry = account.BillingCountry;
                order.ShippingStreet = shippingAddress.street;
                order.ShippingCity = shippingAddress.city;
                order.ShippingState = shippingAddress.state;
                order.ShippingPostalCode = shippingAddress.postalCode;
                order.ShippingCountry = shippingAddress.country;

                insert order;

                // Create Order Delivery Group
                OrderDeliveryGroup odg = new OrderDeliveryGroup();
                odg.orderId = order.Id;
                odg.DeliverToName = account.Name;
                odg.DeliverToStreet = shippingAddress.street;
                odg.DeliverToCity = shippingAddress.city;
                odg.DeliverToState = shippingAddress.state;
                odg.DeliverToPostalCode = shippingAddress.postalCode;
                odg.DeliverToCountry = shippingAddress.country;
                odg.OrderDeliveryMethodId = deliveryMethodId;

                insert odg;

                //Create Order Items
                List<OrderItem> orderItems = new List<OrderItem>();
                List<Id> productIds = new List<Id>();
                for(Membership__c m : memberships) {

                    OrderItem oi = new OrderItem();
                    oi.OrderDeliveryGroupId =odg.Id;
                    oi.OrderId = order.Id;
                    oi.Product2Id = m.Practice_Certification_Kit__r.Id;
                    oi.Quantity = 1;
                    oi.UnitPrice = 0;
                    oi.ListPrice = 0;
                    oi.Type = 'Order Product';

                    orderItems.add(oi);
                    productIds.add(m.Practice_Certification_Kit__r.Id);
                }
                
                if(!orderItems.isEmpty()) {
                    insert orderItems;
                }
                
                //Activate Order
                order.Status = 'Activated';
                update order;

                //Create Order Summary
                if(!Test.isRunningTest()) {
                    ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
                    osir.orderId = order.Id;
                    osir.orderLifeCycleType = 'UNMANAGED';
                    ConnectApi.OrderSummaryOutputRepresentation osor = ConnectApi.OrderSummaryCreation.createOrderSummary(osir);
                    updatePracticeCertificationKitStatus(account.Business__c, productIds, osor.orderSummaryId);
                }
                return true;
            }
            catch(Exception e) {
                B2BHandleCustomException.LogException(e, 'B2BWelcomeKitController', 'createOrderSummary');
            }
        }
        return false;
    }

    public static void updatePracticeCertificationKitStatus(String businessAccount, List<Id> productIds, String osId) {
        try {
            List<Practice_Level_Membership_Assignment__c> practiceMemberships = [SELECT Welcome_Kit_Status__c, Certification_Kit_Order_Summary__c
                                                                                FROM Practice_Level_Membership_Assignment__c
                                                                                WHERE Business_Account__c =:businessAccount AND Membership__r.Practice_Certification_Kit__r.Id IN :productIds 
                                                                                AND Welcome_Kit_Status__c = 'Unclaimed'
                                                                                ];
                                                
            List<Practice_Level_Membership_Assignment__c> itemsToUpdate = new List<Practice_Level_Membership_Assignment__c>();                                                 
            for(Practice_Level_Membership_Assignment__c pm : practiceMemberships) {
                pm.Welcome_Kit_Status__c = 'Claimed';
                pm.Certification_Kit_Order_Summary__c = osId;

                itemsToUpdate.add(pm);
            }
            
            if(!itemsToUpdate.isEmpty()) {
                update itemsToUpdate;
            }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BWelcomeKitController', 'updatePracticeCertificationKitStatus');
        }
    }
}