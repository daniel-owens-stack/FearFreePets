public with sharing class StripeBillingController {
    @AuraEnabled
    public static String createBillingPortalSession() {
        // Get logged-in user's contact
        Id currentUserId = UserInfo.getUserId();
        System.debug('Current User ID: ' + currentUserId);
        
        // Check if the current user is an admin
        User u = [SELECT AccountId FROM User WHERE Id = :currentUserId LIMIT 1];
        if (u.AccountId == null) {
            throw new AuraHandledException('No Account is associated with the logged-in user.');
        }
        
        // Get the person account
        Account acct = [SELECT StripeCustomerId__c FROM Account WHERE Id = :u.AccountId LIMIT 1];
        if (String.isBlank(acct.StripeCustomerId__c)) {
            throw new AuraHandledException('Stripe Customer ID not found.');
        }

        // Construct return URL
        String returnUrl = 'https://my.fearfree.com/my-billing';

        // Build request body
        String body = 'customer=' + EncodingUtil.urlEncode(acct.StripeCustomerId__c, 'UTF-8') +
                      '&return_url=' + EncodingUtil.urlEncode(returnUrl, 'UTF-8');

        // Set up HTTP callout to Stripe using Anonymous Named Credential
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:StripeAnonymous/v1/billing_portal/sessions');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Authorization', 'Bearer ' + Label.Stripe_Secret_Key);
        req.setBody(body);

        // Send request
        Http http = new Http();
        HttpResponse res = http.send(req);

        // Handle response
        if (res.getStatusCode() == 200) {
            Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) json.get('url');
        } else {
            throw new AuraHandledException('Stripe error: ' + res.getStatusCode() + ' ' + res.getBody());
        }
    }
}