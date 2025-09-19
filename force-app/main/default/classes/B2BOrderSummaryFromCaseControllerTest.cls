@isTest
private class B2BOrderSummaryFromCaseControllerTest {
    @isTest
    static void coverGetOrdersForCase() {
        Id accountId = B2BTestDataFactory.createPersonAccount();

        Contact contact = new Contact(FirstName = 'Test', LastName = 'User', AccountId = accountId);
        insert contact;

        Case c = new Case(ContactId = contact.Id, Subject = 'Order Summary Test Case');
        insert c;

        OrderSummary order = new OrderSummary(
            OrderNumber = 'SO-001',
            OrderedDate = Date.today(),
            AccountId = accountId
        );
        insert order;

        Test.startTest();
        B2BOrderSummaryFromCaseController.getOrdersForCase(c.Id);
        Test.stopTest();
    }
}