public class B2BCreateHistoricalOrdersBatch implements Database.Batchable<sObject>, Database.Stateful {

    public B2BCreateHistoricalOrdersBatch() { }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, Billing_Address__CountryCode__s, Billing_Company__c, Billing_Email__c, Billing_FirstName__c, Billing_LastName__c, Billing_Phone__c, Customer_Id__c, Date_Completed__c, Date_Created__c, Date_Paid__c, Discount_Amount__c, FFP_Professional_Role__c, First_Name__c, Group_Role__c, Guid__c, Historical_Order_Id__c, Last_Name__c, Member_of_Group__c, Net_Total__c, Num_Items_Sold__c, Order_Date__c, Parent_Id__c, Post_Author__c, Post_Date__c, Post_Modified__c, Post_Name__c, Post_Title__c, Returning_Customer__c, Shipping_Address__City__s, Shipping_Address__CountryCode__s, Shipping_Total_With_Tax__c, Status__c, Successful_Insert__c, Tax_Total__c, Total_Sales__c, User_Id__c FROM Historical_Order__c WHERE Successful_Insert__c = \'Pending\'';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Historical_Order__c> scope){

        try {
            //--------------------------------------------------------------------SETUP---------------------------------------------------------

            //Get Default Order Delivery Method
            String deliveryMethodId;
            List<OrderDeliveryMethod> deliveryMethod = [SELECT Id FROM OrderDeliveryMethod WHERE IsActive = true];

            if(deliveryMethod.size() > 0) {
                deliveryMethodId = deliveryMethod[0].Id;
            }
            else {
               throw new HistoricalOrdersException('Order Delivery Method Not Found.');
            }

            //Get Delivery Charge Product
            String shippingProductId;
            List<Product2> shippingProduct = [SELECT Id FROM Product2 WHERE Name = 'Delivery Charge' AND IsActive = true];

            if(shippingProduct.size() > 0) {
                shippingProductId = shippingProduct[0].Id;
            }
            else {
                throw new HistoricalOrdersException('Delivery Charge Product Not Found.');
            }

            //Declare Map, Set and List Variables
            Map<String, String> emailToAccountMap = new Map<String, String>();
            Map<String, String> historicaItemIdToProductMap = new Map<String, String>();
            Map<String, String> orderToDeliveryGroupMap = new Map<String, String>();
            Map<String, Decimal> orderToShippingTotal = new Map<String, Decimal>();
            Map<String, Historical_Order__c> orderToHistoricalOrder = new Map<String, Historical_Order__c>();
            Map<String, Historical_Order_Item__c> orderItemToHistoricalOrderItem = new Map<String, Historical_Order_Item__c>();

            Set<String> customerEmails = new Set<String>();
            Set<String> historicalItemProductIds = new Set<String>();

            List<Order> orders = new List<Order>();
            List<OrderDeliveryGroup> odgs = new List<OrderDeliveryGroup>();
            List<OrderItem> orderItems = new List<OrderItem>();
            List<Historical_Order__c> validOrdersToInsert = new List<Historical_Order__c>();
            List<Historical_Order_Item__c> validOrderItemsToInsert = new List<Historical_Order_Item__c>();
            List<Historical_Order__c> historicalOrdersToBeUpdated = new List<Historical_Order__c>();
            List<Historical_Order_Item__c> historicalItemsToBeUpdated = new List<Historical_Order_Item__c>();

            //-----------------------------------------------------------------------SETUP END--------------------------------------------------------------

            //----------------------------------------------------GET VALID ACCOUNTS TO MAP HISTORICAL ORDERS-------------------------------------------------
            for(Historical_Order__c s : scope) {
                customerEmails.add(s.Billing_Email__c);
            }

            List<Account> customerAccounts = [SELECT Id, PersonEmail FROM Account WHERE PersonEmail IN :customerEmails AND RecordType.Name = 'Person Account'];
            if(customerAccounts.size() > 0) {
                for(Account account : customerAccounts) {
                    emailToAccountMap.put(account.PersonEmail, account.Id);
                }
            }

            // Check for unmatched Historical Orders
            for (Historical_Order__c historicalOrder : scope) {
                if (!emailToAccountMap.containsKey(historicalOrder.Billing_Email__c)) {
                    //Log exception for no account match for given billing email
                    String errorMessage = 'Order Insert Failed for Historical Order: ' + historicalOrder.Name + 
                                          ' | Error: Account does not exist with the given Billing Email.';
                    
                    historicalOrder.Exception__c = B2BHandleCustomException.LogException(new HistoricalOrdersException(errorMessage), 'Historical Orders', 'Order Creation');
                    historicalOrder.Successful_Insert__c = 'Unsuccessful';
                    historicalOrdersToBeUpdated.add(historicalOrder);
                } 
                else {
                    validOrdersToInsert.add(historicalOrder);
                }
            }
            //----------------------------------------------------GET VALID ACCOUNTS TO MAP HISTORICAL ORDERS END-------------------------------------------------

            //------------------------------------------------------------CREATE ORDERS-----------------------------------------------------
            for(Historical_Order__c ho : validOrdersToInsert){

                // Create a new Order for the Account
                Order order = new Order();
                order.Name = ho.Historical_Order_Id__c;
                order.AccountId = emailToAccountMap.get(ho.Billing_Email__c);
                order.OrderedDate = DateTime.now();
                order.PoNumber = ho.Name;
                order.EffectiveDate = System.Today();
                order.SalesStoreId = System.Label.Webstore_ID;
                order.Status = 'Draft';
                order.BillingCountryCode = ho.Billing_Address__CountryCode__s;
                order.ShippingCountryCode = ho.Shipping_Address__CountryCode__s;

                orders.add(order);

                orderToShippingTotal.put(ho.Historical_Order_Id__c,ho.Shipping_Total_With_Tax__c);
                orderToHistoricalOrder.put(order.Name, ho);
            }

            if (!orders.isEmpty()) {
                Database.SaveResult[] results = Database.insert(orders, false);

                //Update Status on Historical Order & Log Exceptions for failed records
                for (Integer i = 0; i < results.size(); i++) {
                    Order insertedOrder = orders[i];
                    Database.SaveResult sr = results[i];
            
                    // Find matching historical order
                    Historical_Order__c ho = orderToHistoricalOrder.get(insertedOrder.Name);
            
                    if (sr.isSuccess()) {
                        ho.Successful_Insert__c = 'Successful';
                        ho.SF_Order__c = insertedOrder.Id;
                    } 
                    else {
                        for(Database.Error err : sr.getErrors()) {
                            String errorMessage = 'Order Insert Failed for Historical Order: ' + ho.Name + 
                                                  ' | Error: ' + err.getStatusCode() + ' - ' + err.getMessage();
                            
                            ho.Exception__c = B2BHandleCustomException.LogException(new HistoricalOrdersException(errorMessage), 'Historical Orders', 'Order Creation');
                            ho.Successful_Insert__c = 'Unsuccessful';
                        }
                    }
                    historicalOrdersToBeUpdated.add(ho);
                }
            }
            //----------------------------------------------------------CREATE ORDERS END-----------------------------------------------------

            //----------------------------------------------------CREATE ORDER DELIVERY GROUPS-------------------------------------------------
            for (Order order : orders) {
                OrderDeliveryGroup odg = new OrderDeliveryGroup();
                odg.orderId = order.Id;
                odg.DeliverToName = order.Name;
                odg.DeliverToCountry = order.ShippingCountry;
                odg.OrderDeliveryMethodId = deliveryMethodId;

                odgs.add(odg);
            }

            if (!odgs.isEmpty()) {
                Database.SaveResult[] results = Database.insert(odgs, false);
              
                for (OrderDeliveryGroup odg : odgs) {
                    orderToDeliveryGroupMap.put(odg.orderId, odg.Id);
                }
            }
            //----------------------------------------------------CREATE ORDER DELIVERY GROUPS END-------------------------------------------------

            //--------------------------------------------------------------CREATE ORDER ITEMS-----------------------------------------------------
            for (Order order : orders) {
                validOrderItemsToInsert = new List<Historical_Order_Item__c>();

                // Create Delivery Charge Order Item
                OrderItem charge = new OrderItem();
                charge.OrderDeliveryGroupId = orderToDeliveryGroupMap.get(order.Id);
                charge.OrderId = order.Id;
                charge.Product2Id = shippingProductId;
                charge.Quantity = 1;
                charge.UnitPrice = orderToShippingTotal.get(order.Name);
                charge.ListPrice = orderToShippingTotal.get(order.Name);
                charge.Type = 'Delivery Charge';

                orderItems.add(charge);

                //Get Historical Order Items records for each Order
                List<Historical_Order_Item__c> histOrderItems = [SELECT Id, Name, Historical_Order_Item_Id__c, Historical_Order_Id__c, Product_Id__c, Quantity__c, Line_Total__c, Line_Tax__c, Unit_Price__c, Unit_Price_With_Tax__c
                                                                 FROM Historical_Order_Item__c 
                                                                 WHERE Historical_Order_Id__c = :order.Name];

                for (Historical_Order_Item__c  hoi : histOrderItems) {
                    if(hoi.Quantity__c == 0) {
                        //Log exception for 0 quantity order items
                        String errorMessage = 'OrderItem Insert Failed for Historical Order Item: ' + hoi.Name + 
                                              ' | Error: Quantity cannot be 0.';
                            
                        hoi.Exception__c = B2BHandleCustomException.LogException(new HistoricalOrdersException(errorMessage), 'Historical Orders', 'OrderItem Creation');
                        hoi.Successful_Insert__c = 'Unsuccessful';
                        hoi.SF_Historical_Order__c =  orderToHistoricalOrder.get(order.Name).Id;

                        historicalItemsToBeUpdated.add(hoi);
                    } 
                    else {
                        validOrderItemsToInsert.add(hoi);
                        historicalItemProductIds.add(hoi.Product_Id__c);
                    }
                }

                List<Product2> products = [SELECT Id, WC_Id__c FROM Product2 WHERE WC_Id__c IN :historicalItemProductIds];
                if(products.size() > 0) {
                    for(Product2 p : products) {         
                        historicaItemIdToProductMap.put(p.WC_Id__c, p.Id);
                    }
                }

                for (Historical_Order_Item__c  hoi : validOrderItemsToInsert) {
                    //Create Order Item for each valid historical order item
                    OrderItem oi = new OrderItem();
                    oi.OrderDeliveryGroupId = orderToDeliveryGroupMap.get(order.Id);
                    oi.OrderId = order.Id;
                    oi.Product2Id = historicaItemIdToProductMap.get(hoi.Product_Id__c);
                    oi.Quantity = hoi.Quantity__c;
                    oi.UnitPrice = hoi.Unit_Price_With_Tax__c;
                    oi.ListPrice = hoi.Unit_Price_With_Tax__c;
                    oi.Type = 'Order Product';
                    oi.Description = hoi.Historical_Order_Item_Id__c;

                    orderItems.add(oi);

                    orderItemToHistoricalOrderItem.put(oi.Description, hoi);
                }
            }

            if (!orderItems.isEmpty()) {
                Database.SaveResult[] results = Database.insert(orderItems, false);
                
                //Update Status on Historical OrderItem & Log Exceptions for failed records
                for (Integer i = 0; i < results.size(); i++) {
                    OrderItem insertedOrderItem = orderItems[i];
                    if(insertedOrderItem.Type == 'Order Product') {
                        Database.SaveResult sr = results[i];
                
                        // Find matching historical order Item
                        Historical_Order_Item__c hoi = orderItemToHistoricalOrderItem.get(insertedOrderItem.Description);
                
                        if (sr.isSuccess()) {
                            hoi.Successful_Insert__c = 'Successful';
                            hoi.SF_Order_Item__c = insertedOrderItem.Id;
                        } 
                        else {
                            for(Database.Error err : sr.getErrors()) {
                                String errorMessage = 'Order Insert Failed for Historical Order: ' + hoi.Name + 
                                                    ' | Error: ' + err.getStatusCode() + ' - ' + err.getMessage();
                                
                                hoi.Exception__c = B2BHandleCustomException.LogException(new HistoricalOrdersException(errorMessage), 'Historical Orders', 'OrderItem Creation');
                                hoi.Successful_Insert__c = 'Unsuccessful';
                            }
                        }

                        hoi.SF_Historical_Order__c = orderToHistoricalOrder.get(hoi.Historical_Order_Id__c).Id;
                        historicalItemsToBeUpdated.add(hoi);
                    }
                }
            }
            //-------------------------------------------------------------CREATE ORDER ITEMS END-----------------------------------------------------


            //Activate all the Orders
            for (Order order : orders) {
                order.Status = 'Activated';
            }
            Database.update(orders, false);
            Database.update(historicalOrdersToBeUpdated, false);
            Database.update(historicalItemsToBeUpdated, false);

            //-------------------------------------------------------------CREATE ORDER SUMMARY----------------------------------------------------------
            for (Order order : orders) {
                ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
                osir.orderId = order.Id;
                osir.orderLifeCycleType = 'UNMANAGED';
                ConnectApi.OrderSummaryOutputRepresentation osor = ConnectApi.OrderSummaryCreation.createOrderSummary(osir);
            }
            System.debug('##Order Summaries Inserted Successfully!');
            //------------------------------------------------------------CREATE ORDER SUMMARY END----------------------------------------------------------
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'Historical Orders', 'Order Creation');
        }        
    }

    public void finish(Database.BatchableContext bc){

    }

    public class HistoricalOrdersException extends Exception {}
}