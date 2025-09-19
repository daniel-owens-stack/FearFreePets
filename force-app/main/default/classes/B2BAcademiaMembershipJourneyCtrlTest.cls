@isTest
public class B2BAcademiaMembershipJourneyCtrlTest {

    @TestSetup static void makeData(){
        B2BTestDataFactory.createWebStore();
        String webStoreId  = [SELECT Id FROM WebStore WHERE Name = 'TestWebStore' LIMIT 1].Id;
        String accountId = B2BTestDataFactory.createAccount();
        String contactId = B2BTestDataFactory.createContact(accountId);
        User user = B2BTestDataFactory.createCommunityUser(contactId);
        B2BTestDataFactory.createWebCart(webStoreId, accountId, user.Id);
    }
    
    @isTest static void testUploadFile() {
       
        String fileName = 'Test File';
        String base64Content = 'Test Attachment Content';

        String result;
        Test.StartTest();
        result = B2BAcademiaMembershipJourneyController.uploadFile(fileName, base64Content);
        Test.StopTest();

        System.assertEquals('Test File', result, 'File name should match');
    }

    @isTest static void testUploadFile_exception() {
       
        String fileName = 'Test File';
        String base64Content = 'Test Attachment Content';

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        String result;
        Test.StartTest();
        try{
            System.runAs(user) {
                result = B2BAcademiaMembershipJourneyController.uploadFile(fileName, base64Content);
            }
        }
        catch(Exception e) {}
        Test.StopTest();
    }

    @isTest static void testUpdateAccount() {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Test.StartTest();
        System.runAs(user) {
            B2BAcademiaMembershipJourneyController.updateAccount('2020', 'TEST', '', true, false);
        }
        Test.StopTest();
    }

    @isTest static void testUpdateAccount_exception() {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Test.StartTest();
        try {
            B2BAcademiaMembershipJourneyController.updateAccount('2020', 'TEST', '', false, false);
        }
        catch(Exception e) {}
        Test.StopTest();
    }
}