@IsTest
public class SchooxHttpMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        String m = req.getMethod();
        String u = req.getEndpoint().toLowerCase();

        if (m == 'POST' && u.contains('/users')) {
            res.setStatusCode(201);
            res.setBody('{"id":"9999","status":201,"joined_date":"2024-01-01"}');
            return res;
        }
        if (m == 'PUT' && u.contains('/users/')) {
            res.setStatusCode(200);
            res.setBody('{"ok": true}');
            return res;
        }
        if (m == 'GET' && u.contains('/dashboard/users/')) {
            res.setStatusCode(200);
            res.setBody('[]');
            return res;
        }
        res.setStatusCode(200);
        res.setBody('{"ok": true}');
        return res;
    }
}