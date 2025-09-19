@isTest
public class FFHandleLMSUserFlowActionTest {

    // Mock HTTP response for callouts
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest static void testHandleLMSUserInvocable() {
        // Create test Account (business account)
        Account testAccount = new Account(Name = 'Test Business Account');
        insert testAccount;

        // Create Contact linked to the Account
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Prepare input for invocable method with decimal values
        FFHandleLMSUserFlowAction.LMSUserInput input = new FFHandleLMSUserFlowAction.LMSUserInput();
        input.contactId = testContact.Id;
        input.courseIdsRaw = new List<Decimal>{123.4, 456.6, 789.0}; // raw decimal values

        // Register mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
            List<FFHandleLMSUserFlowAction.LMSUserInput> inputs = new List<FFHandleLMSUserFlowAction.LMSUserInput>{input};
            List<FFHandleLMSUserFlowAction.LMSUserOutput> outputs = FFHandleLMSUserFlowAction.handleLMSUser(inputs);

            // Assert the job was queued successfully
            System.assertEquals(1, outputs.size());
            System.assert(outputs[0].resultMessage.contains('Queued successfully'));
        Test.stopTest();
    }
}