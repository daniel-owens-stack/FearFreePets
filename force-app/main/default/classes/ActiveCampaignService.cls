public class ActiveCampaignService {
    public static void sendContact(String email, String firstName, String lastName) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://freefreepetsllc1743198216.api-us1.com/api/3/contacts'); // replace yourcompany
        req.setMethod('POST');
        req.setHeader('Api-Token', '1cf03f707b2036ae6548b97af9fe190be283ac911ad4bd629e95ad832e49b8068ea65b86'); // insert actual API token
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> contact = new Map<String, Object>{
            'contact' => new Map<String, Object>{
                'email' => email,
                'firstName' => firstName,
                'lastName' => lastName
            }
        };

        req.setBody(JSON.serialize(contact));

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Status: ' + res.getStatusCode());
            System.debug('Response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
}