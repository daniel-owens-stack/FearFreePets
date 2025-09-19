/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-11-15 00:47:44
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:38:07
 * @ Description: Test class for SchooxAPI
 */

@IsTest
public class SchooxAPI_Test {
    @TestSetup static void setup() {
        // SchooxAPI.testResponse = getMockResponse(200, SchooxAPI.ApiType.Course);
        List<SX_LMS_User__c> userList = TestDataFactory.insertLMSUserData();
            // 1) Insert a Person Account (Salesforce will auto-create the Contact)
    RecordType rt = [
      SELECT Id 
      FROM RecordType 
      WHERE SobjectType = 'Account' 
        AND IsPersonType = true
      LIMIT 1
    ];
    
    Account personAcct = new Account(
      LastName     = 'TestPerson',
      RecordTypeId = rt.Id,
      // any other required Person Account fields:
      PersonEmail  = 'person@test.com'
    );
    insert personAcct;
    
    // 2) (Optional) verify that PersonContactId is populated
    personAcct = [
      SELECT Id, PersonContactId 
      FROM Account 
      WHERE Id = :personAcct.Id
    ];
    System.assertNotEquals(
      null, 
      personAcct.PersonContactId, 
      'PersonContactId should be auto-populated on insert'
    );
    }

    @IsTest static void testGetAPI() {
        System.debug('==================SchooxAPI_Test GetAPI=====================');
        Test.startTest();

        SchooxAPI.testResponse = getMockResponse(200, SchooxAPI.ApiType.AllCourse);
        SchooxAPI.getAllCourse('Active');
        SchooxAPI.getUserCourse('123');

        SchooxAPI.testResponse = getMockResponse(200, SchooxAPI.ApiType.AllJob);
        SchooxAPI.getAllJob();
        SchooxAPI.testResponse = getMockResponse(200, SchooxAPI.ApiType.AllUnit);
        SchooxAPI.getAllUnits();
        SchooxAPI.testResponse = getMockResponse(200, SchooxAPI.ApiType.AllAboveUnit);
        SchooxAPI.getAllAboveUnits();

        SchooxAPI.testResponse = getMockResponse(200, SchooxAPI.ApiType.UserDetails);
        SchooxAPI.getUserDetails('123');
        SchooxAPI.removeLMSUser('123');

        SchooxAPI.testResponse = getMockResponse(200, SchooxAPI.ApiType.UserCourse);
        SchooxAPI.assignCourse('123', '321');
        SchooxAPI.assignCourses('123', new List<String>{'321'});

        Test.stopTest();
        System.assertEquals(SchooxAPI.apiError, false, 'Get API');
    }

    @IsTest static void testCreateAPI() {
        System.debug('==================SchooxAPI_Test CreateAPI=====================');

        Account testAcc = [SELECT Name, PersonContactId, SX_Above_Unit_Lookup__r.SX_ID__c FROM Account WHERE PersonContactId != NULL LIMIT 1];
        List<SX_LMS_User__c> testLMSUser = [SELECT SF_Contact__c, SF_User__c FROM SX_LMS_User__c];
        Test.startTest();
        SchooxAPI.testResponse = getMockResponse(200, SchooxAPI.ApiType.Unit);
        SchooxAPI.createLMSUnit(testAcc);

        SchooxAPI.testResponse = getMockResponse(200, SchooxAPI.ApiType.User);
        SchooxAPI.createLMSUser(testAcc.PersonContactId, new List<Integer>{1957825});

        Set<Id> studentIds = new Set<Id>();
        for (SX_LMS_User__c rec : testLMSUser) {
            if (rec.SF_Contact__c != null) {
                studentIds.add(rec.SF_Contact__c);
            } else {
                studentIds.add(rec.SF_User__c);
            }            
        }
        SchooxAPI.testResponse = getMockResponse(200, SchooxAPI.ApiType.Users);
        SchooxAPI.createLMSUsers(studentIds);

        SchooxAPI.testResponse.setBody('');
        SchooxAPI.handleLMSUser(testAcc.Id, new List<Integer>{1957825});

        SchooxAPI.reActivateLMSUser('123');

        Test.stopTest();
        System.assertEquals(SchooxAPI.apiError, false, 'Create API');
    }

  @IsTest
  static void testupdateAndReactivateLMSUser() {
    // 3) Mock both callouts (reactivation POST & update PUT)
    SchooxAPI.testResponse = getMockResponse(200, SchooxAPI.ApiType.User);
    
    // 4) Pull back that Person Account and its generated Contact
    Account acct = [
      SELECT Id, PersonContactId 
      FROM Account 
      WHERE PersonEmail = 'person@test.com' 
      LIMIT 1
    ];
    Contact con = [
      SELECT Id, SX_User_Id__c 
      FROM Contact 
      WHERE Id = :acct.PersonContactId
    ];
    
    // Give the Contact an SX_User_Id__c so reactivation has something to call
    con.SX_User_Id__c = 'SOME_USER_ID';
    update con;
    
    // 5) Now call your method
    Test.startTest();
      SchooxAPI.updateAndReactivateLMSUser(
        acct.Id,
        new List<Integer>{ 1957825 }
      );
    Test.stopTest();
    
    // 6) Assert no API error flag was raised
    System.assertEquals(
      false,
      SchooxAPI.apiError,
      'API error flag should remain false'
    );
  }
  
  @IsTest
static void testMarkCourseComplete_Coverage() {
    // Success WITHOUT completedAtstring
    SchooxAPI.testResponse = getMockResponse(200, SchooxAPI.ApiType.Course);

    Test.startTest();
    Boolean okNoDate = SchooxAPI.markCourseComplete(123, 321, null);

    // Success WITH completedAtstring
    SchooxAPI.testResponse = getMockResponse(200, SchooxAPI.ApiType.Course);
    Boolean okWithDate = SchooxAPI.markCourseComplete(123, 321, '2025-08-20');

    // Failure path (non-2xx)
    SchooxAPI.testResponse = getMockResponse(400, SchooxAPI.ApiType.Course);
    Boolean fail = SchooxAPI.markCourseComplete(123, 321, '2025-08-21');
    Test.stopTest();

    System.assertEquals(true,  okNoDate,  'no-date call should succeed');
    System.assertEquals(true,  okWithDate,'with-date call should succeed');
    System.assertEquals(false, fail,      '400 should return false');
}


@IsTest
static void testParseUserCourseDataWithoutUpsert_HappyPath() {
    // Contact linked by SX_User_Id__c
    Account a = new Account(Name='Acct for Enroll Test');
    insert a;
    Contact c = new Contact(LastName='Learner', AccountId=a.Id, Email='learner@test.com', SX_User_Id__c='1987174188');
    insert c;

    // Matching course (id 320)
    SX_Courses__c course = new SX_Courses__c(Name='Course 320', SX_Course_ID__c='320');
    insert course;

    // Single-line JSON (no line breaks!)
    String responseBody = '[{"id":320,"progress":100,"enroll_date":"2025-07-01","timecompleted":"2025-07-15"},'
                        + '{"id":999,"progress":50,"enroll_date":"2025-07-01","timecompleted":null}]';

    // Call
    List<SX_Enrollment__c> out = SchooxAPI.parseUserCourseDataWithoutUpsert('1987174188', responseBody);

    // Assert only the matching one (320) returned
    System.assertEquals(1, out.size(), 'Only 1 enrollment should be created');
    SX_Enrollment__c e = out[0];
    System.assertEquals('1987174188#320', e.Student_Course_Id__c);
    System.assertEquals(c.Id, e.SF_Contact_Lookup__c);
    System.assertEquals(course.Id, e.SX_Course__c);
    System.assertEquals(Decimal.valueOf(100), e.SX_percent_Completed__c);
    System.assertNotEquals(null, e.SX_Enrollment_Date__c);
    System.assertNotEquals(null, e.SX_Completed_Date__c);
}

@IsTest
static void testParseUserCourseDataWithoutUpsert_EmptyResponse() {
    List<SX_Enrollment__c> out = SchooxAPI.parseUserCourseDataWithoutUpsert('ANY', '[]');
    System.assertEquals(0, out.size(), 'Empty response should yield no enrollments');
}

 @IsTest
    static void testParseWithoutUpsert_DedupeAndDates() {
        // ---- Test data setup ----
        // Contact with SX_User_Id__c so SF_Contact_Lookup__c gets set
        Account a = new Account(Name = 'Acct');
        insert a;
        Contact c = new Contact(LastName = 'User', AccountId = a.Id, SX_User_Id__c = 'U-TEST-1');
        insert c;

        // Courses that will be referenced by JSON
        SX_Courses__c c111 = new SX_Courses__c(Name='C111', SX_Course_ID__c='111');
        SX_Courses__c c222 = new SX_Courses__c(Name='C222', SX_Course_ID__c='222');
        SX_Courses__c c444 = new SX_Courses__c(Name='C444', SX_Course_ID__c='444');
        insert new List<SX_Courses__c>{ c111, c222, c444 };

        // JSON payload with duplicates for same course:
        // 111: non-complete then complete (should keep the completed row)
        // 222: two completes; keep the OLDEST (earliest) completion date
        // 444: both not completed; keep the one with HIGHER progress
        // 999: not in SX_Courses__c -> should be skipped
        String json = '[' +
            // course 111
            '{"id":"111","progress":20,"enroll_date":"2024-11-01T00:00:00+00:00"},' +
            '{"id":"111","progress":100,"enroll_date":"2024-11-02T00:00:00+00:00","timecompleted":"2024-11-23T12:00:00+00:00"},' +
            // course 222 (first newer 2024-01-01, then older 2023-01-01 → keep 2023-01-01)
            '{"id":"222","progress":100,"enroll_date":"2024-02-01T00:00:00+00:00","timecompleted":"2024-01-01T00:00:00+00:00"},' +
            '{"id":"222","progress":100,"enroll_date":"2024-02-02T00:00:00+00:00","timecompleted":"2023-01-01T00:00:00+00:00"},' +
            // course 444 (no completion; choose higher progress 80)
            '{"id":"444","progress":40,"enroll_date":"2024-10-01T00:00:00+00:00"},' +
            '{"id":"444","progress":80,"enroll_date":"2024-10-02T00:00:00+00:00"},' +
            // unknown course 999 → skipped
            '{"id":"999","progress":100,"enroll_date":"2024-05-01T00:00:00+00:00","timecompleted":"2024-05-02T00:00:00+00:00"}' +
        ']';

        // ---- Exercise the method under test ----
        List<SX_Enrollment__c> out = SchooxAPI.parseUserCourseDataWithoutUpsert('U-TEST-1', json);

        // We expect only mapped courses: 111, 222, 444  => 3 rows
        System.assertEquals(3, out.size(), 'Should return one deduped row per known course');

        // Build a lookup by course Id for easy asserts
        Map<Id, SX_Enrollment__c> byCourse = new Map<Id, SX_Enrollment__c>();
        for (SX_Enrollment__c e : out) byCourse.put(e.SX_Course__c, e);

        // ---- Assert course 111 kept the COMPLETED one with the parsed date ----
        System.assert(byCourse.containsKey(c111.Id), 'course 111 present');
        SX_Enrollment__c e111 = byCourse.get(c111.Id);
        System.assertEquals('U-TEST-1#111', e111.Student_Course_Id__c, 'key should match');
        System.assertEquals(Date.newInstance(2024,11,23), e111.SX_Completed_Date__c, '111 should keep completed row (date only)');
        System.assertEquals(Decimal.valueOf(100), e111.SX_percent_Completed__c, '111 progress should be 100 after dedupe');

        // ---- Assert course 222 kept the OLDEST completion date (2023-01-01) ----
        System.assert(byCourse.containsKey(c222.Id), 'course 222 present');
        SX_Enrollment__c e222 = byCourse.get(c222.Id);
        System.assertEquals(Date.newInstance(2023,1,1), e222.SX_Completed_Date__c, '222 should keep earliest completion date');

        // ---- Assert course 444 chose the higher progress (80) and has no completion date ----
        System.assert(byCourse.containsKey(c444.Id), 'course 444 present');
        SX_Enrollment__c e444 = byCourse.get(c444.Id);
        System.assertEquals(null, e444.SX_Completed_Date__c, '444 should be not completed');
        System.assertEquals(Decimal.valueOf(80), e444.SX_percent_Completed__c, '444 should keep higher progress');

        // Also ensures these lines execute:
        // Utility.decimalValue(progress), Utility.dateValue(enroll_date), Utility.dateValue(timecompleted),
        // initial put into byKey, and each replacement branch.
    }



    public static HttpResponse getMockResponse(Integer statusCode, SchooxAPI.ApiType type) {
        List<Contact> conList = [SELECT Id FROM Contact LIMIT 1];
        Id lsmId;
        if (conList.isEmpty()) {
            conList = TestDataFactory.insertContactData();
        }
        lsmId = conList.get(0).Id;
        List<SX_Unit__c> unitList = [SELECT Id FROM SX_Unit__c LIMIT 1];
        Id unitId;
        if (!unitList.isEmpty()) {
            unitId = unitList.get(0).Id;
        }
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        String coursesResponse = '[{"id":320,"title":"LinkedIn Learning AICC Integration","description":"<p>Key reference</p>","course_duration":600,"rating":0,"url":"https://www.schoox.com/linkedin-integration","image":"https://content-cdn3.schoox.com/75cd8a.png","level":"Introductory","language":"English","progress":100,"time":"0:03:42","price":0},{"id":321,"title":"Module 2 - Costing Techniques","description":"<p>The Costing.</p>","url":"https://www.schoox.com/module-2","image":"https://www.schoox.com/image.png","level":"Introductory","language":"English","price":0,"progress":100,"time":"0:03:42","academy_id":2147411132}]';

        String jobsResponse = '[{"id":823652,"name":"Unit Manager","external_id":"","deletable":false},{"id":823653,"name":"Assistant Unit Manager","external_id":"","deletable":false}]';
        String unitsResponse = '[{"id":878157,"name":"Advanced  Location1","external_id":null,"above_ids":[{"id":1022980,"name":"ASport","type":"Demo"}]},{"id":878158,"name":"Austin","external_id":null,"above_ids":[{"id":1022984,"name":"US-Southwest","type":"C Technologies"}]}]';
        String aboveUnitsResponse = '[{"id":100,"name":"IMedical Systems","type_id":259323,"external_id":null,"parent_id":0,"parent_external_id":null},{"id":101,"name":"S Technologies","type_id":259323,"external_id":null,"parent_id":0,"parent_external_id":null}]';
        
        String userDetailsResponse = '{"id":123,"firstname":"Ridowan","lastname":"Ahmed","email":"ridowan.dev@gmail.com","external_ids":["' + lsmId + '"],"username":"","joined_date":"1970-01-01","image":"https://www.schoox.com/user/images/no-user-image_small.gif","url":"https://www.schoox.com/user/1987174188/","active":false,"phone":"","mobile":"","city":"","country":"","country_code":"","state":"","address":"","zip":"","middlename":"","custom_fields":[{"Dietary Restrictions":""}],"units":[],"above_units":[],"registration_fields":[],"last_login":"2022-09-11 03:52:04","modified_at":"2022-09-11 03:59:35","hourly_worker":false,"hired_date":"2022-08-10","certificates":[{"id":190379677,"course_id":3021634,"ver_code":"acc1dc0","total_time":"0:00:00","time_certified":"2022-09-11T03:53:08+00:00","url":"https://www.schoox.com/c190379677?ver_code=acc1dc0"}]}';
        String assignCourseResponse = '[{"id":320,"course_id":320,"message":"User successfully assigned"},{"id":321,"course_id":321,"message":"User successfully assigned"}]';
        
        String unitResponse = '{"id":1120,"status":201,"name":"Test 4","external_id":"' + unitId + '"}';
        String userResponse = '{"firstname":"Ridowan","lastname":"Ahmed","password":"jRJqPVPHZYSeDXPU","email":"ridowan.dev@gmail.com","external_ids":["' + lsmId + '"],"language":"English","hired_date":"2022-08-10","employee_type":"Manager","employee_number":"AurW323","id":1987174188,"status":201}';
        String usersResponse = '[{"firstname":"Ridowan","lastname":"Ahmed","password":"jRJqPVPHZYSeDXPU","email":"ridowan.dev@gmail.com","external_ids":["' + lsmId + '"],"language":"English","hired_date":"2022-08-10","employee_type":"Manager","employee_number":"AurW323","id":1987174188,"status":201}]';

        String getError = '{ "errors": "Not Found"}';

        switch on String.valueOf(type) {
            when 'AllCourse' {
                res.setBody(coursesResponse);
            }
            when 'AllJob' {
                res.setBody(jobsResponse);
            }
            when 'AllUnit' {
                res.setBody(unitsResponse);
            }
            when 'AllAboveUnit' {
                res.setBody(aboveUnitsResponse);
            }
            when 'UserDetails' {
                res.setBody(userDetailsResponse);
            }
            when 'UserCourse' {
                res.setBody(assignCourseResponse);
            }
            when 'Unit' {
                res.setBody(unitResponse);
            }
            when 'User' {
                res.setBody(userResponse);
            }
            when 'Users' {
                res.setBody(usersResponse);
            }
            when 'Course' {
                res.setBody('{"status":"ok"}');
            }
            when else {
                res.setBody(getError);
            }
        }
        res.setStatus('statusCode');
        res.setStatusCode(statusCode);
        return res;
    }
}