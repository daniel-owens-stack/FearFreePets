public class B2BSchooxAPIService {
    private static String API_URL = Label.SX_API_URL;
    private enum ApiType {User, Users, UserDetails, AllCourse, UserCourse, AllJob, AllUnit, Enrollment, AllAboveUnit, Above, Unit, AboveUnit, Course}
    private static String API_KEY = Label.SX_API_Key;
    private static String ACADEMY_ID = Label.SX_Academy_Id;
    public static Boolean apiError = false;
    public static HttpResponse testResponse;

    public static  B2BSchooxAPIWrapper.SchooxUser getSchooxUser(String accountId) {

        Account account = B2BSchooxAPIServiceHelper.getAccountById(accountId);
        B2BSchooxAPIWrapper.SchooxUser schooxUser = new B2BSchooxAPIWrapper.SchooxUser();
        String sxUserId = account.SX_User_Id__pc;
        String url = API_URL + 'users/' + sxUserId;

        Map<String, String> responseMap = makeHTTPRequest(ApiType.UserDetails, url, 'GET', null);

        if (responseMap != null && responseMap.containsKey('responseBody')) {
            String responseBody = responseMap.get('responseBody');
            return schooxUser = parseSchooxUser(responseBody);
        } 
        return null;
    }

    private static B2BSchooxAPIWrapper.SchooxUser parseSchooxUser(String jsonResponse) {
        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        B2BSchooxAPIWrapper.SchooxUser user = new B2BSchooxAPIWrapper.SchooxUser();
    
        user.studentId = String.valueOf(responseMap.get('id'));
        user.isActive = Boolean.valueOf(responseMap.get('active'));
        user.jobs = new List<Integer>();
       
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
                            } 
                        }                        
                    } 
                } 
            }
        } 
        return user;
    }
    

    private static Map<String, String> makeHTTPRequest (ApiType type, String endPoint, String apiMethod, String body) {
        HttpRequest request = new HttpRequest();

        if (endPoint.contains('?')) {
            request.setEndpoint(endPoint + '&apikey=' + API_KEY + '&acadId=' + ACADEMY_ID);
        } else {
            request.setEndpoint(endPoint + '?apikey=' + API_KEY + '&acadId=' + ACADEMY_ID);
        }

        request.setMethod(apiMethod);
        request.setTimeout(120000); 
        request.setHeader('Content-Type', 'application/json');

        if (String.isNotBlank(body)) {
            request.setBody(body);
        }

        Http http = new Http();
        HttpResponse response;
        if (Test.isRunningTest()) {
            response = testResponse;
        } else {
            response = http.send(request);
        }

        if (response.getStatusCode() == 200 || response.getStatusCode() == 201 || response.getStatusCode() == 204) {
            apiError = false;
        } else {
            apiError = true;
        }
		
        return new Map<String, String>{
            'headerLink' => response.getHeader('Link'),
            'responseBody' => response.getBody()
        };
    }
}