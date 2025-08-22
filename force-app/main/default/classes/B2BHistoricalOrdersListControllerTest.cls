@IsTest(SeeAllData=true)
public class B2BHistoricalOrdersListControllerTest {
    
    public static void makeData(){
        B2BTestDataFactory.createWebStore();
        String webStoreId  = [SELECT Id FROM WebStore WHERE Name = 'TestWebStore' LIMIT 1].Id;
        String accountId = B2BTestDataFactory.createAccount();
        String contactId = B2BTestDataFactory.createContact(accountId);
        User user = B2BTestDataFactory.createCommunityUser(contactId);
        String productId = B2BTestDataFactory.createProduct();

        //Create Product with Historical Order Id
        Product2 product = new Product2(
            Name = 'Test Product',
            WC_Id__c = '234567',
            IsActive = true
        );
        insert product;

        //Create Historical Order
        Historical_Order__c ho = new Historical_Order__c();
        ho.Historical_Order_Id__c = '459315';
        ho.Post_Author__c = 1;
        ho.Order_Date__c = Date.valueOf('2024-04-20');
        ho.Post_Title__c = 'Order &ndash; April 20, 2017 @ 05:04 PM';
        ho.Post_Name__c = 'order-apr-20-2017-1104-pm';
        ho.Date_Created__c = Date.valueOf('2024-04-20');
        ho.Guid__c = 'https://stg-fearfreepetsmainwebsite-stage.kinsta.cloud/?post_type=shop_order&#038;p=45931';
        ho.Billing_FirstName__c = 'Test';
        ho.Billing_LastName__c = 'Toay';
        ho.Billing_Company__c = 'Midwest Veterinary Supply';
        ho.Billing_Email__c = 'testuser@gmail.com';
        ho.Billing_Phone__c = '402-677-3244';
        ho.Billing_Address__CountryCode__s = 'US';
        ho.FFP_Professional_Role__c = 'Faculty';
        ho.First_Name__c = 'Test';
        ho.Last_Name__c = 'Toay';
        ho.Group_Role__c = 'Leader';
        ho.Member_of_Group__c = '440830';
        ho.Successful_Insert__c = 'Pending';
        ho.User_Id__c = '126290';
        ho.Shipping_Address__CountryCode__s = 'US';

        insert ho;

       //Create Historical OrderItem
       Historical_Order_Item__c hoi = new Historical_Order_Item__c();
       hoi.Historical_Order_Item_Id__c = '1234567';
       hoi.Historical_Order_Id__c = '459315';
       hoi.Product_Id__c = '234567';
       hoi.Quantity__c = 1;
       hoi.Line_Total__c = 5;
       
       insert hoi;
    }

    public static String createOrderSummary() {
        makeData();
        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1].Id;

        Id orderId = B2BTestDataFactory.createOrder(accountId, productId);
        Order o = [SELECT Id, Is_Historical_Order__c FROM Order WHERE Id = :orderId LIMIT 1];
        o.Is_Historical_Order__c = true;
        update o;
        
        Historical_Order__c ho = [SELECT Id, SF_Order__c, Date_Created__c FROM Historical_Order__c WHERE Historical_Order_Id__c ='459315' LIMIT 1];
        ho.SF_Order__c = orderId;
        update ho;

        ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
        osir.orderId = orderId;
        osir.orderLifeCycleType = 'UNMANAGED';
        ConnectApi.OrderSummaryOutputRepresentation osor = ConnectApi.OrderSummaryCreation.createOrderSummary(osir);

        String orderSummaryId = osor.orderSummaryId;
        OrderSummary os = [SELECT Id, Historical_Order_Date__c FROM OrderSummary WHERE Id =: orderSummaryId LIMIT 1];
        os.Historical_Order_Date__c = ho.Date_Created__c;
        update os;

        return orderSummaryId;
    }

    @isTest static void testGetOrderSummaries() {
        Test.StartTest();
        createOrderSummary();

        Map<String, Object> inputParameters = new Map<String, Object>();
        inputParameters.put('sortingOrder', 'ASC');

        Account businessAccount = new Account(
            Name = 'Test Business Account'
        );
        insert businessAccount;

        Account account = [SELECT Id, Business__c, Admin_Account__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.Business__c = businessAccount.Id;
        account.Admin_Account__c = true;
        update account;

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        System.runAs(user) {
            B2BHistoricalOrdersListController.getHistoricalOrders(inputParameters);
            String historicalOrderId = '459315';
            B2BHistoricalOrdersListController.getHistoricalOrderItems(historicalOrderId);
        }
        Test.StopTest();
    }
}