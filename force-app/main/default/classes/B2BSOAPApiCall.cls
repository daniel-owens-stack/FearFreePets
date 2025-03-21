public class B2BSOAPApiCall {

    public static HttpResponse sendRequestToVeraCore(
        B2BVeraCoreSendReq.Header header, 
        B2BVeraCoreSendReq.OrderedBy orderedBy, 
        List<B2BVeraCoreSendReq.Offers> offers) {

        Boolean isInternationalShipping = orderedBy.countryCode != 'US';

        // Construct the SOAP request body dynamically
        String offersSection = '';
        for (B2BVeraCoreSendReq.Offers offer : offers) {
            String offerId = offer.offerId_SKU;
            
            if(isInternationalShipping && offer.productGroup == 'Certification Kit' 
                && offer.hasInternationalSKU && offer.offerId_SKU_INTL != null) {
                    offerId = offer.offerId_SKU_INTL;
            }
            System.debug('Offer Id:' + offerId);

            offersSection += '<OfferOrdered>' +
                                '<Offer>' +
                                    '<Header><ID>' + offerId + '</ID></Header>' +
                                '</Offer>' +
                                '<Quantity>' + offer.quantity + '</Quantity>' +
                                '<UnitPrice>' + offer.unitPrice + '</UnitPrice>' +
                                '<OrderShipTo><Key>0</Key></OrderShipTo>' +
                             '</OfferOrdered>';
        }

        String soapBody = '<?xml version="1.0" encoding="utf-8"?>' +
                        '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">' +
                            '<soap:Header>' +
                                '<AuthenticationHeader xmlns="http://omscom/">' +
                                '<Username>{!$Credential.Username}</Username>' +
                                '<Password>{!$Credential.Password}</Password>' +
                                '</AuthenticationHeader>' +
                            '</soap:Header>' +
                            '<soap:Body>' +
                                '<AddOrder xmlns="http://omscom/">' +
                                    '<order>' +
                                        '<Header>' + 
                                            '<ID>' + header.veracoreOrderId + '</ID>' + 
                                            '<ReferenceNumber>' + header.orderSummaryNumber + '</ReferenceNumber>' +
                                            '<PONumber>' + header.poNumber + '</PONumber>' +
                                        '</Header>' +
                                        '<OrderedBy>' +
                                            '<FirstName>' + orderedBy.firstName + '</FirstName>' +
                                            '<LastName>' + orderedBy.lastName + '</LastName>' +
                                            '<Address1>' + orderedBy.street + '</Address1>' +
                                            '<City>' + orderedBy.city + '</City>' +
                                            '<State>' + orderedBy.state + '</State>' +
                                            '<PostalCode>' + orderedBy.postalCode + '</PostalCode>' +
                                            '<Country>' + orderedBy.country + '</Country>' +
                                            '<Phone>' + orderedBy.phone + '</Phone>' +
                                            '<Email>' + orderedBy.email + '</Email>' +
                                        '</OrderedBy>' +
                                        '<ShipTo>' +
                                            '<OrderShipTo>' +
                                                '<Flag>OrderedBy</Flag>' +
                                                '<Key>0</Key>' +
                                            '</OrderShipTo>' +
                                        '</ShipTo>' +
                                        '<BillTo>' +
                                            '<Flag>OrderedBy</Flag>' +
                                        '</BillTo>' +
                                        '<Offers>' + offersSection + '</Offers>' +
                                    '</order>' +
                                '</AddOrder>' +
                            '</soap:Body>' +
                        '</soap:Envelope>';

        // Set up the HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:VeraCore');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'text/xml');
        req.setHeader('Encoding', 'utf-8');
        req.setHeader('SOAPAction', 'http://omscom/AddOrder'); 
        req.setBody(soapBody);
        req.setTimeout(20000);

        // Send the request and handle the response
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('B2B Veracore Order Creation Response: ' + res.getStatus() + ' ' + res.getStatusCode() + ' ' + res.getBody());
        if (res.getStatusCode() == 200) {
            return res;
        } else {
            // Log the exception
            Id orderSummaryId = [SELECT Id FROM OrderSummary WHERE Veracore_Order_Id__c = :header.veracoreOrderId].Id;

            ProcessException log = new ProcessException();
            log.Message = 'Error: ' + res.getStatus() + '; Status Code: ' + res.getStatusCode();
            log.Description = res.getBody();
            log.AttachedToId = orderSummaryId;
            log.Category = 'Veracore Order Creation';
            log.OrderSummaryId = orderSummaryId;

            insert log;

            return res;
        }
    }
}