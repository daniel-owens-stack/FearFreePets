@isTest
public class B2BInvoiceHelperTest {
    
    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String webStoreId  = [SELECT Id FROM WebStore WHERE Name = 'TestWebStore' LIMIT 1].Id;
        String accountId = B2BTestDataFactory.createAccount();
        String contactId = B2BTestDataFactory.createContact(accountId);
        User user = B2BTestDataFactory.createCommunityUser(contactId);

        Invoice__c invoice = new Invoice__c(
            Name = 'IN-TEST-01',  
            Amount_Charged__c = 10, 
            Period_Start_Date__c = Date.valueOf(System.today()), 
            Period_End_Date__c  = System.today().addDays(60), 
            Created_Date__c = System.today(), 
            Payment_Date__c = System.today().addDays(59), 
            Stripe_PDF_URL__c = 'https://www.google.com/', 
            Stripe_Payment_URL__c = 'https://www.google.com/',
            Account_Id__c = accountId,
            Status__c = 'Active'
        );
        insert invoice;

        Invoice_Line__c invoiceLine = new Invoice_Line__c(
            Name = 'IN-LINE-TEST-01',
            InvoiceId__c = invoice.Id,
            Line_Quantity__c = 1,
            Line_SubTotal__c = 10,
            Line_Total__c = 10
        );
        insert invoiceLine;
    }

    @isTest static void testGetInvoices() {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Test.StartTest();
        List<B2BInvoiceHelper.InvoiceWrapper> result;
        System.runAs(user) {
            result = B2BInvoiceHelper.getInvoices();
        }
        Test.StopTest();
    }
}