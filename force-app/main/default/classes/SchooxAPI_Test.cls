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
            when else {
                res.setBody(getError);
            }
        }
        res.setStatus('statusCode');
        res.setStatusCode(statusCode);
        return res;
    }
}