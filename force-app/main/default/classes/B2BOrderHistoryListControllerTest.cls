@IsTest(SeeAllData=true)
public class B2BOrderHistoryListControllerTest {
    
    public static void makeData(){
        B2BTestDataFactory.createWebStore();
        String webStoreId  = [SELECT Id FROM WebStore WHERE Name = 'TestWebStore' LIMIT 1].Id;
        String accountId = B2BTestDataFactory.createAccount();
        String contactId = B2BTestDataFactory.createContact(accountId);
        User user = B2BTestDataFactory.createCommunityUser(contactId);
        String productId = B2BTestDataFactory.createProduct();
    }

    public static String createOrderSummary() {
        makeData();
        String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        String productId = [SELECT Id FROM Product2 WHERE Name = 'Test Product1' LIMIT 1].Id;

        Id orderId = B2BTestDataFactory.createOrder(accountId, productId);

        ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
        osir.orderId = orderId;
        osir.orderLifeCycleType = 'UNMANAGED';
        ConnectApi.OrderSummaryOutputRepresentation osor = ConnectApi.OrderSummaryCreation.createOrderSummary(osir);

        String orderSummaryId = osor.orderSummaryId;
        return orderSummaryId;
    }

    @isTest static void testGetOrderSummaries() {
        Test.StartTest();
        createOrderSummary();

        Map<String, Object> inputParameters = new Map<String, Object>();
        inputParameters.put('sortingOrder', 'ASC');
        inputParameters.put('startDate', System.today().addDays(-1));
        inputParameters.put('endDate', System.today());

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];
        System.runAs(user) {
            B2BOrderHistoryListController.getOrderSummaries(inputParameters);
        }
        Test.StopTest();
    }

    @isTest static void testGetOrderSummaries_Admin() {
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
            B2BOrderHistoryListController.getOrderSummaries(inputParameters);
        }
        Test.StopTest();
    }

    @isTest static void testGetOrderSummaryItems() {
        Test.StartTest();
        String orderSummaryId = createOrderSummary();
        B2BOrderHistoryListController.getOrderSummaryItems(orderSummaryId);
        Test.StopTest();
    }

    // @isTest static void testGetOrderDeliveryGroupSummary() {
    //     Test.StartTest();
    //     B2BOrderHistoryListController.
    //     Test.StopTest();
    // }
}