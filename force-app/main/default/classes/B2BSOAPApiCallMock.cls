@isTest
public class B2BSOAPApiCallMock implements HttpCalloutMock {
    public static HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"id": "12345"}');
        res.setStatusCode(400);
        return res;
    }
}