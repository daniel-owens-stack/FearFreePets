public class B2BRenewalController {
    public static void handlePLMA(Account record) {
        
        List<B2BPracticeLevelRenewalsWrapper.PracticeLevelMembershipAssignment> plmaList = B2BPracticeLevelRenewalsService.getPracticeLevelMembershipAssignments(record.Id);
        if (plmaList == null || plmaList.isEmpty()) {
            return;
        }

        Date nearestRenewalDate = plmaList[0].expirationDate;
        B2BPracticeLevelRenewalsWrapper.BusinessAccount businessAccount = B2BPracticeLevelRenewalsService.getBusinessAccount(record, nearestRenewalDate);
        B2BPracticeLevelRenewalsWrapper.Order order = B2BPracticeLevelRenewalsService.createOrder(businessAccount);
        B2BPracticeLevelRenewalsService.createOrderItems(plmaList, order);
    }

    public static void handleILMA(Account record) {

        List<B2BIndividualLevelRenewalsWrapper.IndividualLevelMembershipAssignment> ilmaList = B2BIndividualLevelRenewalsService.getIndividualLevelMembershipAssignments(record.Id);
        if (ilmaList == null || ilmaList.isEmpty()) {
            return;
        }

        Date nearestRenewalDate = ilmaList[0].expirationDate;
        B2BIndividualLevelRenewalsWrapper.ParentAccount parentAccount = B2BIndividualLevelRenewalsService.getParentAccount(record, nearestRenewalDate);
    
        B2BIndividualLevelRenewalsWrapper.Order order;
        order = B2BIndividualLevelRenewalsService.getExistingOrder(record);
        if(order == null) {

            order = B2BIndividualLevelRenewalsService.createOrder(parentAccount);
        }
        
        B2BIndividualLevelRenewalsService.createOrderItems(ilmaList, order);
    }

    public static void handleInvoiceCreation(Order record) {
        
        String orderId = record.Id;
        String accountId = record.Account.Id;

        //Get OrderItems of type 'Order Product'
        List<OrderItem> orderItems = [
            SELECT Id, OrderId, Product2.Membership__r.Id
            FROM OrderItem 
            WHERE OrderId = :orderId AND Type = 'Order Product'
        ];

        //Collect MembershipIds of each order item
        Set<Id> membershipIds = new Set<Id>();
        for (OrderItem item : orderItems) {
            if (item.Product2.Membership__r.Id != null) {
                membershipIds.add(item.Product2.Membership__r.Id);
            }
        }
        
        if (accountId != null) {
            Account account = [SELECT Id, Business__c FROM Account WHERE Id = :accountId];
            if (account.Business__c != null) {
                accountId = account.Business__c;
            }

            Set<Id> activeMembershipIds = new Set<Id>();
            if(!membershipIds.isEmpty()) {

                //Check if Individual Memberships are Active to Renew
                List<Account_Membership__c> activeIndividualMemberships = [
                    SELECT Id, Membership__c, Status__c, Account_Id__c
                    FROM Account_Membership__c 
                    WHERE Membership__c IN :membershipIds 
                    AND Parent_Id__c = :accountId
                    AND Status__c = 'Active'
                    ORDER BY CreatedDate Desc NULLS LAST
                ];

                if(activeIndividualMemberships.size() > 0) {
                    for(Account_Membership__c am : activeIndividualMemberships) {
                        activeMembershipIds.add(am.Membership__c);
                    }
                }

                //Check if Practice Memberships are Active to Renew
                List<Practice_Level_Membership_Assignment__c> activePracticeMemberships = [
                    SELECT Id, Membership__c, Status__c 
                    FROM Practice_Level_Membership_Assignment__c 
                    WHERE Membership__c IN :membershipIds 
                    AND Business_Account__c = :accountId
                    AND Status__c = 'Active'
                    ORDER BY CreatedDate Desc NULLS LAST
                ];

                if(activePracticeMemberships.size() > 0) {
                    for(Practice_Level_Membership_Assignment__c pm : activePracticeMemberships) {
                        activeMembershipIds.add(pm.Membership__c);
                    }
                }
            }

            //If there are no active memberships delete the orderitems with the corresponding membershipids
            List<OrderItem> orderItemsToDelete = new List<OrderItem>();

            if(!activeMembershipIds.isEmpty()) {
                for (OrderItem item : orderItems) {
                    if(!activeMembershipIds.contains(item.Product2.Membership__r.Id)) {
                        orderItemsToDelete.add(item);
                    }
                }

                if(!orderItemsToDelete.isEmpty()) {
                    delete orderItemsToDelete;
                }

                String stripeInvoiceId = B2BStripePaymentController.createInvoiceByOrderId(orderId, record.Account.StripeCustomerId__c, record.Account.Id);
            }
        }
    }
}