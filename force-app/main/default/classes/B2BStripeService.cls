public with sharing class B2BStripeService {
    private static final String POST_METHOD = 'POST';
    private static final String GET_METHOD = 'GET';
    private static final String DELETE_METHOD = 'DELETE';
    private static final Integer NET_60_INVOICE_DUE_DATE = 60;
    private static final Integer NET_30_INVOICE_DUE_DATE = 30;
    private static final Integer CREDIT_CARD_ONLY_DUE_DATE = 0;

    public class B2BStripeException extends Exception {
    }

    public static B2BStripeWrapper.StripeCustomer createStripeCustomer(String accountId, String billingEmail) {
        Account account = B2BStripeServiceHelper.getAccountById(accountId);
        HttpResponse response = new HttpResponse();
        String endPoint = 'v1/customers';
        String requestBody = 'email=' + billingEmail + '&name=' + account.Name;
        response = makeCalloutToStripe(endPoint, POST_METHOD, requestBody, 'application/x-www-form-urlencoded');

        B2BStripeWrapper.StripeCustomer result = (B2BStripeWrapper.StripeCustomer) JSON.deserialize(response.getBody(), B2BStripeWrapper.StripeCustomer.class);

        if (response.getStatusCode() != 200 && String.isNotBlank(result.error.message)) {
            throw new B2BStripeException(result.error.type + ': ' + result.error.message);
        } else {
            return result;
        }
    }

    public static B2BStripeWrapper.StripeCustomer getStripeCustomerByEmail(String billingEmail) {
        
        String endPoint = 'v1/customers/search';
        String requestBody = 'query=email:' + '"' + billingEmail + '"';

        HttpResponse response = new HttpResponse();
        response = makeCalloutToStripe(endPoint, GET_METHOD, requestBody, 'application/x-www-form-urlencoded');

        B2BStripeWrapper.StripeCustomers stripeCustomers = (B2BStripeWrapper.StripeCustomers) JSON.deserialize(response.getBody(), B2BStripeWrapper.StripeCustomers.class);
        B2BStripeWrapper.StripeCustomer stripeCustomer = new B2BStripeWrapper.StripeCustomer();
        if (stripeCustomers.data != null && !stripeCustomers.data.isEmpty()) {
            stripeCustomer = stripeCustomers.data[0];
        }

        if (response.getStatusCode() != 200 && String.isNotBlank(stripeCustomers.error.message)) {
            throw new B2BStripeException(stripeCustomers.error.type + ': ' + stripeCustomers.error.message);
        } else {
            return stripeCustomer;
        }
    }

    public static B2BStripeWrapper.CheckoutSession getCheckoutSession(String checkoutSessionId) {
        HttpResponse response = new HttpResponse();
        String endPoint = 'v1/checkout/sessions/' + checkoutSessionId;
        response = makeCalloutToStripe(endPoint, GET_METHOD, '', 'application/x-www-form-urlencoded');

        B2BStripeWrapper.CheckoutSession result = (B2BStripeWrapper.CheckoutSession) JSON.deserialize(response.getBody(), B2BStripeWrapper.CheckoutSession.class);

        if (response.getStatusCode() != 200 && String.isNotBlank(result.error.message)) {
            throw new B2BStripeException(result.error.type + ': ' + result.error.message);
        } else {
            return result;
        }
    }

    public static B2BStripeWrapper.CheckoutSession createCheckoutSession(String customerId, String webCartId, String href) {
        System.debug('CREATE CHECKOUT SESSION');

        String endPoint = 'v1/checkout/sessions';
        HttpResponse response = new HttpResponse();
        String requestString = B2BStripeServiceHelper.createCheckoutRequestString(customerId, webCartId, href);

        response = makeCalloutToStripe(endPoint, POST_METHOD, requestString, 'application/x-www-form-urlencoded');

        B2BStripeWrapper.CheckoutSession result = (B2BStripeWrapper.CheckoutSession) JSON.deserialize(response.getBody(), B2BStripeWrapper.CheckoutSession.class);
        System.debug('CREATE CHECKOUT SESSION RESULT === '  +result);
        if (response.getStatusCode() != 200 && String.isNotBlank(result.error.message)) {
            throw new B2BStripeException(result.error.type + ': ' + result.error.message);
        } else {
            return result;
        }

    }

    public static B2BStripeWrapper.InvoiceLineItem createInvoiceLineItem(String invoiceId, String customerId, CartItem cartItem) {
        String endPoint = 'v1/invoiceitems';
        HttpResponse response = new HttpResponse();
        String requestString = B2BStripeServiceHelper.createInvoiceLineItemsString(invoiceId, customerId, cartItem);

        response = makeCalloutToStripe(endPoint, POST_METHOD, requestString, 'application/x-www-form-urlencoded');
        B2BStripeWrapper.InvoiceLineItem result = (B2BStripeWrapper.InvoiceLineItem) JSON.deserialize(response.getBody(), B2BStripeWrapper.InvoiceLineItem.class);

        if (response.getStatusCode() != 200 && String.isNotBlank(result.error.message)) {
            throw new B2BStripeException(result.error.type + ': ' + result.error.message);
        } else {
            return result;
        }
    }

    public static B2BStripeWrapper.InvoiceLineItem createTaxInvoiceLineItem(String invoiceId, String customerId, String cartId) {
        String endPoint = 'v1/invoiceitems';
        HttpResponse response = new HttpResponse();
        String requestString = B2BStripeServiceHelper.createTaxInvoiceLineItemsString(invoiceId, customerId, cartId);

        response = makeCalloutToStripe(endPoint, POST_METHOD, requestString, 'application/x-www-form-urlencoded');
        B2BStripeWrapper.InvoiceLineItem result = (B2BStripeWrapper.InvoiceLineItem) JSON.deserialize(response.getBody(), B2BStripeWrapper.InvoiceLineItem.class);

        if (response.getStatusCode() != 200 && String.isNotBlank(result.error.message)) {
            throw new B2BStripeException(result.error.type + ': ' + result.error.message);
        } else {
            return result;
        }
    }

    public static B2BStripeWrapper.Invoice createInvoice(String customerId, Integer daysUntilDue, String orderId) {
        if (orderId == null) {
            orderId ='';
        }
        
        String endPoint = 'v1/invoices';
        HttpResponse response = new HttpResponse();
        String requestString = 'customer=' + customerId +
        '&collection_method=send_invoice' +
        '&days_until_due=' + daysUntilDue +
        '&metadata[salesforce_order_id]=' + EncodingUtil.urlEncode(orderId, 'UTF-8');
        response = makeCalloutToStripe(endPoint, POST_METHOD, requestString, 'application/x-www-form-urlencoded');
        B2BStripeWrapper.Invoice result = (B2BStripeWrapper.Invoice) JSON.deserialize(response.getBody(), B2BStripeWrapper.Invoice.class);

        if (response.getStatusCode() != 200 && String.isNotBlank(result.error.message)) {
            throw new B2BStripeException(result.error.type + ': ' + result.error.message);
        } else {
            return result;
        }
    }

    public static HttpResponse makeCalloutToStripe(String endPoint, String requestMethod, String requestBody, String contentType) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:StripeCredential/' + endPoint);
        req.setMethod(requestMethod);
        req.setHeader('Content-Type', contentType);
        req.setBody(requestBody);

        return http.send(req);
    }

    public static B2BStripeWrapper.PaymentIntent createPaymentIntent(String customerId, String paymentMethod, Integer amount) {
        if(paymentMethod.startsWith('pi_')) {
            B2BStripeWrapper.PaymentIntent intent = retrievePaymentIntent(paymentMethod);
            paymentMethod = intent.payment_method;
        }

        String endPoint = 'v1/payment_intents';
        String requestBody = 'amount=' + String.valueOf(amount) + '&currency=usd&customer=' + customerId + '&payment_method=' + paymentMethod + '&off_session=true&confirm=true';
        System.debug('requestBody ==  ' + requestBody);

        HttpResponse response = makeCalloutToStripe(endPoint, POST_METHOD, requestBody, 'application/x-www-form-urlencoded');
        
        System.debug(response.getBody());
        B2BStripeWrapper.PaymentIntent result = (B2BStripeWrapper.PaymentIntent) JSON.deserialize(response.getBody(), B2BStripeWrapper.PaymentIntent.class);
        if (response.getStatusCode() != 200 && String.isNotBlank(result.error.message)) {
            throw new B2BStripeException(result.error.type + ': ' + result.error.message);
        } else {
            return result;
        }
    }

    public static B2BStripeWrapper.PaymentIntent retrievePaymentIntent(String paymentIntentId) {
        //pi_3PHKELDuoNhH1Sre2OxY3Au2
        String endPoint = 'v1/payment_intents/' + paymentIntentId;
        String requestBody = '';
        HttpResponse response = makeCalloutToStripe(endPoint, POST_METHOD, requestBody, 'application/x-www-form-urlencoded');
        
        B2BStripeWrapper.PaymentIntent result = (B2BStripeWrapper.PaymentIntent) JSON.deserialize(response.getBody(), B2BStripeWrapper.PaymentIntent.class);
        if (response.getStatusCode() != 200 && String.isNotBlank(result.error.message)) {
            throw new B2BStripeException(result.error.type + ': ' + result.error.message);
        } else {
            return result;
        }
    }

    public static Integer getInvoiceDueDate(String customerId, String accountId) {
        Integer daysUntilDue = 0;
        
        Account account = B2BStripeServiceHelper.getAccountByStripeId(customerId, accountId);
        switch on account.Payment_Terms__c {
            when 'Net 60' {
                daysUntilDue += NET_60_INVOICE_DUE_DATE;
            }
            when 'Net 30' {
                daysUntilDue += NET_30_INVOICE_DUE_DATE;
            }
            when else {
                daysUntilDue += CREDIT_CARD_ONLY_DUE_DATE;
            }
        }
        
        return daysUntilDue;
    }
}