public class B2BUpdateIncorrectOrderDates implements Database.Batchable<SObject>, Database.Stateful {

    @TestVisible static Boolean testThrowPrepException = false;
    @TestVisible static Boolean testThrowSummaryUpdateException = false;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Name, SF_Order__c, Date_Created__c, Order_Date__c, Exception__c FROM Historical_Order__c WHERE SF_Order__c != null AND Date_Created__c != null ORDER BY SF_Order__r.OrderNumber Desc'
        );
    }

    public void execute(Database.BatchableContext bc, List<Historical_Order__c> scope) {
        List<Order> ordersToUpdate = new List<Order>();
        List<Id> orderIds = new List<Id>();
        List<OrderSummary> summariesToUpdate = new List<OrderSummary>();
        List<Historical_Order__c> historicalOrdersToUpdate = new List<Historical_Order__c>();
        Map<Id, Datetime> orderIdToDateCreatedMap = new Map<Id, Datetime>();

        for (Historical_Order__c ho : scope) {
            try {
                if (Test.isRunningTest() && testThrowPrepException) {
                    throw new HistoricalOrdersException('Forced Prep Exception');
                }

                if (ho.SF_Order__c != null) {
                    Order order = new Order(
                        Id = ho.SF_Order__c,
                        OrderedDate = ho.Date_Created__c
                    );
                    ordersToUpdate.add(order);
                    orderIds.add(ho.SF_Order__c);
                    orderIdToDateCreatedMap.put(ho.SF_Order__c, ho.Date_Created__c);
                }
            } catch (Exception ex) {
                String errorMessage = 'Order Update Prep Failed for Historical Order: ' + ho.Name +
                    ' | Error: ' + ex.getMessage();
                ho.Exception__c = B2BHandleCustomException.LogException(
                    new HistoricalOrdersException(errorMessage),'Historical Orders', 'Order Update'
                );
                historicalOrdersToUpdate.add(ho);
            }
        }

        if (!ordersToUpdate.isEmpty()) {
            Database.SaveResult[] orderResults = Database.update(ordersToUpdate, false);
            for (Integer i = 0; i < orderResults.size(); i++) {
                if (!orderResults[i].isSuccess()) {
                    Historical_Order__c ho = scope[i];
                    for (Database.Error err : orderResults[i].getErrors()) {
                        String errorMessage = 'Order Update Failed for Historical Order: ' + ho.Name +
                            ' | Error: ' + err.getStatusCode() + ' - ' + err.getMessage();
                        ho.Exception__c = B2BHandleCustomException.LogException(
                            new HistoricalOrdersException(errorMessage),'Historical Orders', 'Order Update'
                        );
                        historicalOrdersToUpdate.add(ho);
                    }
                }
            }
        }

        if(!orderIds.isEmpty()) {
            List<OrderSummary> summaries = [
                SELECT Id, Historical_Order_Date__c, OriginalOrderId
                FROM OrderSummary
                WHERE OriginalOrderId IN :orderIds
            ];

            for (OrderSummary os : summaries) {
                Datetime histDate = orderIdToDateCreatedMap.get(os.OriginalOrderId);
                if (histDate != null) {
                    OrderSummary osToUpdate = new OrderSummary(
                        Id = os.Id,
                        Historical_Order_Date__c = histDate
                    );
                    summariesToUpdate.add(osToUpdate);
                }
            }
        }

        if (!summariesToUpdate.isEmpty() || Test.isRunningTest()) {
            try {
                if (Test.isRunningTest() && testThrowSummaryUpdateException) {
                    throw new HistoricalOrdersException('Forced Summary Update Exception');
                }
                update summariesToUpdate;
            } catch (Exception ex) {
                for (Historical_Order__c ho : scope) {
                    String errorMessage = 'OrderSummary Update Failed for Historical Order: ' + ho.Name +
                        ' | Error: ' + ex.getMessage();
                    ho.Exception__c = B2BHandleCustomException.LogException(
                        new HistoricalOrdersException(errorMessage),
                        'Historical Orders', 'OrderSummary Update'
                    );
                    historicalOrdersToUpdate.add(ho);
                }
            }
        }

        // Update Historical_Order__c for any exceptions recorded
        if (!historicalOrdersToUpdate.isEmpty()) {
            update historicalOrdersToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {}

    public class HistoricalOrdersException extends Exception{}
}