@isTest
public class B2BHandleInvoiceLineStripeEventsTest {
    
    @isTest static void testDeserializeInvoiceLine() {

        List<String> requestBodies = new List<String>();
        String requestBody = '{"type":"invoiceitem.created","request":{"idempotency_key":"756930ac-e97c-4855-94b3-7367945b8f71","id":"req_QDVEuGFfSyvz0K"},"pending_webhooks":1,"livemode":false,"data":{"object":{"unit_amount_decimal":"2250","unit_amount":2250,"test_clock":null,"tax_rates":[],"subscription":null,"quantity":1,"proration":false,"price":{"unit_amount_decimal":"2250","unit_amount":2250,"type":"one_time","transform_quantity":null,"tiers_mode":null,"tax_behavior":"unspecified","recurring":null,"product":"prod_PpExWoDadqVClm","nickname":"Sony headphones","metadata":{},"lookup_key":null,"livemode":false,"custom_unit_amount":null,"currency":"usd","created":1711699668,"billing_scheme":"per_unit","active":true,"object":"price","id":"price_1OzaTYFkggLOPOs8lBa12SUA"},"plan":null,"period":{"start":1724953508,"end":1724953508},"metadata":{},"livemode":false,"invoice":"in_1PtCP1FkggLOPOs8urwBPiPW","discounts":[],"discountable":true,"description":"Sony WH-1000XM5 (per 1)","date":1724953508,"customer":"cus_Q2NwxM4cWSm8ra","currency":"usd","amount":2250,"object":"invoiceitem","id":"ii_1PtCPAFkggLOPOs8gvNdWUJh"}},"created":1724953508,"api_version":"2022-11-15","object":"event","id":"evt_1PtCPAFkggLOPOs8cDV6BUYT"}';
        requestBodies.add(requestBody);

        List<B2BHandleInvoiceLineStripeEvents.Results> result;
        Test.StartTest();
        result = B2BHandleInvoiceLineStripeEvents.deserializeInvoiceLine(requestBodies);
        Test.StopTest();
    }
}