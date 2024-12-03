public with sharing class B2BSchooxAPIService {
    private static String API_URL = Label.SX_API_URL;
    private enum ApiType {User, Users, UserDetails, AllCourse, UserCourse, AllJob, AllUnit, Enrollment, AllAboveUnit, Above, Unit, AboveUnit, Course}
    private static String API_KEY = Label.SX_API_Key;
    private static String ACADEMY_ID = Label.SX_Academy_Id;
    public static Boolean apiError = false;
    public static HttpResponse testResponse;

    public static  B2BSchooxAPIWrapper.SchooxUser getSchooxUser(String accountId) {
        // System.debug('B2BSchooxAPIService.getSchooxUser - Start: Retrieving Account by Id');
        Account account = B2BSchooxAPIServiceHelper.getAccountById(accountId);
        B2BSchooxAPIWrapper.SchooxUser schooxUser = new B2BSchooxAPIWrapper.SchooxUser();
        String sxUserId = account.SX_User_Id__pc;
        String url = API_URL + 'users/' + sxUserId;
        // System.debug('B2BSchooxAPIService.getSchooxUser - Making HTTP Request to URL: ' + url);

        Map<String, String> responseMap = makeHTTPRequest(ApiType.UserDetails, url, 'GET', null);
        // System.debug('B2BSchooxAPIService.getSchooxUser - Response Map: ' + responseMap);

        if (responseMap != null && responseMap.containsKey('responseBody')) {
            String responseBody = responseMap.get('responseBody');
            // System.debug('B2BSchooxAPIService.getSchooxUser - Response Body: ' + responseBody);
            return schooxUser = parseSchooxUser(responseBody);
            // System.debug('B2BSchooxAPIService.getSchooxUser - Parsed Schoox User: ' + schooxUser);
        } else {
            // System.debug('B2BSchooxAPIService.getSchooxUser - No response body received or response map is null.');
        }
        // System.debug('B2BSchooxAPIService.getSchooxUser - End of Method');
        return null;
    }

    private static B2BSchooxAPIWrapper.SchooxUser parseSchooxUser(String jsonResponse) {
        System.debug('B2BSchooxAPIService.parseSchooxUser - Start Parsing JSON Response');
        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        B2BSchooxAPIWrapper.SchooxUser user = new B2BSchooxAPIWrapper.SchooxUser();
    
        user.studentId = String.valueOf(responseMap.get('id'));
        user.isActive = Boolean.valueOf(responseMap.get('active'));
        user.jobs = new List<Integer>();
        // System.debug('B2BSchooxAPIService.parseSchooxUser - Mapped studentId: ' + user.studentId + ', isActive: ' + user.isActive);    
       
        if (responseMap.containsKey('units') && responseMap.get('units') instanceof List<Object>) {
            List<Object> units = (List<Object>) responseMap.get('units');
            
            for (Object unitObj : units) {
                if (unitObj instanceof Map<String, Object>) {
                    Map<String, Object> unit = (Map<String, Object>) unitObj;
    
                    if (unit.containsKey('jobs') && unit.get('jobs') instanceof List<Object>) {
                        List<Object> jobsList = (List<Object>) unit.get('jobs');
    
                        for (Object jobObj : jobsList) {
                            if (jobObj instanceof Map<String, Object>) {
                                Map<String, Object> jobMap = (Map<String, Object>) jobObj;
                                Integer jobId = Integer.valueOf(jobMap.get('id'));
                                user.jobs.add(jobId);
                                // System.debug('B2BSchooxAPIService.parseSchooxUser - Added Job ID: ' + jobId);
                            } else {
                                // System.debug('B2BSchooxAPIService.parseSchooxUser - Job object is not a map, skipping.');
                            }
                        }                        
                    } else {
                        // System.debug('B2BSchooxAPIService.parseSchooxUser - No valid jobs array found in unit.');
                    }
                } else {
                    // System.debug('B2BSchooxAPIService.parseSchooxUser - Unit object is not a map, skipping.');
                }
            }
        } else {
            // System.debug('B2BSchooxAPIService.parseSchooxUser - No valid units array found in response.');
        }
    
        // System.debug('B2BSchooxAPIService.parseSchooxUser - End Parsing JSON Response');
        return user;
    }
    

    private static Map<String, String> makeHTTPRequest (ApiType type, String endPoint, String apiMethod, String body) {
        // System.debug('=================================HTTPRequest=================================');
        HttpRequest request = new HttpRequest();
        if (endPoint.contains('?')) {
            request.setEndpoint(endPoint + '&apikey=' + API_KEY + '&acadId=' + ACADEMY_ID);
        } else {
            request.setEndpoint(endPoint + '?apikey=' + API_KEY + '&acadId=' + ACADEMY_ID);
        }
        request.setMethod(apiMethod);
        request.setTimeout(120000);     // Timeout 120 seconds
        // request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(getBearerToken(shopName)));
        request.setHeader('Content-Type', 'application/json');
        if (String.isNotBlank(body)) {
            request.setBody(body);
        }
        // System.debug(apiMethod + ' ' + type);
        // System.debug(request.toString());
        Http http = new Http();
        HttpResponse response;
        if (Test.isRunningTest()) {
            response = testResponse;
        } else {
            response = http.send(request);
        }
        // System.debug(response);
        // System.debug(response.getBody());
        // System.debug('Status: ' + response.getStatus() + ' StatusCode: ' + response.getStatusCode());
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201 || response.getStatusCode() == 204) {
            apiError = false;
        } else {
            apiError = true;
        }
		// System.debug('apiError: ' + apiError);
        return new Map<String, String>{
            'headerLink' => response.getHeader('Link'),
            'responseBody' => response.getBody()
        };
    }
}