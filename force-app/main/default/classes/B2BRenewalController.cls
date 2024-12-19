public class B2BRenewalController {
    public static void handlePLMA(Account record) {
        
        List<B2BPracticeLevelRenewalsWrapper.PracticeLevelMembershipAssignment> plmaList = B2BPracticeLevelRenewalsService.getPracticeLevelMembershipAssignments(record.Id);
        if (plmaList == null || plmaList.isEmpty()) {
            return;
        }

        B2BPracticeLevelRenewalsWrapper.BusinessAccount businessAccount = B2BPracticeLevelRenewalsService.getBusinessAccount(record);
        B2BPracticeLevelRenewalsWrapper.Order order = B2BPracticeLevelRenewalsService.createOrder(businessAccount);
        B2BPracticeLevelRenewalsService.createOrderItems(plmaList, order);
    }

    public static void handleILMA(Account record) {
        System.debug('GETTING ORDER');

        List<B2BIndividualLevelRenewalsWrapper.IndividualLevelMembershipAssignment> ilmaList = B2BIndividualLevelRenewalsService.getIndividualLevelMembershipAssignments(record.Id);
        if (ilmaList == null || ilmaList.isEmpty()) {

            return;
        }

        B2BIndividualLevelRenewalsWrapper.ParentAccount parentAccount = B2BIndividualLevelRenewalsService.getParentAccount(record);
    
        B2BIndividualLevelRenewalsWrapper.Order order;
        order = B2BIndividualLevelRenewalsService.getExistingOrder(record);
        if(order == null) {

            order = B2BIndividualLevelRenewalsService.createOrder(parentAccount);
        }
        
        B2BIndividualLevelRenewalsService.createOrderItems(ilmaList, order);
    }

    public static void handleInvoiceCreation(Order record) {
        
        String orderId = record.Id;
        System.debug('DEBUG ' + record);
        String stripeInvoiceId = B2BStripePaymentController.createInvoiceByOrderId(orderId, record.Account.StripeCustomerId__c, record.Account.Id);
    }
}