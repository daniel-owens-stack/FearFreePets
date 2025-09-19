public class B2BRenewalInvoiceBatch {

    // public Database.QueryLocator start(Database.BatchableContext bc) {
    //     String query = 
    //             'SELECT Id, AccountId, Account.StripeCustomerId__c, Account.Payment_Terms__c'
    //             + ' FROM Order'
    //             + ' WHERE EffectiveDate = TODAY'
    //             + ' AND IsRenewal__c = TRUE'
    //             + ' AND Status = \'Draft\'' ;
        
    //     return Database.getQueryLocator(query);
    // }

    // public void execute(Database.BatchableContext bc, List<Order> scope) {
    //     try {
    //         for (Order record : scope) {
    //             B2BRenewalController.handleInvoiceCreation(record);
    //         }

    //     } catch (Exception e) {
    //         B2BHandleCustomException.LogException(e, 'B2BRenewalInvoiceBatch', 'execute');
    //     }
    // }

    // public void finish(Database.BatchableContext bc) {

    // }
}