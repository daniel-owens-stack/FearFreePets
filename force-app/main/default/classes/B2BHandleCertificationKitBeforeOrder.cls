public without sharing class B2BHandleCertificationKitBeforeOrder {

    public static Boolean isRunTrigger = true;

    public static void updateOrderItems(String orderId) {
        try {
            isRunTrigger = false;
            
            List<OrderItem> orderItems = [SELECT Id, Product2Id, Product2.Name, Product2.Product_Group__c, Product2.ProductClass
                                        FROM OrderItem 
                                        WHERE OrderId = :orderId
                                        ];

            List<Id> productIds = new List<Id>();

            for(OrderItem oi: orderItems) {
                if(oi.Product2.Product_Group__c == 'Certification Kit') {
                    productIds.add(oi.Product2Id);
                }
                else {
                    continue;
                }
            }
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

            List<Account_Membership__c> accountMemberships = [SELECT Id, Name, Welcome_Kit_Status__c, Certification_Kit_Order__c, Order_Summary__c
                                                            FROM Account_Membership__c
                                                            WHERE Account_Id__c =:accountId AND Membership__r.Individual_Certification_Kit__r.Id IN :productIds 
                                                            AND Welcome_Kit_Status__c = 'Unclaimed'
                                                            ];
                                            
            List<Account_Membership__c> itemsToUpdate = new List<Account_Membership__c>();                                                 
            for(Account_Membership__c am : accountMemberships) {
                am.Welcome_Kit_Status__c = 'Claimed';
                am.Certification_Kit_Order__c = orderId;

                itemsToUpdate.add(am);
            }
            
            if(!itemsToUpdate.isEmpty()) {
                update itemsToUpdate;
            }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BHandleCertificationKitBeforeOrder', 'updateCertificationKitStatus');
        }
    }
}