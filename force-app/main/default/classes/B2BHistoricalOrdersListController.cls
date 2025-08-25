public without sharing class B2BHistoricalOrdersListController {
    
    @AuraEnabled
    public static List<OrderSummaryWrapper> getHistoricalOrders(Map<String, Object> inputParameters) {
        List<OrderSummaryWrapper> historicalOrderSummaryList = new List<OrderSummaryWrapper>();
        try {
            String accountId = B2BUtils.getUserAccountID();
            List<Account> account = [SELECT Admin_Account__c, Business__c FROM Account WHERE Id = :accountId];

            if(account.size() > 0) {
                Boolean isTeamAdmin = account[0].Admin_Account__c;
                String businessAccount = account[0].Business__c;

                //Get Historical Orders
                List<Historical_Order__c> historicalOrders = new List<Historical_Order__c>();
                if(isTeamAdmin == true && businessAccount != null) {
                    historicalOrders = [
                        SELECT Id, Historical_Order_Id__c, SF_Order__c, Order_Date__c, Shipping_Total_With_Tax__c 
                        FROM Historical_Order__c 
                        WHERE SF_Order__c != null
                        AND (SF_Order__r.AccountId  =:accountId OR SF_Order__r.Account.Business__c = :businessAccount)
                    ];
                }
                else {
                    historicalOrders = [
                        SELECT Id, Historical_Order_Id__c, SF_Order__c, Order_Date__c, Shipping_Total_With_Tax__c 
                        FROM Historical_Order__c 
                        WHERE SF_Order__c != null
                        AND SF_Order__r.AccountId  =:accountId
                    ];
                }

                List<Id> sfOrderIds = new List<Id>();
                Map<Id, Historical_Order__c> historicalToSFOrdermap = new Map<Id, Historical_Order__c>();

                for(Historical_Order__c ho : historicalOrders) {
                    sfOrderIds.add(ho.SF_Order__c);
                    historicalToSFOrdermap.put(ho.SF_Order__c, ho);
                }
                
                List<OrderSummary> orderSummaries = new List<OrderSummary>();

                String osFields = 'Id, CreatedDate, GrandTotalAmount, OrderedDate, Ordered_Date__c, OrderNumber, Status, Owner.FirstName, Owner.LastName, Account.Name, OriginalOrderId';
                String osWhere = 'OriginalOrderId IN :sfOrderIds AND OriginalOrder.Is_Historical_Order__c = true';

                String query = 'SELECT ' + osFields + ' FROM OrderSummary WHERE ' + osWhere;
                
                if(inputParameters.containsKey('startDate') && inputParameters.containsKey('endDate')){
                    query += ' AND Ordered_Date__c >= ' + inputParameters.get('startDate') + ' AND Ordered_Date__c <= '+ inputParameters.get('endDate') ;
                }
                
                query += ' ORDER BY CreatedDate ' + inputParameters.get('sortingOrder') + ' NULLS LAST LIMIT 5000';
                orderSummaries = Database.query(query);

                if(orderSummaries.size() > 0) {
                    for (OrderSummary os : orderSummaries) {	
                        OrderSummaryWrapper osw = new OrderSummaryWrapper();
                        osw.osId = historicalToSFOrdermap.get(os.OriginalOrderId).Historical_Order_Id__c;
                        osw.orderNumber = os.OrderNumber;
                        osw.orderedDateText =  DateTime.newInstance(os.Ordered_Date__c, Time.newInstance(0, 0, 0, 0)).format('MM/dd/yyyy');
                        osw.status = os.Status;
                        osw.total = 0;
                        osw.orderedDate = os.Ordered_Date__c;
                        osw.ordersCount = orderSummaries.size();
                        osw.isViewDetailsDisabled = os.Status == 'Canceled' ? true : false;
                        osw.ownerName = os.Account.Name;

                        //Get Historical Order Items
                        List<Historical_Order_Item__c> histOrderItems = [
                            SELECT Id, Name, Historical_Order_Item_Id__c, Historical_Order_Id__c, Product_Id__c, Quantity__c, Line_Total__c, Line_Tax__c, Unit_Price__c, Unit_Price_With_Tax__c                                              
                            FROM Historical_Order_Item__c 
                            WHERE Historical_Order_Id__c = :historicalToSFOrdermap.get(os.OriginalOrderId).Historical_Order_Id__c
                            AND Quantity__c > 0
                        ];
                        if(!histOrderItems.isEmpty()) {
                            for(Historical_Order_Item__c hoi : histOrderItems) {
                                osw.total += hoi.Unit_Price_With_Tax__c * hoi.Quantity__c;
                            }
                            osw.total += historicalToSFOrdermap.get(os.OriginalOrderId).Shipping_Total_With_Tax__c;
                        }

                        historicalOrderSummaryList.add(osw);
                    }
                }
            }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BOrderHistoryListController', 'getOrderSummaries');
        }
        return historicalOrderSummaryList;
    }

    @AuraEnabled
    public static OrderSummaryDetailsWrapper getHistoricalOrderItems(String historicalOrderId) {
        //Get Historical Order
        Historical_Order__c ho = [
            SELECT Id, Shipping_Total_With_Tax__c, SF_Order__c 
            FROM Historical_Order__c 
            WHERE Historical_Order_Id__c = :historicalOrderId 
            ORDER BY CreatedDate Desc
            LIMIT 1
        ];
       
        //Get OrderSummary
        OrderSummary orderSummary = [SELECT Id, OrderNumber, OrderedDate,Ordered_Date__c, AccountId, Account.Name, Owner.FirstName, Owner.LastName, Account.PersonEmail, 
                                            Status, TotalAdjustedProductAmount, TotalAdjustedDeliveryAmount, TotalTaxAmount, 
                                            GrandTotalAmount, TotalDeliveryAmount, CreatedDate, Shipping_Address__c,
                                            Shipping_Address__Street__s, Shipping_Address__City__s, Shipping_Address__StateCode__s,
                                            Shipping_Address__PostalCode__s, Shipping_Address__CountryCode__s, Total_Refunded_Amount__c, Total_Amount_After_Refund__c
                                    FROM OrderSummary 
                                    WHERE OriginalOrderId = :ho.SF_Order__c];      
     
        String orderSummaryId = orderSummary.Id;
        
        OrderSummaryDetailsWrapper detailsWrapper = new OrderSummaryDetailsWrapper();

        //Details
        detailsWrapper.osDetails = new orderSummaryDetails();
        detailsWrapper.osDetails.orderNumber = orderSummary.OrderNumber;
        detailsWrapper.osDetails.orderedDate = DateTime.newInstance(orderSummary.Ordered_Date__c, Time.newInstance(0, 0, 0, 0)).format('MM/dd/yyyy');
        detailsWrapper.osDetails.accountName = orderSummary.Account.Name;
        detailsWrapper.osDetails.orderStatus = orderSummary.Status;
        detailsWrapper.osDetails.orderPlacedBy = orderSummary.Account.Name;
        detailsWrapper.osDetails.purchaserEmail = orderSummary.Account.PersonEmail;
        
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

        //Totals
        detailsWrapper.osTotals = new orderSummaryTotals();
        detailsWrapper.osTotals.subtotal = 0;
        detailsWrapper.osTotals.shipping = 0;
        detailsWrapper.osTotals.shippingSubTotal = 0;
        detailsWrapper.osTotals.tax = 0;
        detailsWrapper.osTotals.total = 0; 
        detailsWrapper.osTotals.refundedAmount = 0;
        detailsWrapper.osTotals.showRefundedAmount = false;
        detailsWrapper.osTotals.totalAmountAfterRefund = 0;

        //Get Historical Order Items
        List<Historical_Order_Item__c> histOrderItems = [
            SELECT Id, Name, Historical_Order_Item_Id__c, Historical_Order_Id__c, Product_Id__c, Quantity__c, Line_Total__c, Line_Tax__c, Unit_Price__c, Unit_Price_With_Tax__c                                              
            FROM Historical_Order_Item__c 
            WHERE Historical_Order_Id__c = :historicalOrderId
            AND Quantity__c > 0
        ];

        if(histOrderItems == null || histOrderItems.size() == 0) {
            return detailsWrapper;
        }

        //Set Totals from Order Items
        Set<String> historicalItemProductIds = new Set<String>();
        for(Historical_Order_Item__c hoi : histOrderItems) {
            detailsWrapper.osTotals.subtotal += hoi.Unit_Price_With_Tax__c * hoi.Quantity__c;
            historicalItemProductIds.add(hoi.Product_Id__c);
        }
        detailsWrapper.osTotals.shipping = ho.Shipping_Total_With_Tax__c;
        detailsWrapper.osTotals.shippingSubTotal = ho.Shipping_Total_With_Tax__c;
        detailsWrapper.osTotals.total = detailsWrapper.osTotals.subtotal + detailsWrapper.osTotals.shipping + detailsWrapper.osTotals.tax;

        Map<String, Product2> historicaItemIdToProductMap = new Map<String, Product2>();
        Map<String, orderItemSummaryWrapper> productToWrapperMap = new Map<String, orderItemSummaryWrapper>();
        List<String> productIds = new List<String>();
        Integer numOfItems = 0;

        if(!historicalItemProductIds.isEmpty()) {
            List<Product2> products = [
                SELECT Id, Name, Description, IsShippingChargeNotApplicable, StockKeepingUnit, WC_Id__c 
                FROM Product2 
                WHERE WC_Id__c 
                IN :historicalItemProductIds
            ];
            if(products.size() > 0) {
                for(Product2 p : products) {         
                    historicaItemIdToProductMap.put(p.WC_Id__c, p);
                }

                for(Historical_Order_Item__c hoi : histOrderItems) {
                    Product2 product = historicaItemIdToProductMap.get(hoi.Product_Id__c);
                    orderItemSummaryWrapper itemWrapper = new orderItemSummaryWrapper();

                    itemWrapper.osItemId = hoi.Historical_Order_Item_Id__c;
                    itemWrapper.quantity = hoi.Quantity__c;
                    itemWrapper.unitPrice = hoi.Unit_Price_With_Tax__c;
                    itemWrapper.lineSubtotal = hoi.Unit_Price_With_Tax__c * hoi.Quantity__c;
                    itemWrapper.productName = product.Name;
                    itemWrapper.productSku =  product.StockKeepingUnit;
                    itemWrapper.productDescription = product.Description;
                    
                    productToWrapperMap.put(product.Id, itemWrapper);
                    productIds.add(product.Id);
                    numOfItems += 1;

                    if(!product.IsShippingChargeNotApplicable) {
                        detailsWrapper.osDetails.hasShippableProducts = true;
                    }
                }
                detailsWrapper.osDetails.productCount = numOfItems;

                //Get Product Images
                String webStoreId = B2BUtils.getWebstoreID();

                if(!Test.isRunningTest()) {
                    ConnectApi.ProductOverviewCollection productsData = ConnectAPI.CommerceCatalog.getProducts(webStoreId, null, productIds, null, null, false, false, false, false, false, null);

                    for(ConnectApi.ProductOverview product : productsData.products){
                        if(product.success){
                            if(product.defaultImage != null) {
                                productToWrapperMap.get(product.id).productImgUrl = Site.getBaseUrl() + product.defaultImage.url;
                            }
                        }      
                    }
                }
        
                if(!productToWrapperMap.values().isEmpty()){
                    detailsWrapper.orderProductWrap = new List<orderItemSummaryWrapper>();
                    detailsWrapper.orderProductWrap.addAll(productToWrapperMap.values());
                }
            }
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

        @AuraEnabled
        public String purchaserEmail  {get; set; }
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

        @AuraEnabled
        public Decimal totalAmountAfterRefund {get; set;}
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