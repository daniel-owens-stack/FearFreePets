public without sharing class B2BInvoiceHelper {
    
    @AuraEnabled(cacheable=true)
    public static List<InvoiceWrapper> getInvoices() {

        String userId = UserInfo.getUserId();
        User u = [SELECT Id, ContactId
                  FROM User
                  WHERE Id = :userId];

        Contact contact = [SELECT Id, AccountId
                           FROM Contact
                           WHERE Id = :u.ContactId];
        Id accountId = contact.AccountId;

        List<Invoice__c> invoices = new List<Invoice__c>();
        invoices = [SELECT Id, Name, Total__c, Amount_Charged__c, Period_Start_Date__c, Period_End_Date__c, Created_Date__c, Payment_Date__c, Stripe_PDF_URL__c, Stripe_Payment_URL__c, Status__c
                    FROM Invoice__c
                    WHERE Account_Id__c =:accountId AND Stripe_Payment_URL__c != null
                    ORDER BY Created_Date__c DESC
                   ];

        List<InvoiceWrapper> invoiceList = new List<InvoiceWrapper>();

        for(Invoice__c invoice : invoices) {

            InvoiceWrapper iw = new InvoiceWrapper();
            iw.id = invoice.Id;
            iw.invoiceNumber = invoice.Name;
            iw.total = invoice.Total__c;
            iw.amountCharged = invoice.Amount_Charged__c;
            iw.period = String.valueOf(invoice.Period_Start_Date__c.daysBetween(invoice.Period_End_Date__c)) + ' Days';
            iw.createdDate = invoice.Created_Date__c.date();
            iw.paidDate = invoice.Payment_Date__c;
            iw.downloadLink = invoice.Stripe_PDF_URL__c;
            iw.paymentLink = invoice.Stripe_Payment_URL__c;
            iw.disablePayNow = invoice.Status__c == 'Disabled' ? true : false;

            invoiceList.add(iw);
        }
        System.debug('invoice list: ' + invoiceList[0]);
        return invoiceList;
    }
        
    public class InvoiceWrapper {

        @AuraEnabled
        public String id { get; set; }

        @AuraEnabled
        public String invoiceNumber { get; set; }

        @AuraEnabled
        public Decimal total { get; set; }

        @AuraEnabled
        public Decimal amountCharged { get; set; }

        @AuraEnabled
        public String period { get; set; }

        @AuraEnabled
        public Date createdDate { get; set; }

        @AuraEnabled
        public Date paidDate { get; set; }

        @AuraEnabled
        public String downloadLink { get; set; }

        @AuraEnabled
        public String paymentLink { get; set; }

        @AuraEnabled
        public Boolean disablePayNow { get; set; }
    }
}