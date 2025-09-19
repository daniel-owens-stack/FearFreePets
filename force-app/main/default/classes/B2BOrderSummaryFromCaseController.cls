public with sharing class B2BOrderSummaryFromCaseController {
    @AuraEnabled(cacheable=true)
    public static List<OrderSummary> getOrdersForCase(Id caseId) {
        Case c = [SELECT Contact.AccountId FROM Case WHERE Id = :caseId LIMIT 1];
        if (c.Contact == null || c.Contact.AccountId == null) {
            return new List<OrderSummary>();
        }

        return [
             SELECT Id, OrderNumber, OrderedDate, TotalAmount
            FROM OrderSummary
            WHERE AccountId = :c.Contact.AccountId
            ORDER BY OrderedDate DESC
        ];
    }
}