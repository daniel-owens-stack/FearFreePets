public without sharing class B2BHandleCertificationKitBeforeOrder {

    public static Boolean isRunTrigger = true;

    public static void updateOrderItems(String orderId) {
        try {
            isRunTrigger = false;
            
            List<OrderItem> orderItems = [SELECT Id, Product2Id, Product2.Name, Product2.Product_Group__c, Product2.ProductClass
                                        FROM OrderItem 
                                        WHERE OrderId = :orderId
                                        ];

            // List<String> productNames = new List<String>(); 
            List<Id> productIds = new List<Id>();    
            // List<OrderItem> itemsToDelete = new List<OrderItem>();

            for(OrderItem oi: orderItems) {
                if(oi.Product2.Product_Group__c == 'Certification Kit') { // && oi.Product2.ProductClass == 'Set'
                    // productNames.add(oi.Product2.Name);
                    productIds.add(oi.Product2Id);
                    // itemsToDelete.add(oi);
                }
                else {
                    continue;
                }
            }

            // System.debug('##Items to delete: ' + itemsToDelete);
            // if (!itemsToDelete.isEmpty()) {
            //     delete itemsToDelete;
            // }
            // else {
            //     return;
            // }

            // List<Product2> setProducts = [SELECT Id FROM Product2 WHERE ProductClass = 'Set' AND Name IN :productNames];
            // List<Id> setProductIds = new List<Id>();
            // for(Product2 p : setProducts) {
            //     setProductIds.add(p.Id);
            // }
            // System.debug('##setProductIds : ' + setProductIds);

            // List<ProductRelatedComponent> childProducts;
            // if(setProductIds.size() > 0) {
            //     childProducts = [SELECT Id, ChildProductId, Quantity FROM ProductRelatedComponent WHERE ParentProductId IN :setProductIds];
            // }

            // List<OrderItem> itemsToInsert = new List<OrderItem>();
            // if(childProducts.size() > 0) {
            //     OrderDeliveryGroup odg = [SELECT Id FROM OrderDeliveryGroup WHERE OrderId = :orderId LIMIT 1];
            //     for(ProductRelatedComponent prc : childProducts) {
            //             OrderItem oi = new OrderItem(
            //                 OrderId = orderId,
            //                 Product2Id = prc.ChildProductId,
            //                 Quantity = prc.Quantity,
            //                 ListPrice = 0,
            //                 UnitPrice = 0,
            //                 OrderDeliveryGroupId = odg.Id,
            //                 TotalLineAmount = 0,
            //                 Type = 'Order Product'
            //             );
            //             itemsToInsert.add(oi);
            //     }
            // }
            
            // System.debug('##items to insert : ' + itemsToInsert);
            // if (!itemsToInsert.isEmpty()) {
            //     insert itemsToInsert;
            //     updateCertificationKitStatus(productIds, orderId);
            // }
            updateCertificationKitStatus(productIds, orderId);
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BHandleCertificationKitBeforeOrder', 'updateOrderItems');
        }
    }

    public static Boolean runTrigger() {
        return isRunTrigger == true ? true : false;
    }

    public static void updateCertificationKitStatus(List<Id> productIds, String orderId) {
        try {
            String accountId = B2BUtils.getUserAccountID();
            System.debug('##Account Id : ' + accountId);
            System.debug('##Product Ids : ' + productIds);

            List<Account_Membership__c> accountMemberships = [SELECT Id, Name, Welcome_Kit_Status__c, Certification_Kit_Order__c, Order_Summary__c
                                                            FROM Account_Membership__c
                                                            WHERE Account_Id__c =:accountId AND Membership__r.Individual_Certification_Kit__r.Id IN :productIds 
                                                            AND Welcome_Kit_Status__c = 'Unclaimed'
                                                            ];

            System.debug('##Account Memeberships: ' + accountMemberships);                                                
            List<Account_Membership__c> itemsToUpdate = new List<Account_Membership__c>();                                                 
            for(Account_Membership__c am : accountMemberships) {
                am.Welcome_Kit_Status__c = 'Claimed';
                am.Certification_Kit_Order__c = orderId;

                itemsToUpdate.add(am);
            }
            
            System.debug('##items to update : '+ itemsToUpdate);
            if(!itemsToUpdate.isEmpty()) {
                update itemsToUpdate;
            }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BHandleCertificationKitBeforeOrder', 'updateCertificationKitStatus');
        }
    }
}