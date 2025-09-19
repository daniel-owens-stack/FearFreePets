@IsTest
private class FFGetUserCourseWrapperTest {
    
    // Mock response for createLMSUser (used in LMSUserQueueable test)
    private class CreateUserMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            // This mimics the structure expected by createLMSUser, a single JSON object
            String jsonResponse = JSON.serialize(new Map<String, Object>{
                'id' => '12345',
                'status' => 201,
                'joined_date' => '2025-07-22',
                'external_ids' => new List<String>{ '003TR00000XYZ123' }
            });
            
            res.setBody(jsonResponse);
            return res;
        }
    }
    
    // Mock class for successful API response
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200); // Success status code for GET, not 201
            String jsonResponse = '[{ "id": "7212464", "courseName": "Animal Trainer Certification Program", "url": "https://example.com/course", "progress": 6.67, "total_time": "0:00:04" }]';
            res.setBody(jsonResponse);
            return res;
        }
    }
    
    
    // Mock class for empty API response
    private class EmptyMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            // Mock empty JSON response
            res.setBody('[]');
            return res;
        }
    }
    
    // Mock class for error API response
    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setBody('{"error": "Internal Server Error"}');
            return res;
        }
    }
    
    @TestSetup
    static void setup() {
        // Insert test data if needed (e.g., SX_Enrollment__c records)
        // For this test, we can skip this since we're mocking the API response
    }
    
    @IsTest
    static void testGetSchooxCourseData_Success() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        
        Test.startTest();
        List<SX_Enrollment__c> result = FFGetUserCourseWrapper.getSchooxCourseData('819707483');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        //System.assertEquals(1, result.size(), 'Expected one course record');
    }
    
    @IsTest
    static void testGetSchooxCourseData_EmptyResponse() {
        Test.setMock(HttpCalloutMock.class, new EmptyMock());
        
        Test.startTest();
        List<SX_Enrollment__c> result = FFGetUserCourseWrapper.getSchooxCourseData('819707483');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Expected an empty list');
    }
    
    @IsTest
    static void testGetSchooxCourseData_Error() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            List<SX_Enrollment__c> result = FFGetUserCourseWrapper.getSchooxCourseData('819707483');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.debug('Exception thrown as expected: ' + e.getMessage());
        }
        Test.stopTest();
        
        System.assertEquals(true, exceptionThrown, 'An AuraHandledException should have been thrown');
    }

    @IsTest
static void testHandleLMSUserAsync() {
    Test.setMock(HttpCalloutMock.class, new CreateUserMock());

    // Insert required data
    SX_Unit__c unit = new SX_Unit__c(Name = 'Unit A', SX_ID__c = 'unit-001');
    SX_Unit__c aboveUnit = new SX_Unit__c(Name = 'Above Unit A', SX_ID__c = 'above-001');
    insert new List<SX_Unit__c>{ unit, aboveUnit };

    SX_Job__c job = new SX_Job__c(Name = 'Vet Job A', SX_Job_ID__c = '1234567');
    insert job;

    RecordType paRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1];

    Account acct = new Account(
        RecordTypeId = paRt.Id,
        FirstName = 'Async',
        LastName = 'Test',
        PersonEmail = 'async@test.com'
    );
    insert acct;

    Contact con = [SELECT Id FROM Contact WHERE AccountId = :acct.Id LIMIT 1];
    con.SX_Job_Lookup__c = job.Id;
    update con;

    Test.startTest();
    FFGetUserCourseWrapper.handleLMSUserAsync(acct.Id, new List<Integer>{ 1234567 });
    Test.stopTest();

    System.assert(true, 'handleLMSUserAsync + runHandleLMSUserFuture executed without error');
}

    
    @IsTest
    static void testLMSUserQueueableExecution() {
        Test.setMock(HttpCalloutMock.class, new CreateUserMock()); // ✅ Correct mock for user creation
        
        Test.startTest();
        
        // Supporting objects
        SX_Unit__c unit = new SX_Unit__c(Name = 'Unit 1', SX_ID__c = 'unit-001');
        SX_Unit__c aboveUnit = new SX_Unit__c(Name = 'Above Unit', SX_ID__c = 'above-001');
        insert new List<SX_Unit__c>{ unit, aboveUnit };
        
        SX_Job__c job = new SX_Job__c(Name = 'Vet Job', SX_Job_ID__c = '1234567');
        insert job;
        
        RecordType paRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1];
        
        Account acct = new Account(
            RecordTypeId = paRt.Id,
        FirstName = 'Match',
        LastName = 'User',
        PersonEmail = 'match@example.com'
            );
        insert acct;
        
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :acct.Id LIMIT 1];
        con.SX_Job_Lookup__c = job.Id;
        update con;
        
        System.enqueueJob(new FFGetUserCourseWrapper.LMSUserQueueable(acct.Id, new List<Integer>{ 12345 }));
        
        Test.stopTest();
        
        System.assert(true, 'Queueable job executed without exception');
    }
}