@IsTest
public class B2BUpdateIncorrectOrderDatesTest {

    @TestSetup static void makeData(){
        
        B2BTestDataFactory.createWebStore();
        String webStoreId  = [SELECT Id FROM WebStore WHERE Name = 'TestWebStore' LIMIT 1].Id;
        String accountId = B2BTestDataFactory.createAccount();
        String contactId = B2BTestDataFactory.createContact(accountId);
        User user = B2BTestDataFactory.createCommunityUser(contactId);
        String productId = B2BTestDataFactory.createProduct();

        Id orderId = B2BTestDataFactory.createOrder(accountId, productId);

        //Create Historical Order
        Historical_Order__c ho = new Historical_Order__c();
        ho.Historical_Order_Id__c = '459312';
        ho.Post_Author__c = 1;
        ho.Post_Date__c = Date.valueOf('2017-04-20');
        ho.Post_Title__c = 'Order &ndash; April 20, 2017 @ 05:04 PM';
        ho.Post_Name__c = 'order-apr-20-2017-1104-pm';
        ho.Post_Modified__c = Date.valueOf('2017-04-20');
        ho.Guid__c = 'https://stg-fearfreepetsmainwebsite-stage.kinsta.cloud/?post_type=shop_order&#038;p=45931';
        ho.Billing_FirstName__c = 'Test';
        ho.Billing_LastName__c = 'Toay';
        ho.Billing_Company__c = 'Midwest Veterinary Supply';
        ho.Billing_Email__c = 'test.123+1@gmail.com';
        ho.Billing_Phone__c = '402-677-3244';
        ho.Billing_Address__CountryCode__s = 'US';
        ho.FFP_Professional_Role__c = 'Faculty';
        ho.First_Name__c = 'Test';
        ho.Last_Name__c = 'Toay';
        ho.Group_Role__c = 'Leader';
        ho.Member_of_Group__c = '440830';
        ho.Successful_Insert__c = 'Pending';
        ho.User_Id__c = '12629';
        ho.Shipping_Address__CountryCode__s = 'US'; 
        ho.Date_Created__c = System.now().addDays(-10);
        ho.Order_Date__c = System.today().addDays(-12);
        ho.SF_Order__c = orderId;

        insert ho;

        //Create Historical OrderItem
        Historical_Order_Item__c hoi = new Historical_Order_Item__c();
        hoi.Historical_Order_Item_Id__c = '1234567';
        hoi.Historical_Order_Id__c = '459312';
        hoi.Product_Id__c = '234567';
        hoi.Quantity__c = 1;
        hoi.Line_Total__c = 5;
        
        insert hoi;
    }

    @isTest
    static void testBatchUpdatesOrdersAndSummaries() {
        Test.startTest();
        Database.executeBatch(new B2BUpdateIncorrectOrderDates(), 50);
        Test.stopTest();
    }

    @isTest
    static void testOrderPrepException() {
        B2BUpdateIncorrectOrderDates.testThrowPrepException = true;
        Test.startTest();
        Database.executeBatch(new B2BUpdateIncorrectOrderDates(), 50);
        Test.stopTest();
        B2BUpdateIncorrectOrderDates.testThrowPrepException = false;
    }

    @isTest
    static void testSummaryUpdateException() {
        B2BUpdateIncorrectOrderDates.testThrowSummaryUpdateException = true;
        Test.startTest();
        Database.executeBatch(new B2BUpdateIncorrectOrderDates(), 50);
        Test.stopTest();
        B2BUpdateIncorrectOrderDates.testThrowSummaryUpdateException = false;
    }
}