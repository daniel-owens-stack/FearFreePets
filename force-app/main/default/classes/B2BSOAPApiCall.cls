public class B2BSOAPApiCall {

    public static HttpResponse makeSOAPCall(String endpoint, String prefix, String firstName, String middleInitial, String lastName, String suffix, String title, String address1, String address2, String address3, String city, String state, String postalCode, String country, String phone, String fax, String email, String veraCore_OrderId, Decimal quantity, Decimal unitPrice) {
        // Construct the SOAP request body dynamically
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
                          '<Header><ID>' + veraCore_OrderId + '</ID></Header>' +
                          '<Money></Money>' +
                          '<Payment></Payment>' +
                          '<OrderedBy>' +
                          '<Prefix>' + prefix + '</Prefix>' +
                          '<FirstName>' + firstName + '</FirstName>' +
                          '<MiddleInitial>' + middleInitial + '</MiddleInitial>' +
                          '<LastName>' + lastName + '</LastName>' +
                          '<Suffix>' + suffix + '</Suffix>' +
                          '<Title>' + title + '</Title>' +
                          '<Address1>' + address1 + '</Address1>' +
                          '<Address2>' + address2 + '</Address2>' +
                          '<Address3>' + address3 + '</Address3>' +
                          '<City>' + city + '</City>' +
                          '<State>' + state + '</State>' +
                          '<PostalCode>' + postalCode + '</PostalCode>' +
                          '<Country>' + country + '</Country>' +
                          '<Phone>' + phone + '</Phone>' +
                          '<Fax>' + fax + '</Fax>' +
                          '<Email>' + email + '</Email>' +
                          '</OrderedBy>' +
                          '<ShipTo>' +
                          '<OrderShipTo>' +
                          '<Flag>OrderedBy</Flag>' +
                          '<Key>1</Key>' +
                          '</OrderShipTo>' +
                          '</ShipTo>' +
                          '<BillTo>' +
                          '<Flag>OrderedBy</Flag>' +
                          '</BillTo>' +
                          '<Offers>' +
                          '<OfferOrdered>' +
                          '<Offer>' +
                          '<Header><ID>GW</ID></Header>' +
                          '</Offer>' +
                          '<Quantity>' + quantity + '</Quantity>' +
                          '<UnitPrice>' + unitPrice + '</UnitPrice>' +
                          '<OrderShipTo><Key>1</Key></OrderShipTo>' +
                          '</OfferOrdered>' +
                          '</Offers>' +
                          '</order>' +
                          '</AddOrder>' +
                          '</soap:Body>' +
                          '</soap:Envelope>';

        // Set up the HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'text/xml; charset=UTF-8');
        req.setHeader('SOAPAction', 'http://omscom/AddOrder'); 
        req.setBody(soapBody);
        req.setTimeout(20000);

        // Send the request and handle the response
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            System.debug('##B2BSOAPApiCall - Response: ' + res.getBody());
            return res;
        } else {
            System.debug('##B2BSOAPApiCall - Error: ' + res.getStatus() + ' ' + res.getStatusCode() + ' ' + res.getBody());
            // Log the exception
            Id orderId = [SELECT Id FROM Order ORDER BY CreatedDate Desc LIMIT 1].Id;
            ProcessException log = new ProcessException();
            log.Message = 'Error: ' + res.getStatus() + ', Status Code: ' + res.getStatusCode();
            log.Description = res.getBody();
            log.AttachedToId = orderId;
            insert log;

            return res;
        }
    }
}