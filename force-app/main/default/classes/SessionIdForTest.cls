@RestResource(urlMapping='/GetSessionId')
global with sharing class SessionIdForTest {
    
    @HttpGet
    global static String getSessionId() {
        return UserInfo.getSessionId();
    }
}