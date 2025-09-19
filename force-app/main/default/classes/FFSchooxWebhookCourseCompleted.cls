@RestResource(urlMapping='/syncEnrollments')
global with sharing class FFSchooxWebhookCourseCompleted {
    private static String WEBHOOK_SECRET = Label.SX_WEBHOOK_SECRET;

    global class CourseWrapper {
        public Integer id;
        public String title;
        public String description;
        public String image;
        public String status;
        public String visibilityStatus;
    }

    global class UserWrapper {
        public Integer id;
        public String firstName;
        public String lastName;
        public String email;
    }

    global class CourseProgressWrapper {
        public Integer progress;
        public String completionDate;
        public String certificationVerificationCode;
    }

    global class PayloadWrapper {
        public CourseWrapper course;
        public UserWrapper user;
        public CourseProgressWrapper courseProgress;
    }

    global class ResponseWrapper {
        public String status;
        public String message;
        public List<String> errors;
    }

    // HMAC Utility (must not be static inside an inner class)
    global class CryptoUtil {
        public String calculateHmacSHA256(String secret, String data) {
            Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(data), Blob.valueOf(secret));
            return EncodingUtil.base64Encode(mac);
        }
    }

    @HttpPost
    global static void handleWebhook() {
        ResponseWrapper response = new ResponseWrapper();
        response.errors = new List<String>();

        try {
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
            System.debug('Schoox Webhook Payload: ' + jsonBody);

            String whId = req.headers.get('wh-id');
            String whTimestamp = req.headers.get('wh-timestamp');
            String whSignatureHeader = req.headers.get('wh-signature');

            if (String.isBlank(whId) || String.isBlank(whTimestamp) || String.isBlank(whSignatureHeader)) {
                response.status = 'ERROR';
                response.message = 'Missing webhook headers';
                setResponse(400, response);
                return;
            }

            Long now = DateTime.now().getTime() / 1000;
            Long timestamp = Long.valueOf(whTimestamp);
            Long tolerance = 300;
            if (Math.abs(now - timestamp) > tolerance) {
                response.status = 'ERROR';
                response.message = 'Webhook timestamp outside allowed tolerance';
                setResponse(400, response);
                return;
            }

            String secret = WEBHOOK_SECRET;
            String signable = whId + '.' + whTimestamp + '.' + jsonBody;

            String expectedSignature = new CryptoUtil().calculateHmacSHA256(secret, signable);
            if (!whSignatureHeader.contains(expectedSignature)) {
                response.status = 'ERROR';
                response.message = 'Signature mismatch. Webhook not verified.';
                setResponse(401, response);
                return;
            }

            if (String.isBlank(jsonBody)) {
                response.status = 'ERROR';
                response.message = 'Empty payload received';
                setResponse(400, response);
                return;
            }

            PayloadWrapper payload;
            try {
                Map<String, Object> raw = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
                Object payloadObj = raw.get('payload');
                payload = (PayloadWrapper) JSON.deserialize(JSON.serialize(payloadObj), PayloadWrapper.class);
            } catch (JSONException e) {
                response.status = 'ERROR';
                response.message = 'Invalid JSON format: ' + e.getMessage();
                setResponse(400, response);
                return;
            }

            if (payload.course == null || payload.user == null || payload.courseProgress == null) {
                response.status = 'ERROR';
                response.message = 'Missing course, user, or courseProgress data';
                setResponse(400, response);
                return;
            }

            String courseId = String.valueOf(payload.course.id);
            String sxUserId = String.valueOf(payload.user.id);

            Map<String, Id> courseIdToRecordId = new Map<String, Id>();
            List<SX_Courses__c> courses = [
                SELECT Id, SX_Course_ID__c 
                FROM SX_Courses__c 
                WHERE SX_Course_ID__c = :courseId 
                WITH SECURITY_ENFORCED 
                LIMIT 1
            ];
            if (courses.isEmpty()) {
                response.status = 'ERROR';
                response.message = 'Course not found for id: ' + courseId;
                setResponse(400, response);
                return;
            }
            courseIdToRecordId.put(courseId, courses[0].Id);

            List<SX_LMS_User__c> lmsUsers = [
                SELECT Id
                FROM SX_LMS_User__c
                WHERE SX_User_ID__c = :sxUserId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if (lmsUsers.isEmpty()) {
                response.status = 'ERROR';
                response.message = 'User not found for id: ' + sxUserId;
                setResponse(400, response);
                return;
            }
            SX_LMS_User__c lmsUser = lmsUsers[0];

            List<SX_Enrollment__c> existingEnrollments = [
                SELECT Id, SX_Enrollment_Date__c
                FROM SX_Enrollment__c
                WHERE Student_ID__c = :lmsUser.Id
                AND SX_Course__r.SX_Course_ID__c = :courseId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            SX_Enrollment__c tempEnroll = new SX_Enrollment__c(
                Student_Course_Id__c = sxUserId + '#' + courseId,
                Student_ID__c = lmsUser.Id,
                SX_Course__c = courseIdToRecordId.get(courseId),
                SX_percent_Completed__c = payload.courseProgress.progress != null ? 
                                         Decimal.valueOf(payload.courseProgress.progress) : null,
                SX_Completed_Date__c = String.isNotBlank(payload.courseProgress.completionDate) ?
                                      dateValue(payload.courseProgress.completionDate) : null
            );

            if (existingEnrollments.isEmpty()) {
                tempEnroll.SX_Enrollment_Date__c = Date.today();
            } else {
                tempEnroll.Id = existingEnrollments[0].Id;
                tempEnroll.SX_Enrollment_Date__c = existingEnrollments[0].SX_Enrollment_Date__c;
            }

            List<Contact> sfContact = [SELECT Id FROM Contact WHERE SX_User_Id__c = :sxUserId LIMIT 1];
            if (!sfContact.isEmpty()) {
                tempEnroll.SF_Contact_Lookup__c = sfContact[0].Id;
            }

            Database.UpsertResult upsertResult = Database.upsert(
                tempEnroll,
                SX_Enrollment__c.Fields.Student_Course_Id__c,
                false
            );
            if (!upsertResult.isSuccess()) {
                for (Database.Error err : upsertResult.getErrors()) {
                    response.errors.add('Enrollment upsert error: ' + err.getMessage());
                }
                response.status = 'ERROR';
                response.message = 'Failed to upsert enrollment';
                setResponse(400, response);
                return;
            }

            response.status = 'SUCCESS';
            response.message = 'Enrollment updated successfully';
            setResponse(200, response);

        } catch (Exception e) {
            response.status = 'ERROR';
            response.message = 'Server error: ' + e.getMessage();
            setResponse(500, response);
        }
    }

    private static void setResponse(Integer statusCode, ResponseWrapper response) {
        RestContext.response.statusCode = statusCode;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
    }

    private static Date dateValue(String isoDateString) {
        try {
            return Date.valueOf(isoDateString.substring(0, 10));
        } catch (Exception e) {
            return null;
        }
    }
}