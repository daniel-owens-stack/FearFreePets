public class B2BRenewalInvoiceBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    private String query;

    public B2BRenewalInvoiceBatch(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Order> scope) {
        try {
            for (Order record : scope) {
                if(record.Account.Payment_Terms__c == '	Credit Card Only') {
                    B2BRenewalController.handleInvoiceCreation(record);
                }
            }

        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BRenewalInvoiceBatch', 'execute');
        }
    }

    public void finish(Database.BatchableContext bc) {

    }
}