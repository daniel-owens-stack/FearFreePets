public class B2BChargeCustomerInvoice {

    @AuraEnabled
    public static Invoice__c getInvoice(String invoiceId) {
        Invoice__c invoice= [SELECT Id, Stripe_Invoice_Id__c, Status__c,Stripe_Payment_URL__c FROM Invoice__c WHERE Id =:invoiceId];
        return invoice;
    }
    
    @AuraEnabled
    public static String chargeCustomerInvoice(List<String> invoiceIds) {
        try {
            //Get related orders of each invoice
            List<Order> orders = [SELECT Id, InvoiceId__c, AccountId FROM Order WHERE InvoiceId__c IN :invoiceIds];

            Map<Id, String> orderToInvoiceMap = new Map<Id, String>();
            Map<Id, Id> orderToAccountMap = new Map<Id, Id>();

            for (Order order : orders) {
                orderToInvoiceMap.put(order.Id, order.InvoiceId__c);
                orderToAccountMap.put(order.Id, order.AccountId);
            }
            
            Set<Id> orderIds = orderToInvoiceMap.keySet();
            Set<Id> accountIds = new Set<Id>(orderToAccountMap.values());

            Set<Id> businessIds = new Set<Id>();
            Map<Id, Id> businessToAccountMap = new Map<Id, Id>();
            
            if (!accountIds.isEmpty()) {
                List<Account> accounts = [SELECT Id, Business__c FROM Account WHERE Id IN :accountIds];
                
                for (Account acc : accounts) {
                    if (acc.Business__c != null) {
                        businessIds.add(acc.Business__c);
                        businessToAccountMap.put(acc.Business__c, acc.Id);
                    }
                }
            }
            
            //Get Order Items for each order to get the memberships
            List<OrderItem> orderItems = [
                SELECT Id, OrderId, Product2.Membership__r.Id
                FROM OrderItem 
                WHERE OrderId IN :orderIds AND Type = 'Order Product'
            ];
            
            Set<Id> membershipIds = new Set<Id>();
            Map<Id, Id> membershipToAccountMap = new Map<Id, Id>();

            for (OrderItem item : orderItems) {
                Id accountId = orderToAccountMap.get(item.OrderId);
                if (item.Product2.Membership__r.Id != null) {
                    membershipIds.add(item.Product2.Membership__r.Id);
                    membershipToAccountMap.put(item.Product2.Membership__r.Id, accountId);
                }
            }
            
            Set<String> invoiceIdsToCharge = new Set<String>(invoiceIds);
            Map<Id, List<Account_Membership__c>> canceledMemberships_Individal = new Map<Id, List<Account_Membership__c>>();
            Map<Id, List<Practice_Level_Membership_Assignment__c>> canceledMemberships_Practice = new Map<Id, List<Practice_Level_Membership_Assignment__c>>();
            
            if (!accountIds.isEmpty() && !membershipIds.isEmpty()) {

                //Check for Canceled Individual Memberships
                List<Account_Membership__c> individualMemberships = [
                    SELECT Id, Membership__c, Status__c, Account_Id__c
                    FROM Account_Membership__c 
                    WHERE Membership__c IN :membershipIds 
                    AND Account_Id__c IN :accountIds
                    AND Status__c = 'Canceled' 
                    ORDER BY CreatedDate Desc NULLS LAST
                ];
                
                for (Account_Membership__c am : individualMemberships) {
                    if (!canceledMemberships_Individal.containsKey(am.Account_Id__c)) {
                        canceledMemberships_Individal.put(am.Account_Id__c, new List<Account_Membership__c>());
                    }
                    canceledMemberships_Individal.get(am.Account_Id__c).add(am);
                }
                

                //Check for Canceled Practice Memberships
                List<Practice_Level_Membership_Assignment__c> practiceMemberships = [
                    SELECT Id, Membership__c, Status__c 
                    FROM Practice_Level_Membership_Assignment__c 
                    WHERE Membership__c IN :membershipIds 
                    AND Business_Account__c IN :businessIds
                    AND Status__c = 'Canceled'
                    ORDER BY CreatedDate Desc NULLS LAST
                ];
                
                for (Practice_Level_Membership_Assignment__c pm : practiceMemberships) {
                    Id associatedAccountId = businessToAccountMap.get(pm.Business_Account__c);

                    if (!canceledMemberships_Practice.containsKey(associatedAccountId)) {
                        canceledMemberships_Practice.put(associatedAccountId, new List<Practice_Level_Membership_Assignment__c>());
                    }
                    canceledMemberships_Practice.get(associatedAccountId).add(pm);
                }

                for (OrderItem item : orderItems) {
                    Id accountId = membershipToAccountMap.get(item.Product2.Membership__r.Id);
                    if (accountId != null && 
                        (canceledMemberships_Individal.containsKey(accountId) || canceledMemberships_Practice.containsKey(accountId))) {
                        String invoiceId = orderToInvoiceMap.get(item.OrderId);
                        invoiceIdsToCharge.remove(invoiceId);
                    }
                }
            }
            
            if(!invoiceIdsToCharge.isEmpty()) {
                for (String invoiceId : invoiceIdsToCharge) {
                    B2BStripePaymentController.chargeCustomerInvoice(invoiceId);
                }
            }
            return 'success';
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BChargeCustomerInvoiceInvocable', 'chargeCustomerInvoice');
            return e.getMessage();
        } 
    } 
}