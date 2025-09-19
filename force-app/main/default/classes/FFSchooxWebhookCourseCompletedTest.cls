@IsTest
private class FFSchooxWebhookCourseCompletedTest {
    private static String WEBHOOK_SECRET = Label.SX_WEBHOOK_SECRET;

    @TestSetup
    static void setup() {
        // Create test data
        SX_Courses__c course = new SX_Courses__c(
            SX_Course_ID__c = '101'
        );
        insert course;

        SX_LMS_User__c lmsUser = new SX_LMS_User__c(
            SX_User_ID__c = '1'
        );
        insert lmsUser;

        Contact contact = new Contact(
            LastName = 'Test',
            SX_User_Id__c = '1'
        );
        insert contact;

        // Existing enrollment for update test
        SX_Enrollment__c enroll = new SX_Enrollment__c(
            Student_Course_Id__c = '1#101',
            Student_ID__c = lmsUser.Id,
            SX_Course__c = course.Id,
            SX_Enrollment_Date__c = Date.newInstance(2025, 4, 1)
        );
        insert enroll;
    }

    @IsTest
    static void testValidWebhookNewEnrollment() {
        // Prepare JSON payload
        String jsonPayload = '{"payload":{"course":{"id":101,"title":"Introduction to Apex","description":"Learn Apex","image":"https://example.com/image.jpg","status":"ACTIVE","visibilityStatus":"PUBLIC"},"user":{"id":1,"firstName":"John","lastName":"Doe","email":"john.doe@example.com"},"courseProgress":{"progress":75,"completionDate":"2025-04-14T10:30:00Z","certificationVerificationCode":"CERT123"}}}';

        // Calculate HMAC
        String whId = 'test-wh-id';
        String whTimestamp = String.valueOf(DateTime.now().getTime() / 1000);
        String signable = whId + '.' + whTimestamp + '.' + jsonPayload;
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(signable), Blob.valueOf(WEBHOOK_SECRET));
        String whSignature = EncodingUtil.base64Encode(mac);

        // Set up request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.addHeader('wh-id', whId);
        req.addHeader('wh-timestamp', whTimestamp);
        req.addHeader('wh-signature', whSignature);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Delete existing enrollment to test new enrollment
        delete [SELECT Id FROM SX_Enrollment__c WHERE Student_Course_Id__c = '1#101'];

        // Run test
        Test.startTest();
        FFSchooxWebhookCourseCompleted.handleWebhook();
        Test.stopTest();

        // Verify response
        System.assertEquals(200, RestContext.response.statusCode, 'Expected 200 OK');
        FFSchooxWebhookCourseCompleted.ResponseWrapper response = 
            (FFSchooxWebhookCourseCompleted.ResponseWrapper) JSON.deserialize(
                RestContext.response.responseBody.toString(), 
                FFSchooxWebhookCourseCompleted.ResponseWrapper.class
            );
        System.assertEquals('SUCCESS', response.status, 'Expected SUCCESS status');
        System.assertEquals('Enrollment updated successfully', response.message, 'Expected success message');
        System.assertEquals(0, response.errors.size(), 'Expected no errors');

        // Verify enrollment
        SX_Enrollment__c enroll = [
            SELECT SX_percent_Completed__c, SX_Enrollment_Date__c, SX_Completed_Date__c, SF_Contact_Lookup__c
            FROM SX_Enrollment__c
            WHERE Student_Course_Id__c = '1#101'
            LIMIT 1
        ];
        System.assertEquals(75, enroll.SX_percent_Completed__c, 'Expected progress 75');
        System.assertEquals(Date.today(), enroll.SX_Enrollment_Date__c, 'Expected today\'s date');
        System.assertEquals(Date.newInstance(2025, 4, 14), enroll.SX_Completed_Date__c, 'Expected completion date');
        System.assertNotEquals(null, enroll.SF_Contact_Lookup__c, 'Expected contact lookup set');
    }

    @IsTest
    static void testValidWebhookExistingEnrollment() {
        // Prepare JSON payload
        String jsonPayload = '{"payload":{"course":{"id":101,"title":"Introduction to Apex","description":"Learn Apex","image":"https://example.com/image.jpg","status":"ACTIVE","visibilityStatus":"PUBLIC"},"user":{"id":1,"firstName":"John","lastName":"Doe","email":"john.doe@example.com"},"courseProgress":{"progress":90,"completionDate":"2025-04-15T10:30:00Z","certificationVerificationCode":"CERT456"}}}';

        // Calculate HMAC
        String whId = 'test-wh-id';
        String whTimestamp = String.valueOf(DateTime.now().getTime() / 1000);
        String signable = whId + '.' + whTimestamp + '.' + jsonPayload;
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(signable), Blob.valueOf(WEBHOOK_SECRET));
        String whSignature = EncodingUtil.base64Encode(mac);

        // Set up request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.addHeader('wh-id', whId);
        req.addHeader('wh-timestamp', whTimestamp);
        req.addHeader('wh-signature', whSignature);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Run test
        Test.startTest();
        FFSchooxWebhookCourseCompleted.handleWebhook();
        Test.stopTest();

        // Verify response
        System.assertEquals(200, RestContext.response.statusCode, 'Expected 200 OK');
        FFSchooxWebhookCourseCompleted.ResponseWrapper response = 
            (FFSchooxWebhookCourseCompleted.ResponseWrapper) JSON.deserialize(
                RestContext.response.responseBody.toString(), 
                FFSchooxWebhookCourseCompleted.ResponseWrapper.class
            );
        System.assertEquals('SUCCESS', response.status, 'Expected SUCCESS status');
        System.assertEquals('Enrollment updated successfully', response.message, 'Expected success message');
        System.assertEquals(0, response.errors.size(), 'Expected no errors');

        // Verify enrollment
        SX_Enrollment__c enroll = [
            SELECT SX_percent_Completed__c, SX_Enrollment_Date__c, SX_Completed_Date__c
            FROM SX_Enrollment__c
            WHERE Student_Course_Id__c = '1#101'
            LIMIT 1
        ];
        System.assertEquals(90, enroll.SX_percent_Completed__c, 'Expected progress 90');
        System.assertEquals(Date.newInstance(2025, 4, 1), enroll.SX_Enrollment_Date__c, 'Expected original enrollment date');
        System.assertEquals(Date.newInstance(2025, 4, 15), enroll.SX_Completed_Date__c, 'Expected new completion date');
    }

    @IsTest
    static void testValidWebhookNoContact() {
        // Delete contact to test no SF_Contact_Lookup__c
        delete [SELECT Id FROM Contact WHERE SX_User_Id__c = '1'];

        // Prepare JSON payload
        String jsonPayload = '{"payload":{"course":{"id":101,"title":"Introduction to Apex","description":"Learn Apex","image":"https://example.com/image.jpg","status":"ACTIVE","visibilityStatus":"PUBLIC"},"user":{"id":1,"firstName":"John","lastName":"Doe","email":"john.doe@example.com"},"courseProgress":{"progress":75,"completionDate":"2025-04-14T10:30:00Z","certificationVerificationCode":"CERT123"}}}';

        // Calculate HMAC
        String whId = 'test-wh-id';
        String whTimestamp = String.valueOf(DateTime.now().getTime() / 1000);
        String signable = whId + '.' + whTimestamp + '.' + jsonPayload;
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(signable), Blob.valueOf(WEBHOOK_SECRET));
        String whSignature = EncodingUtil.base64Encode(mac);

        // Set up request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.addHeader('wh-id', whId);
        req.addHeader('wh-timestamp', whTimestamp);
        req.addHeader('wh-signature', whSignature);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Delete existing enrollment
        delete [SELECT Id FROM SX_Enrollment__c WHERE Student_Course_Id__c = '1#101'];

        // Run test
        Test.startTest();
        FFSchooxWebhookCourseCompleted.handleWebhook();
        Test.stopTest();

        // Verify response
        System.assertEquals(200, RestContext.response.statusCode, 'Expected 200 OK');
        FFSchooxWebhookCourseCompleted.ResponseWrapper response = 
            (FFSchooxWebhookCourseCompleted.ResponseWrapper) JSON.deserialize(
                RestContext.response.responseBody.toString(), 
                FFSchooxWebhookCourseCompleted.ResponseWrapper.class
            );
        System.assertEquals('SUCCESS', response.status, 'Expected SUCCESS status');

        // Verify enrollment
        SX_Enrollment__c enroll = [
            SELECT SX_percent_Completed__c, SF_Contact_Lookup__c
            FROM SX_Enrollment__c
            WHERE Student_Course_Id__c = '1#101'
            LIMIT 1
        ];
        System.assertEquals(75, enroll.SX_percent_Completed__c, 'Expected progress 75');
        System.assertEquals(null, enroll.SF_Contact_Lookup__c, 'Expected no contact lookup');
    }

    @IsTest
    static void testMissingHeaders() {
        // Prepare JSON payload
        String jsonPayload = '{"payload":{"course":{"id":101,"title":"Introduction to Apex","description":"Learn Apex","image":"https://example.com/image.jpg","status":"ACTIVE","visibilityStatus":"PUBLIC"},"user":{"id":1,"firstName":"John","lastName":"Doe","email":"john.doe@example.com"},"courseProgress":{"progress":75,"completionDate":"2025-04-14T10:30:00Z","certificationVerificationCode":"CERT123"}}}';

        // Set up request without headers
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Run test
        Test.startTest();
        FFSchooxWebhookCourseCompleted.handleWebhook();
        Test.stopTest();

        // Verify response
        System.assertEquals(400, RestContext.response.statusCode, 'Expected 400 Bad Request');
        FFSchooxWebhookCourseCompleted.ResponseWrapper response = 
            (FFSchooxWebhookCourseCompleted.ResponseWrapper) JSON.deserialize(
                RestContext.response.responseBody.toString(), 
                FFSchooxWebhookCourseCompleted.ResponseWrapper.class
            );
        System.assertEquals('ERROR', response.status, 'Expected ERROR status');
        System.assertEquals('Missing webhook headers', response.message, 'Expected missing headers message');
    }

    @IsTest
    static void testInvalidTimestamp() {
        // Prepare JSON payload
        String jsonPayload = '{"payload":{"course":{"id":101,"title":"Introduction to Apex","description":"Learn Apex","image":"https://example.com/image.jpg","status":"ACTIVE","visibilityStatus":"PUBLIC"},"user":{"id":1,"firstName":"John","lastName":"Doe","email":"john.doe@example.com"},"courseProgress":{"progress":75,"completionDate":"2025-04-14T10:30:00Z","certificationVerificationCode":"CERT123"}}}';

        // Calculate HMAC with old timestamp
        String whId = 'test-wh-id';
        String whTimestamp = String.valueOf((DateTime.now().getTime() / 1000) - 600);
        String signable = whId + '.' + whTimestamp + '.' + jsonPayload;
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(signable), Blob.valueOf(WEBHOOK_SECRET));
        String whSignature = EncodingUtil.base64Encode(mac);

        // Set up request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.addHeader('wh-id', whId);
        req.addHeader('wh-timestamp', whTimestamp);
        req.addHeader('wh-signature', whSignature);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Run test
        Test.startTest();
        FFSchooxWebhookCourseCompleted.handleWebhook();
        Test.stopTest();

        // Verify response
        System.assertEquals(400, RestContext.response.statusCode, 'Expected 400 Bad Request');
        FFSchooxWebhookCourseCompleted.ResponseWrapper response = 
            (FFSchooxWebhookCourseCompleted.ResponseWrapper) JSON.deserialize(
                RestContext.response.responseBody.toString(), 
                FFSchooxWebhookCourseCompleted.ResponseWrapper.class
            );
        System.assertEquals('ERROR', response.status, 'Expected ERROR status');
        System.assertEquals('Webhook timestamp outside allowed tolerance', response.message, 'Expected timestamp error');
    }

    @IsTest
    static void testSignatureMismatch() {
        // Prepare JSON payload
        String jsonPayload = '{"payload":{"course":{"id":101,"title":"Introduction to Apex","description":"Learn Apex","image":"https://example.com/image.jpg","status":"ACTIVE","visibilityStatus":"PUBLIC"},"user":{"id":1,"firstName":"John","lastName":"Doe","email":"john.doe@example.com"},"courseProgress":{"progress":75,"completionDate":"2025-04-14T10:30:00Z","certificationVerificationCode":"CERT123"}}}';

        // Set up request with wrong signature
        String whId = 'test-wh-id';
        String whTimestamp = String.valueOf(DateTime.now().getTime() / 1000);
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.addHeader('wh-id', whId);
        req.addHeader('wh-timestamp', whTimestamp);
        req.addHeader('wh-signature', 'invalid-signature');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Run test
        Test.startTest();
        FFSchooxWebhookCourseCompleted.handleWebhook();
        Test.stopTest();

        // Verify response
        System.assertEquals(401, RestContext.response.statusCode, 'Expected 401 Unauthorized');
        FFSchooxWebhookCourseCompleted.ResponseWrapper response = 
            (FFSchooxWebhookCourseCompleted.ResponseWrapper) JSON.deserialize(
                RestContext.response.responseBody.toString(), 
                FFSchooxWebhookCourseCompleted.ResponseWrapper.class
            );
        System.assertEquals('ERROR', response.status, 'Expected ERROR status');
        System.assertEquals('Signature mismatch. Webhook not verified.', response.message, 'Expected signature error');
    }

    @IsTest
    static void testEmptyPayload() {
        // Set up request with empty body
        String whId = 'test-wh-id';
        String whTimestamp = String.valueOf(DateTime.now().getTime() / 1000);
        String jsonPayload = '';
        String signable = whId + '.' + whTimestamp + '.' + jsonPayload;
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(signable), Blob.valueOf(WEBHOOK_SECRET));
        String whSignature = EncodingUtil.base64Encode(mac);

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.addHeader('wh-id', whId);
        req.addHeader('wh-timestamp', whTimestamp);
        req.addHeader('wh-signature', whSignature);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Run test
        Test.startTest();
        FFSchooxWebhookCourseCompleted.handleWebhook();
        Test.stopTest();

        // Verify response
        System.assertEquals(400, RestContext.response.statusCode, 'Expected 400 Bad Request');
        FFSchooxWebhookCourseCompleted.ResponseWrapper response = 
            (FFSchooxWebhookCourseCompleted.ResponseWrapper) JSON.deserialize(
                RestContext.response.responseBody.toString(), 
                FFSchooxWebhookCourseCompleted.ResponseWrapper.class
            );
        System.assertEquals('ERROR', response.status, 'Expected ERROR status');
        System.assertEquals('Empty payload received', response.message, 'Expected empty payload error');
    }

    @IsTest
    static void testInvalidJson() {
        // Prepare invalid JSON
        String jsonPayload = '{"payload":{"course":invalid}}';

        // Calculate HMAC
        String whId = 'test-wh-id';
        String whTimestamp = String.valueOf(DateTime.now().getTime() / 1000);
        String signable = whId + '.' + whTimestamp + '.' + jsonPayload;
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(signable), Blob.valueOf(WEBHOOK_SECRET));
        String whSignature = EncodingUtil.base64Encode(mac);

        // Set up request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.addHeader('wh-id', whId);
        req.addHeader('wh-timestamp', whTimestamp);
        req.addHeader('wh-signature', whSignature);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Run test
        Test.startTest();
        FFSchooxWebhookCourseCompleted.handleWebhook();
        Test.stopTest();

        // Verify response
        System.assertEquals(400, RestContext.response.statusCode, 'Expected 400 Bad Request');
        FFSchooxWebhookCourseCompleted.ResponseWrapper response = 
            (FFSchooxWebhookCourseCompleted.ResponseWrapper) JSON.deserialize(
                RestContext.response.responseBody.toString(), 
                FFSchooxWebhookCourseCompleted.ResponseWrapper.class
            );
        System.assertEquals('ERROR', response.status, 'Expected ERROR status');
        System.assert(response.message.contains('Invalid JSON format'), 'Expected JSON error');
    }

    @IsTest
    static void testMissingPayloadData() {
        // Prepare JSON with missing data
        String jsonPayload = '{"payload":{"course":null,"user":null,"courseProgress":null}}';

        // Calculate HMAC
        String whId = 'test-wh-id';
        String whTimestamp = String.valueOf(DateTime.now().getTime() / 1000);
        String signable = whId + '.' + whTimestamp + '.' + jsonPayload;
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(signable), Blob.valueOf(WEBHOOK_SECRET));
        String whSignature = EncodingUtil.base64Encode(mac);

        // Set up request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.addHeader('wh-id', whId);
        req.addHeader('wh-timestamp', whTimestamp);
        req.addHeader('wh-signature', whSignature);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Run test
        Test.startTest();
        FFSchooxWebhookCourseCompleted.handleWebhook();
        Test.stopTest();

        // Verify response
        System.assertEquals(400, RestContext.response.statusCode, 'Expected 400 Bad Request');
        FFSchooxWebhookCourseCompleted.ResponseWrapper response = 
            (FFSchooxWebhookCourseCompleted.ResponseWrapper) JSON.deserialize(
                RestContext.response.responseBody.toString(), 
                FFSchooxWebhookCourseCompleted.ResponseWrapper.class
            );
        System.assertEquals('ERROR', response.status, 'Expected ERROR status');
        System.assertEquals('Missing course, user, or courseProgress data', response.message, 'Expected missing data error');
    }

    @IsTest
    static void testNoCourseFound() {
        // Prepare JSON with non-existent course
        String jsonPayload = '{"payload":{"course":{"id":999,"title":"Missing Course","description":"Learn Apex","image":"https://example.com/image.jpg","status":"ACTIVE","visibilityStatus":"PUBLIC"},"user":{"id":1,"firstName":"John","lastName":"Doe","email":"john.doe@example.com"},"courseProgress":{"progress":75,"completionDate":"2025-04-14T10:30:00Z","certificationVerificationCode":"CERT123"}}}';

        // Calculate HMAC
        String whId = 'test-wh-id';
        String whTimestamp = String.valueOf(DateTime.now().getTime() / 1000);
        String signable = whId + '.' + whTimestamp + '.' + jsonPayload;
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(signable), Blob.valueOf(WEBHOOK_SECRET));
        String whSignature = EncodingUtil.base64Encode(mac);

        // Set up request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.addHeader('wh-id', whId);
        req.addHeader('wh-timestamp', whTimestamp);
        req.addHeader('wh-signature', whSignature);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Run test
        Test.startTest();
        FFSchooxWebhookCourseCompleted.handleWebhook();
        Test.stopTest();

        // Verify response
        System.assertEquals(400, RestContext.response.statusCode, 'Expected 400 Bad Request');
        FFSchooxWebhookCourseCompleted.ResponseWrapper response = 
            (FFSchooxWebhookCourseCompleted.ResponseWrapper) JSON.deserialize(
                RestContext.response.responseBody.toString(), 
                FFSchooxWebhookCourseCompleted.ResponseWrapper.class
            );
        System.assertEquals('ERROR', response.status, 'Expected ERROR status');
        System.assertEquals('Course not found for id: 999', response.message, 'Expected no course error');
    }

    @IsTest
    static void testNoUserFound() {
        // Prepare JSON with non-existent user
        String jsonPayload = '{"payload":{"course":{"id":101,"title":"Introduction to Apex","description":"Learn Apex","image":"https://example.com/image.jpg","status":"ACTIVE","visibilityStatus":"PUBLIC"},"user":{"id":999,"firstName":"John","lastName":"Doe","email":"john.doe@example.com"},"courseProgress":{"progress":75,"completionDate":"2025-04-14T10:30:00Z","certificationVerificationCode":"CERT123"}}}';

        // Calculate HMAC
        String whId = 'test-wh-id';
        String whTimestamp = String.valueOf(DateTime.now().getTime() / 1000);
        String signable = whId + '.' + whTimestamp + '.' + jsonPayload;
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(signable), Blob.valueOf(WEBHOOK_SECRET));
        String whSignature = EncodingUtil.base64Encode(mac);

        // Set up request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.addHeader('wh-id', whId);
        req.addHeader('wh-timestamp', whTimestamp);
        req.addHeader('wh-signature', whSignature);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Run test
        Test.startTest();
        FFSchooxWebhookCourseCompleted.handleWebhook();
        Test.stopTest();

        // Verify response
        System.assertEquals(400, RestContext.response.statusCode, 'Expected 400 Bad Request');
        FFSchooxWebhookCourseCompleted.ResponseWrapper response = 
            (FFSchooxWebhookCourseCompleted.ResponseWrapper) JSON.deserialize(
                RestContext.response.responseBody.toString(), 
                FFSchooxWebhookCourseCompleted.ResponseWrapper.class
            );
        System.assertEquals('ERROR', response.status, 'Expected ERROR status');
        System.assertEquals('User not found for id: 999', response.message, 'Expected no user error');
    }

    @IsTest
    static void testNullProgressAndInvalidDate() {
        // Prepare JSON with null progress and invalid date
        String jsonPayload = '{"payload":{"course":{"id":101,"title":"Introduction to Apex","description":"Learn Apex","image":"https://example.com/image.jpg","status":"ACTIVE","visibilityStatus":"PUBLIC"},"user":{"id":1,"firstName":"John","lastName":"Doe","email":"john.doe@example.com"},"courseProgress":{"progress":null,"completionDate":"invalid-date","certificationVerificationCode":"CERT123"}}}';

        // Calculate HMAC
        String whId = 'test-wh-id';
        String whTimestamp = String.valueOf(DateTime.now().getTime() / 1000);
        String signable = whId + '.' + whTimestamp + '.' + jsonPayload;
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(signable), Blob.valueOf(WEBHOOK_SECRET));
        String whSignature = EncodingUtil.base64Encode(mac);

        // Set up request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.addHeader('wh-id', whId);
        req.addHeader('wh-timestamp', whTimestamp);
        req.addHeader('wh-signature', whSignature);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Delete existing enrollment
        delete [SELECT Id FROM SX_Enrollment__c WHERE Student_Course_Id__c = '1#101'];

        // Run test
        Test.startTest();
        FFSchooxWebhookCourseCompleted.handleWebhook();
        Test.stopTest();

        // Verify response
        System.assertEquals(200, RestContext.response.statusCode, 'Expected 200 OK');
        FFSchooxWebhookCourseCompleted.ResponseWrapper response = 
            (FFSchooxWebhookCourseCompleted.ResponseWrapper) JSON.deserialize(
                RestContext.response.responseBody.toString(), 
                FFSchooxWebhookCourseCompleted.ResponseWrapper.class
            );
        System.assertEquals('SUCCESS', response.status, 'Expected SUCCESS status');

        // Verify enrollment
        SX_Enrollment__c enroll = [
            SELECT SX_percent_Completed__c, SX_Completed_Date__c
            FROM SX_Enrollment__c
            WHERE Student_Course_Id__c = '1#101'
            LIMIT 1
        ];
        System.assertEquals(null, enroll.SX_percent_Completed__c, 'Expected null progress');
        System.assertEquals(null, enroll.SX_Completed_Date__c, 'Expected null completion date');
    }
}