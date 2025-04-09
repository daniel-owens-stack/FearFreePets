@isTest
public class B2BCreateHistoricalOrdersBatchTest {

    @TestSetup static void makeData(){

        //Create Person Account with Customer Email
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account account = new Account(
            FirstName = 'TestFFP',
            LastName = 'Account',
            PersonEmail = 'test.123+1@gmail.com',
            RecordTypeId = recordTypeId
        );
        insert account;

        //Create Product with Historical Order Id
        Product2 product = new Product2(
            Name = 'Test Product',
            WC_Id__c = '234567',
            IsActive = true
        );
        insert product;

        //Create Historical Order
        Historical_Order__c ho = new Historical_Order__c();
        ho.Historical_Order_Id__c = '45931';
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

        insert ho;

       //Create Historical OrderItem
       Historical_Order_Item__c hoi = new Historical_Order_Item__c();
       hoi.Historical_Order_Item_Id__c = '123456';
       hoi.Historical_Order_Id__c = '45931';
       hoi.Product_Id__c = '234567';
       hoi.Quantity__c = 1;
       hoi.Line_Total__c = 5;
       
       insert hoi;
    }

    @isTest static void testB2BCreateHistoricalOrdersBatch() {

        //Create a Shipping Product
        Product2 p = new Product2(
            Name = 'Delivery Charge',
            IsActive = true
        );
        insert p;

        //Create Default Delivery Method
        OrderDeliveryMethod odm = new OrderDeliveryMethod();
        odm.Name = 'Default Delivery Method';
        odm.Carrier = 'Carrier Unavailable';
        odm.ClassOfService = 'Digital Shipping';
        odm.IsActive = true;
        odm.ProductId = p.Id;

        insert odm;

        Test.StartTest();
        B2BCreateHistoricalOrdersBatch b = new B2BCreateHistoricalOrdersBatch();
        Database.executeBatch(b);
        Test.StopTest();
    }

    @isTest static void testB2BCreateHistoricalOrdersBatch_withoutDeliveryMethod() {
        //Create a Shipping Product
        Product2 p = new Product2(
            Name = 'Delivery Charge',
            IsActive = true
        );
        insert p;

        Test.StartTest();
        B2BCreateHistoricalOrdersBatch b = new B2BCreateHistoricalOrdersBatch();
        Database.executeBatch(b);
        Test.StopTest();
    }

    @isTest static void testB2BCreateHistoricalOrdersBatch_withoutShippingProduct() {
        //Create a Shipping Product
        Product2 p = new Product2(
            Name = 'Delivery Charge'
        );
        insert p;

        //Create Default Delivery Method
        OrderDeliveryMethod odm = new OrderDeliveryMethod();
        odm.Name = 'Default Delivery Method';
        odm.Carrier = 'Fedex';
        odm.ClassOfService = 'Digital Shipping';
        odm.IsActive = true;
        odm.ProductId = p.Id;

        insert odm;
        
        Test.StartTest();
        B2BCreateHistoricalOrdersBatch b = new B2BCreateHistoricalOrdersBatch();
        Database.executeBatch(b);
        Test.StopTest();
    }

    @isTest static void testB2BCreateHistoricalOrdersBatch_invalidEmail() {

        //Create a Shipping Product
        Product2 p = new Product2(
            Name = 'Delivery Charge',
            IsActive = true
        );
        insert p;

        //Create Default Delivery Method
        OrderDeliveryMethod odm = new OrderDeliveryMethod();
        odm.Name = 'Default Delivery Method';
        odm.Carrier = 'Carrier Unavailable';
        odm.ClassOfService = 'Digital Shipping';
        odm.IsActive = true;
        odm.ProductId = p.Id;

        insert odm;

        Historical_Order__c ho = [SELECT Id, Billing_Email__c FROM Historical_Order__c LIMIT 1];
        ho.Billing_Email__c = 'test@gmail.com';
        update ho;

        Test.StartTest();
        B2BCreateHistoricalOrdersBatch b = new B2BCreateHistoricalOrdersBatch();
        Database.executeBatch(b);
        Test.StopTest();
    }

    @isTest static void testB2BCreateHistoricalOrdersBatch_zeroQuantity() {

        //Create a Shipping Product
        Product2 p = new Product2(
            Name = 'Delivery Charge',
            IsActive = true
        );
        insert p;

        //Create Default Delivery Method
        OrderDeliveryMethod odm = new OrderDeliveryMethod();
        odm.Name = 'Default Delivery Method';
        odm.Carrier = 'Carrier Unavailable';
        odm.ClassOfService = 'Digital Shipping';
        odm.IsActive = true;
        odm.ProductId = p.Id;

        insert odm;

        Historical_Order_Item__c hoi = [SELECT Id, Quantity__c FROM Historical_Order_Item__c LIMIT 1];
        hoi.Quantity__c = 0;
        update hoi;

        Test.StartTest();
        B2BCreateHistoricalOrdersBatch b = new B2BCreateHistoricalOrdersBatch();
        Database.executeBatch(b);
        Test.StopTest();
    }
}