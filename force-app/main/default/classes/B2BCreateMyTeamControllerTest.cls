@isTest
public class B2BCreateMyTeamControllerTest {

    @TestSetup static void makeData(){
        String accountId = B2BTestDataFactory.createAccount();
        String contactId = B2BTestDataFactory.createContact(accountId);
        User user = B2BTestDataFactory.createCommunityUser(contactId);
    }

    @isTest static void testUpdateAccountFields() {

        User user = [SELECT Id FROM User WHERE Username = 'testuser@gmail.com' LIMIT 1];

        Account result;
        Test.StartTest();
        System.runAs(user) {
            result = B2BCreateMyTeamController.getAccountDetails();
        }
        Test.StopTest();
    }
}