public class B2BCreateHistoricalOrdersBatch implements Database.Batchable<sObject>, Database.Stateful {

    public B2BCreateHistoricalOrdersBatch() { }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, Billing_Address__City__s, Billing_Address__CountryCode__s, Billing_Address__PostalCode__s, Billing_Address__StateCode__s, Billing_Address__Street__s, Billing_Company__c, Billing_Email__c, Billing_FirstName__c, Billing_LastName__c, Billing_Phone__c, Customer_Id__c, Date_Completed__c, Date_Created__c, Date_Paid__c, Discount_Amount__c, FFP_Professional_Role__c, First_Name__c, Group_Role__c, Guid__c, Historical_Order_Id__c, Last_Name__c, Member_of_Group__c, Net_Total__c, Num_Items_Sold__c, Order_Date__c, Parent_Id__c, Post_Author__c, Post_Date__c, Post_Modified__c, Post_Name__c, Post_Title__c, Returning_Customer__c, Shipping_Address__City__s, Shipping_Address__CountryCode__s, Shipping_Address__PostalCode__s, Shipping_Address__StateCode__s, Shipping_Address__Street__s, Shipping_Total__c, Status__c, Successful_Insert__c, Tax_Total__c, Total_Sales__c, User_Id__c FROM Historical_Order__c WHERE Successful_Insert__c = false';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Historical_Order__c> scope){

        try {
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

            //Create Maps to get AccountId and ProductId 
            Map<String, String> accountMap = new Map<String, String>();
            Map<String, String> productMap = new Map<String, String>();

            Set<String> customerEmails = new Set<String>();
            Set<String> historicalOrderIds = new Set<String>();
            for(Historical_Order__c s : scope) {
                customerEmails.add(s.Billing_Email__c);
                historicalOrderIds.add(s.Historical_Order_Id__c);
            }

            List<Account> customerAccounts = [SELECT Id, PersonEmail FROM Account WHERE PersonEmail IN :customerEmails];
            if(customerAccounts.size() > 0) {
                for(Account a : customerAccounts) {
                    accountMap.put(a.PersonEmail, a.Id);
                }
            }

            List<Product2> products = [SELECT Id, WC_Id__c FROM Product2 WHERE WC_Id__c IN :historicalOrderIds];
            if(products.size() > 0) {
                for(Product2 p : products) {         
                    productMap.put(p.WC_Id__c, p.Id);
                }
            }
            
            //List of records to insert
            List<Order> orders = new List<Order>();
            List<OrderDeliveryGroup> odgs = new List<OrderDeliveryGroup>();
            List<OrderItem> orderItems = new List<OrderItem>();

            for(Historical_Order__c s : scope){

                // Create a new Order for the Account
                Order order = new Order();
                order.Name = s.Historical_Order_Id__c;
                order.AccountId = accountMap.get(s.Billing_Email__c);
                order.OrderedDate = DateTime.now();
                order.PoNumber = s.Name;
                order.EffectiveDate = System.Today();
                order.SalesStoreId = storeId;
                order.Status = 'Draft';
                order.BillingStreet = s.Billing_Address__Street__s;
                order.BillingCity = s.Billing_Address__City__s;
                order.BillingState = s.Billing_Address__StateCode__s;
                order.BillingPostalCode = s.Billing_Address__PostalCode__s;
                order.BillingCountry = s.Billing_Address__CountryCode__s;
                order.ShippingStreet = s.Shipping_Address__Street__s;
                order.ShippingCity = s.Shipping_Address__City__s;
                order.ShippingState = s.Shipping_Address__StateCode__s;
                order.ShippingPostalCode = s.Shipping_Address__PostalCode__s;
                order.ShippingCountry = s.Shipping_Address__CountryCode__s;

                orders.add(order);
            }

            if (!orders.isEmpty()) {
                insert orders;

                for (Order order : orders) {
                    // Create Order Delivery Group for each Order
                    OrderDeliveryGroup odg = new OrderDeliveryGroup();
                    odg.orderId = order.Id;
                    odg.DeliverToName = order.Name;
                    odg.DeliverToStreet = order.ShippingStreet;
                    odg.DeliverToCity = order.ShippingCity;
                    odg.DeliverToState = order.ShippingState;
                    odg.DeliverToPostalCode = order.ShippingPostalCode;
                    odg.DeliverToCountry = order.ShippingCountry;
                    odg.OrderDeliveryMethodId = deliveryMethodId;

                    odgs.add(odg);

                    //Get Historical Order Items records for each Order
                    List<Historical_Order_Item__c > histOrderItems = [SELECT Id, Historical_Order_Item_Id__c, Historical_Order_Id__c, Product_Id__c, Quantity__c, Line_Total__c
                                                                      FROM Historical_Order_Item__c 
                                                                      WHERE Historical_Order_Id__c = :order.Name];

                    for (Historical_Order_Item__c  hoi : histOrderItems) {
                        //Create Order Item for each historical order item
                        OrderItem oi = new OrderItem();
                        oi.OrderDeliveryGroupId = null; //will assign after odgs are inserted
                        oi.OrderId =order.Id;
                        oi.Product2Id = productMap.get(hoi.Historical_Order_Id__c);
                        oi.Quantity = hoi.Quantity__c;
                        oi.UnitPrice = hoi.Line_Total__c;
                        oi.ListPrice = hoi.Line_Total__c;
                        oi.Type = 'Order Product';
                        oi.Description = hoi.Historical_Order_Item_Id__c;

                        orderItems.add(oi);
                    }
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

            //Activate all the Orders
            for (Order order : orders) {
                order.Status = 'Activated';
            }
            update orders;

            //Create Order Summary and link with Order 
            for (Order order : orders) {
                ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
                osir.orderId = order.Id;
                osir.orderLifeCycleType = 'UNMANAGED';
                ConnectApi.OrderSummaryOutputRepresentation osor = ConnectApi.OrderSummaryCreation.createOrderSummary(osir);
            }
            System.debug('##Order Summaries Inserted Successfully!');

            List<Historical_Order__c> historicalOrdersToBeUpdated = new List<Historical_Order__c>();
            for(Historical_Order__c ho : scope) {
                ho.Successful_Insert__c = true;
                historicalOrdersToBeUpdated.add(ho);
            }
            update historicalOrdersToBeUpdated;
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'Historical Orders', 'Order Creation');
        }        
    }

    public void finish(Database.BatchableContext bc){

    }
}