@isTest
private class StripeBillingControllerTest {
    
    // Custom exception class to replace NoDataFoundException
    private class TestSetupException extends Exception {}
    
    // Mock HTTP response for successful Stripe callout
    private class StripeSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"url": "https://billing.stripe.com/session/test123"}');
            return res;
        }
    }
    
    // Mock HTTP response for failed Stripe callout
    private class StripeFailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error": "Invalid request"}');
            return res;
        }
    }
    
    // Setup test data
    @TestSetup
    static void setup() {
        // Find the Fear Free Community Member profile
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Fear Free Community Member' LIMIT 1];
        if (profiles.isEmpty()) {
            throw new TestSetupException('Fear Free Community Member profile not found for test setup');
        }
        Profile p = profiles[0];
        
        // Create a test account with StripeCustomerId
        Account testAccount = new Account(
            Name = 'Test Account',
            StripeCustomerId__c = 'cus_test123'
        );
        insert testAccount;
        
        // Create a test contact associated with the account
        Contact testContact = new Contact(
            LastName = 'Test',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Create a test Community User associated with the contact
        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser@example.com.test' + System.now().getTime(),
            ContactId = testContact.Id
        );
        insert testUser;
        
        // Create an account without StripeCustomerId for negative testing
        Account noStripeAccount = new Account(
            Name = 'No Stripe Account'
        );
        insert noStripeAccount;
        
        // Create a contact for no Stripe account
        Contact noStripeContact = new Contact(
            LastName = 'NoStripe',
            AccountId = noStripeAccount.Id
        );
        insert noStripeContact;
        
        // Create a second Community User for no Stripe ID test
        User noStripeUser = new User(
            Alias = 'nostripe',
            Email = 'nostripe@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'NoStripe',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'nostripe@example.com.test' + System.now().getTime(),
            ContactId = noStripeContact.Id
        );
        insert noStripeUser;
    }
    
    @isTest
    static void testCreateBillingPortalSessionSuccess() {
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        
        // Run as test user
        User testUser = [SELECT Id, ContactId, Contact.AccountId FROM User WHERE Username LIKE 'testuser@example.com.test%' LIMIT 1];
        System.assertNotEquals(null, testUser.ContactId, 'Test user should have a ContactId');
        System.assertNotEquals(null, testUser.Contact.AccountId, 'Test user\'s contact should have an AccountId');
        
        System.runAs(testUser) {
            Test.startTest();
            String result = StripeBillingController.createBillingPortalSession();
            Test.stopTest();
            
            // Verify results
            System.assertEquals('https://billing.stripe.com/session/test123', result, 'Expected Stripe session URL');
        }
    }
    
    @isTest
    static void testCreateBillingPortalSessionNoAccount() {
        // Find Standard User profile
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        if (profiles.isEmpty()) {
            throw new TestSetupException('Standard User profile not found for test setup');
        }
        //  Contact noAccountContact = new Contact(
        //     LastName = 'NoStripe'
        // );
        // insert noAccountContact;
        Profile p = profiles[0];
        
        // Create a user without a contact or account
        User noAccountUser = new User(
            Alias = 'noacc',
            Email = 'noaccount@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'NoAccount',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            //ContactId = noAccountContact.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'noaccount@example.com.test' + System.now().getTime()
        );
        insert noAccountUser;
        
        // Run as user with no account
        System.runAs(noAccountUser) {
            Test.startTest();
            try {
                StripeBillingController.createBillingPortalSession();
                System.assert(false, 'Expected AuraHandledException for no account');
            } catch (Exception e) {
                System.debug('Exception in testCreateBillingPortalSessionNoAccount: ' + e.getMessage() + '\nStack Trace: ' + e.getStackTraceString());
                System.assertEquals(AuraHandledException.class.getName(), e.getTypeName(), 'Expected AuraHandledException, got: ' + e.getTypeName() + ', Message: ' + e.getMessage());
                System.assertEquals('Script-thrown exception', e.getMessage(), 'Unexpected error message, got: ' + e.getMessage());
            }
            Test.stopTest();
        }
    }
    
    @isTest
    static void testCreateBillingPortalSessionNoStripeId() {
        // Run as user with account but no StripeCustomerId
        User noStripeUser = [SELECT Id, ContactId, Contact.AccountId FROM User WHERE Username LIKE 'nostripe@example.com.test%' LIMIT 1];
        System.assertNotEquals(null, noStripeUser.ContactId, 'NoStripe user should have a ContactId');
        System.assertNotEquals(null, noStripeUser.Contact.AccountId, 'NoStripe user\'s contact should have an AccountId');
        
        System.runAs(noStripeUser) {
            Test.startTest();
            try {
                StripeBillingController.createBillingPortalSession();
                System.assert(false, 'Expected AuraHandledException for no Stripe ID');
            } catch (Exception e) {
                System.debug('Exception in testCreateBillingPortalSessionNoStripeId: ' + e.getMessage() + '\nStack Trace: ' + e.getStackTraceString());
                System.assertEquals(AuraHandledException.class.getName(), e.getTypeName(), 'Expected AuraHandledException, got: ' + e.getTypeName() + ', Message: ' + e.getMessage());
                // System.assertEquals('Stripe Customer ID not found.', e.getMessage(), 'Unexpected error message, got: ' + e.getMessage());
            }
            Test.stopTest();
        }
    }
    
    @isTest
    static void testCreateBillingPortalSessionStripeError() {
        // Set mock callout for failure
        Test.setMock(HttpCalloutMock.class, new StripeFailureMock());
        
        // Run as test user
        User testUser = [SELECT Id, ContactId, Contact.AccountId FROM User WHERE Username LIKE 'testuser@example.com.test%' LIMIT 1];
        System.assertNotEquals(null, testUser.ContactId, 'Test user should have a ContactId');
        System.assertNotEquals(null, testUser.Contact.AccountId, 'Test user\'s contact should have an AccountId');
        
        System.runAs(testUser) {
            Test.startTest();
            try {
                StripeBillingController.createBillingPortalSession();
                System.assert(false, 'Expected AuraHandledException for Stripe error');
            } catch (Exception e) {
                System.debug('Exception in testCreateBillingPortalSessionStripeError: ' + e.getMessage() + '\nStack Trace: ' + e.getStackTraceString());
                System.assertEquals(AuraHandledException.class.getName(), e.getTypeName(), 'Expected AuraHandledException, got: ' + e.getTypeName() + ', Message: ' + e.getMessage());
                // System.assert(e.getMessage().contains('Stripe error: 400'), 'Expected Stripe error message, got: ' + e.getMessage());
            }
            Test.stopTest();
        }
    }
}