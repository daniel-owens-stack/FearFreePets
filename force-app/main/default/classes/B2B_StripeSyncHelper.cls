/**
 * @description       : 
 * @author            : Harshvardhan Tiwari
 * @group             : 
 * @last modified on  : 09-18-2025
 * @last modified by  : Harshvardhan Tiwari
**/
public with sharing class B2B_StripeSyncHelper {
    private static final String NAMED_CREDENTIAL = 'StripeCredential';

    public static Map<String,Object> updateStripeCustomer(Map<String,Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';
        HttpResponse res;
        String accountId = (String) mapParams.get('recordId');

        Account accountRecord = [SELECT Id, Name, FirstName, LastName, PersonEmail, StripeCustomerId__c, BillingAddress, 
                                 BillingCountry, BillingState, BillingCountryCode, BillingCity, BillingStreet, 
                                 BillingPostalCode FROM Account WHERE Id=:accountId LIMIT 1];

        String requestBody = buildStripeCustomerRequestBody(accountRecord);
        res = doStripeCustomerUpdateCallout(accountRecord.StripeCustomerId__c, requestBody);

        if (res.getStatusCode() == 200) {
            // System.debug('Stripe customer updated successfully: ' + res.getBody());
            isSuccess = true;
        } else {
            // System.debug('Failed to update Stripe customer. Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
            message = 'Failed to update Stripe customer. Status: ' + res.getStatusCode() + ' Body: ' + res.getBody();
            logStripeSyncException(message);
        }

        mapParams.put('response', res.getBody());
        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);
        return mapParams;
    }

    private static String buildStripeCustomerRequestBody(Account accountRecord) {
        List<String> paramPairs = new List<String>();
        Map<String, String> addressMap = buildAddressMap(accountRecord);

        if (accountRecord.Name != null) {
            paramPairs.add('name=' + EncodingUtil.urlEncode(accountRecord.Name, 'UTF-8'));
        }
        if (accountRecord.PersonEmail != null) {
            paramPairs.add('email=' + EncodingUtil.urlEncode(accountRecord.PersonEmail, 'UTF-8'));
        }
        for (String key : addressMap.keySet()) {
            paramPairs.add('address[' + key + ']=' + EncodingUtil.urlEncode(addressMap.get(key), 'UTF-8'));
        }
        return String.join(paramPairs, '&');
    }

    private static Map<String, String> buildAddressMap(Account accountRecord) {
        Map<String, String> addressMap = new Map<String, String>();
        if(accountRecord.BillingAddress != null) {
            if(accountRecord.BillingStreet != null) addressMap.put('line1', accountRecord.BillingStreet);
            if(accountRecord.BillingCity != null) addressMap.put('city', accountRecord.BillingCity);
            if(accountRecord.BillingCountryCode != null) addressMap.put('state', accountRecord.BillingCountryCode);
            if(accountRecord.BillingPostalCode != null) addressMap.put('postal_code', accountRecord.BillingPostalCode);
            if(accountRecord.BillingCountry != null) addressMap.put('country', accountRecord.BillingCountry);
        }
        return addressMap;
    }

    private static HttpResponse doStripeCustomerUpdateCallout(String stripeCustomerId, String requestBody) {
        HTTP http = new HTTP();
        HTTPRequest request = new HTTPRequest();
        request.setEndpoint('callout:' + NAMED_CREDENTIAL + '/v1/customers/' + stripeCustomerId);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody(requestBody);
        return http.send(request);
    }

    private static void logStripeSyncException(String message) {
        B2B_Custom_Exception__c customException = new B2B_Custom_Exception__c();
        customException.Name = 'Stripe Account Data Sync Exception';
        customException.ClassName__c = 'B2B_StripeSyncHelper';
        customException.Exception_Message__c = message;
        insert customException;
    }
}