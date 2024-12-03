@isTest 
public class B2BEditAccountDetailsControllerTest {

    @isTest static void testUpdateAccountRecord () {
        String accountId = B2BTestDataFactory.createAccount();
        Map<String, String> accountDetails = new Map<String, String> {
            'Id' => accountId,
            'licenseNumber' => 'Test123',
            'ccpdtNumber' => 'Test 456'
        };

        Test.StartTest();
        B2BEditAccountDetailsController.updateAccountRecord(accountDetails);
        Test.StopTest();
    }

    @isTest static void testUpdateAccountRecord_exception () {
        try {
            Test.StartTest();
            B2BEditAccountDetailsController.updateAccountRecord(null);
            Test.StopTest();
        }
        catch(Exception e) {}
    }
}