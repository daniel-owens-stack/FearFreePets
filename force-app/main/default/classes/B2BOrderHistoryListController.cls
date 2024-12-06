public without sharing class B2BOrderHistoryListController {
    
    @AuraEnabled
    public static List<OrderSummaryWrapper> getOrderSummaries(Map<String, Object> inputParameters) {

        List<OrderSummaryWrapper> orderSummaryList = new List<OrderSummaryWrapper>();
        try {
            String accountId = B2BUtils.getUserAccountID();
            List<Account> account = [SELECT Admin_Account__c, Business__c FROM Account WHERE Id = :accountId];

            if(account.size() > 0) {
                List<OrderSummary> orderSummaries = new List<OrderSummary>();
                Boolean isTeamAdmin = account[0].Admin_Account__c;
                String businessAccount = account[0].Business__c;

                String osFields = 'Id, CreatedDate, GrandTotalAmount, OrderedDate, Ordered_Date__c, OrderNumber, Status, Owner.FirstName, Owner.LastName';
                String osWhere;

                if(isTeamAdmin == true && businessAccount != null) {
                    osWhere = '(AccountId = ' +  '\'' + accountId + '\' OR Business_Account__c = ' + '\'' + account[0].Business__c + '\')';
                }
                else {
                    osWhere = 'AccountId = ' +  '\'' + accountId + '\'';
                }

                String query = 'SELECT ' + osFields + ' FROM OrderSummary WHERE ' + osWhere;
                
                if(inputParameters.containsKey('startDate') && inputParameters.containsKey('endDate')){
                    query += ' AND Ordered_Date__c >= ' + inputParameters.get('startDate') + ' AND Ordered_Date__c <= '+ inputParameters.get('endDate') ;
                }
                
                query += ' ORDER BY CreatedDate ' + inputParameters.get('sortingOrder') + ' NULLS LAST LIMIT 5000';
                orderSummaries = Database.query(query);

                if(orderSummaries.size() > 0) {
                    for (OrderSummary os : orderSummaries) {	
                        OrderSummaryWrapper osw = new OrderSummaryWrapper();
                        osw.osId = os.Id;
                        osw.orderNumber = os.OrderNumber;
                        osw.orderedDateText = os.OrderedDate.format('MM/dd/yyyy');
                        osw.status = os.Status;
                        osw.total = os.GrandTotalAmount;
                        osw.orderedDate = os.Ordered_Date__c;
                        osw.ordersCount = orderSummaries.size();
                        osw.isViewDetailsDisabled = os.Status == 'Canceled' ? true : false;

                        String firstName = os.Owner.FirstName;
                        if(firstName == null) {
                            osw.ownerName = os.Owner.LastName;
                        } else {
                            osw.ownerName = os.Owner.FirstName + ' ' + os.Owner.LastName;
                        }

                        orderSummaryList.add(osw);
                    }
                }
            }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BOrderHistoryListController', 'getOrderSummaries');
        }
        return orderSummaryList;
    }

    @AuraEnabled
    public static OrderSummaryDetailsWrapper getOrderSummaryItems(String orderSummaryId) {

        OrderSummary orderSummary = [SELECT Id, OrderNumber, OrderedDate, AccountId, Account.Name, Owner.FirstName, Owner.LastName, 
                                            Status, TotalAdjustedProductAmount, TotalAdjustedDeliveryAmount, TotalTaxAmount, 
                                            GrandTotalAmount, TotalDeliveryAmount, CreatedDate, Shipping_Address__c,
                                            Shipping_Address__Street__s, Shipping_Address__City__s, Shipping_Address__StateCode__s,
                                            Shipping_Address__PostalCode__s, Shipping_Address__CountryCode__s, Total_Refunded_Amount__c
                                    FROM OrderSummary 
                                    WHERE Id=:orderSummaryId];      
     
                  
        String ownerName;
        String firstName = orderSummary.Owner.FirstName;
        if(firstName == null) {
            ownerName = orderSummary.Owner.LastName;
        } else {
            ownerName = orderSummary.Owner.FirstName + ' ' + orderSummary.Owner.LastName;
        }
        
        OrderSummaryDetailsWrapper detailsWrapper = new OrderSummaryDetailsWrapper();

        //Details
        detailsWrapper.osDetails = new orderSummaryDetails();
        detailsWrapper.osDetails.orderNumber = orderSummary.OrderNumber;
        detailsWrapper.osDetails.orderedDate = orderSummary.OrderedDate.format('MM/dd/yyyy');
        detailsWrapper.osDetails.accountName = orderSummary.Account.Name;
        detailsWrapper.osDetails.orderStatus = orderSummary.Status;
        detailsWrapper.osDetails.orderPlacedBy = ownerName;
        
        //Totals
        detailsWrapper.osTotals = new orderSummaryTotals();
        detailsWrapper.osTotals.subtotal = orderSummary.TotalAdjustedProductAmount;
        detailsWrapper.osTotals.shipping = orderSummary.TotalAdjustedDeliveryAmount;
        detailsWrapper.osTotals.tax = orderSummary.TotalTaxAmount;
        detailsWrapper.osTotals.total = orderSummary.GrandTotalAmount;
        detailsWrapper.osTotals.shippingSubTotal = orderSummary.TotalDeliveryAmount;
        detailsWrapper.osTotals.refundedAmount = orderSummary.Total_Refunded_Amount__c;
        detailsWrapper.osTotals.showRefundedAmount = orderSummary.Total_Refunded_Amount__c != 0;
        
        OrderDeliveryGroupSummary deliveryGroupSummary = getOrderDeliveryGroupSummary(orderSummaryId);

        // Shipping Details
        detailsWrapper.shippingAddress = new shippingAddressDetails();
        detailsWrapper.shippingAddress.deliverToStreet = orderSummary.Shipping_Address__Street__s;
        detailsWrapper.shippingAddress.deliverToCity = orderSummary.Shipping_Address__City__s;
        detailsWrapper.shippingAddress.deliverToState = orderSummary.Shipping_Address__StateCode__s;
        detailsWrapper.shippingAddress.deliverToPostalCode = orderSummary.Shipping_Address__PostalCode__s;
        detailsWrapper.shippingAddress.deliverToCountry = orderSummary.Shipping_Address__CountryCode__s;
        detailsWrapper.shippingAddress.deliverToName = deliveryGroupSummary?.DeliverToName;
        detailsWrapper.shippingAddress.deliveryMethod = deliveryGroupSummary?.OrderDeliveryMethod.Name;
        
        //OrderSummary Items
        List<OrderItemSummary> orderItemSummaries = [SELECT Id, Type, Quantity, UnitPrice, TotalLineAmount, Product2.Shippable__c, 
                                                            Product2Id, Product2.Name, StockKeepingUnit, Product2.Description
                                                     FROM OrderItemSummary 
                                                     WHERE OrderSummaryId =:orderSummaryId
                                                    ];

        if(orderItemSummaries == null || orderItemSummaries.size() == 0) {
            return detailsWrapper;
        }

        Map<String, orderItemSummaryWrapper> productToWrapperMap = new Map<String, orderItemSummaryWrapper>();
        List<String> productIds = new List<String>();
        Integer numOfItems = 0;

        for(OrderItemSummary ois :orderItemSummaries){
            if(ois.Type == 'Order Product'){
                orderItemSummaryWrapper itemWrapper = new orderItemSummaryWrapper();

                itemWrapper.osItemId = ois.Id;
                itemWrapper.quantity = ois.Quantity;
                itemWrapper.unitPrice = ois.UnitPrice;
                itemWrapper.lineSubtotal = ois.TotalLineAmount;
                itemWrapper.productName = ois.Product2.Name;
                itemWrapper.productSku =  ois.StockKeepingUnit;
                itemWrapper.productDescription = ois.Product2.Description;
                
                productToWrapperMap.put(ois.Product2Id, itemWrapper);
                productIds.add(ois.Product2Id);
                numOfItems += 1;

                if(ois.Product2.Shippable__c) {
                    detailsWrapper.osDetails.hasShippableProducts = true;
                }
            }
        }
        detailsWrapper.osDetails.productCount = numOfItems;

        //Get Product Images
        String webStoreId = B2BUtils.getWebstoreID();

        if(!Test.isRunningTest()) {
            ConnectApi.ProductOverviewCollection productsData = ConnectAPI.CommerceCatalog.getProducts(webStoreId, null, productIds, null, null, false);

            for(ConnectApi.ProductOverview product : productsData.products){
                if(product.success){
                    productToWrapperMap.get(product.id).productImgUrl = product.defaultImage.url;
                }      
            }
        }
        
        if(!productToWrapperMap.values().isEmpty()){
            detailsWrapper.orderProductWrap = new List<orderItemSummaryWrapper>();
            detailsWrapper.orderProductWrap.addAll(productToWrapperMap.values());
        } 

        return detailsWrapper;
    }

    public static OrderDeliveryGroupSummary  getOrderDeliveryGroupSummary(String orderSummaryId){
        List<OrderDeliveryGroupSummary > odgs = [SELECT Id, DeliverToName, DeliverToStreet, DeliverToCity, DeliverToState, DeliverToPostalCode, DeliverToCountry, OrderDeliveryMethod.Name
                                                 FROM OrderDeliveryGroupSummary 
                                                 WHERE OrderSummaryId =: orderSummaryId
                                                ];
        if(odgs == null || odgs.size() == 0) {
            return null;
        }
        return odgs[0];
    }

    public class OrderSummaryDetailsWrapper{
        @AuraEnabled
        public orderSummaryDetails osDetails;

        @AuraEnabled
        public orderSummaryTotals osTotals {get; set;}

        @AuraEnabled
        public shippingAddressDetails shippingAddress {get; set;}
        
        @AuraEnabled
        public List<orderItemSummaryWrapper> orderProductWrap {get; set;}
    }

    public class orderSummaryDetails{

        @AuraEnabled
        public String orderNumber {get; set;}

        @AuraEnabled
        public String orderedDate {get; set;}

        @AuraEnabled
        public String accountName {get; set;}

        @AuraEnabled
        public String orderPlacedBy {get; set;}

        @AuraEnabled
        public String orderStatus {get; set;}

        @AuraEnabled
        public Integer productCount {get; set;}

        @AuraEnabled
        public Boolean hasShippableProducts {get; set;}
    }

    public class orderSummaryTotals{
        
        @AuraEnabled
        public Decimal subtotal {get; set;}

        @AuraEnabled
        public Decimal shipping {get; set;}

        @AuraEnabled
        public Decimal tax {get; set;}

        @AuraEnabled
        public Decimal total {get; set;}

        @AuraEnabled
        public Decimal shippingSubTotal {get; set;}

        @AuraEnabled
        public Decimal refundedAmount {get; set;}

        @AuraEnabled
        public Boolean showRefundedAmount {get; set;}
    }

    public class shippingAddressDetails{

        @AuraEnabled
        public String deliverToName {get; set;}

        @AuraEnabled
        public String deliverToStreet {get; set;}

        @AuraEnabled
        public String deliverToCity {get; set;}

        @AuraEnabled
        public String deliverToState {get; set;}

        @AuraEnabled
        public String deliverToPostalCode {get; set;}

        @AuraEnabled
        public String deliverToCountry {get; set;}

        @AuraEnabled
        public String deliveryMethod {get; set;}
    }
    
    public class orderItemSummaryWrapper{
        @AuraEnabled
        public String osItemId {get; set;}

        @AuraEnabled
        public String productName {get; set;}

        @AuraEnabled
        public String productDescription {get; set;}

        @AuraEnabled
        public String productSku {get; set;}

        @AuraEnabled
        public String productImgUrl {get; set;}

        @AuraEnabled
        public Decimal lineSubtotal {get; set;}

        @AuraEnabled
        public Decimal quantity {get; set;}

        @AuraEnabled
        public Decimal unitPrice {get; set;}
    }

    public class OrderSummaryWrapper {
        @AuraEnabled
        public String osId { get; set; }

        @AuraEnabled
        public String orderNumber { get; set; }

        @AuraEnabled
        public Date orderedDate { get; set; }

        @AuraEnabled
        public String orderedDateText { get; set; }

        @AuraEnabled
        public String status { get; set; }

        @AuraEnabled
        public Decimal total { get; set; }
        
        @AuraEnabled
        public Integer ordersCount { get; set; }

        @AuraEnabled
        public Boolean isViewDetailsDisabled { get; set; }

        @AuraEnabled
        public String ownerName { get; set; }
    }
}