@isTest
private class B2BILMAFromCaseControllerTest {
    @isTest
    static void coverGetAccountMembershipsForCase() {
        Id accountId = B2BTestDataFactory.createPersonAccount();

        Contact contact = new Contact(FirstName = 'Test', LastName = 'User', AccountId = accountId);
        insert contact;

        Case c = new Case(ContactId = contact.Id, Subject = 'ILMA Test Case');
        insert c;

        Membership__c membership = new Membership__c(Name = 'Test Membership');
        insert membership;

        Account_Membership__c accMem = new Account_Membership__c(
            Membership__c = membership.Id,
            Account_Id__c = accountId,
            Account_Assignment_Date__c = Date.today(),
            Status__c = 'Active'
        );
        insert accMem;

        Test.startTest();
        B2BILMAFromCaseController.getAccountMembershipsForCase(c.Id);
        Test.stopTest();
    }
}