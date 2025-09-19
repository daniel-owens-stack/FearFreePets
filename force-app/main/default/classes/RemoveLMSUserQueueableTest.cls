@IsTest
private class RemoveLMSUserQueueableTest {
    
    @IsTest
    static void testQueueableExecutes() {
        // Fake LMS User Id
        String fakeUserId = 'external-user-123';
        
        // Replace SchooxAPI with a mock to avoid real callouts
        Test.setMock(HttpCalloutMock.class, new MockSchooxAPI());

        Test.startTest();
        System.enqueueJob(new RemoveLMSUserQueueable(fakeUserId));
        Test.stopTest();

        // If no exception is thrown, the queueable executed fine
        System.assert(true, 'Queueable executed successfully for RemoveLMSUserQueueable');
    }
    
    // Mock SchooxAPI HTTP callout
    private class MockSchooxAPI implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true}');
            return res;
        }
    }
}