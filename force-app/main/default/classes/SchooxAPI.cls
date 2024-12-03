/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-09-05 21:35:02
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:37:59
 * @ Description: Test class is SchooxAPI_Test
 * https://app.schoox.com/api-docs
 */

public with sharing class SchooxAPI {
    private static String API_URL = Label.SX_API_URL;
    private static String API_KEY = Label.SX_API_Key;
    private static String ACADEMY_ID = Label.SX_Academy_Id;
    public static Boolean apiError = false;
    public static HttpResponse testResponse;
    @TestVisible
    private enum ApiType {User, Users, UserDetails, AllCourse, UserCourse, AllJob, AllUnit, Enrollment, AllAboveUnit, Above, Unit, AboveUnit, Course}

    private class LMSData {
        private String firstname;
        private String lastname;
        private String password = 'jRJqPVPHZYSeDXPU';
        private Boolean welcomeEmail = false;
        private String email;
        private Date joined_date = Date.today();
        private String language = 'English';
        private List<String> external_ids;

        private List<JobData> jobs;
        private List<Integer> unit_ids = new List<Integer>{1532475};
        private List<Integer> above_ids;
        private List<String> roles = new List<String>{'employee'};

        private LMSData(Contact con) {
            this.firstname = con.firstName;
            this.lastname = con.lastName;
            this.email = con.Email;
            if (String.isNotBlank(con.SX_Job_Lookup__r.SX_Job_ID__c)) {
                this.jobs = new List<JobData>{new JobData(Integer.valueOf(con.SX_Job_Lookup__r.SX_Job_ID__c))};
            }
            if (String.isNotBlank(con.Account.SX_Unit_Lookup__r.SX_ID__c)) {
                this.unit_ids.add(Integer.valueOf(con.Account.SX_Unit_Lookup__r.SX_ID__c));
            }
            if (String.isNotBlank(con.Account.SX_Above_Unit_Lookup__r.SX_ID__c)) {
                this.above_ids = new List<Integer>{Integer.valueOf(con.Account.SX_Above_Unit_Lookup__r.SX_ID__c)};
            }
            this.external_ids = new List<String>{con.Id};
        }
        private LMSData(User member) {
            List<String> nameList = member.Name.split(' ');
            this.firstname = nameList.get(0);
            this.lastname = nameList.get(1);
            this.email = member.Email;
            this.external_ids = new List<String>{member.Id};
        }
    }

    private class LMSEditData {
        private String firstname;
        private String lastname;
        private String email;
        private List<Integer> unit_ids = new List<Integer>{1532475};
        private List<JobData> jobs;
        private LMSEditData(Contact con, List<Integer> jobIdList) {
            this.firstname = con.FirstName;
            this.lastname = con.LastName;
            this.email = con.Email;
            if (jobIdList != null) {
                this.jobs = new List<JobData>{new JobData(jobIdList)};
            }
        }
    }

    private class JobData {
        private Integer unit_id = 1532475;
		private List<Integer> jobs;

        private JobData(Integer jobId) {
            this.jobs = new List<Integer>{jobId};
        }
		private JobData(List<Integer> jobIdList) {
			this.jobs = jobIdList;
		}
    }
	private class UnitData {
        private String name;
        private String external_id;
        private List<Integer> above_ids;

        private UnitData(Account acc) {
            this.name = acc.Name;
            this.external_id = acc.Id;
            if (acc.SX_Above_Unit_Lookup__c != null && String.isNotBlank(acc.SX_Above_Unit_Lookup__r.SX_ID__c)) {
                this.above_ids = new List<Integer>{Integer.valueOf(acc.SX_Above_Unit_Lookup__r.SX_ID__c)};
            }
        }
    }

    public static List<SObject> createLMSUsers(Set<Id> studentIds) {
        System.debug('<-----------createLMSUsers----------->');
        Map<Id, Id> lmsUserByStudentId = new Map<Id,Id>();
        for (SX_LMS_User__c lmsUser : [SELECT SF_User__c, SF_Contact__c FROM SX_LMS_User__c WHERE SF_User__c IN :studentIds OR SF_Contact__c IN :studentIds]) {
            lmsUserByStudentId.put(String.isNotBlank(lmsUser.SF_User__c) ? lmsUser.SF_User__c : lmsUser.SF_Contact__c, lmsUser.Id);
        }
        Set<Id> contactIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        for (Id studentId : studentIds) {
            if (studentId.getSobjectType() == Schema.Contact.getSObjectType()) {
                contactIds.add(studentId);
            } else {
                userIds.add(studentId);
            }
        }
        List<LMSData> lmsList = new List<LMSData>();
        for (Contact conRec : [
            SELECT FirstName, LastName, Email, SX_Job_Lookup__r.SX_Job_ID__c, Account.SX_Unit_Lookup__r.SX_ID__c, Account.SX_Above_Unit_Lookup__r.SX_ID__c
            FROM Contact 
            WHERE Id IN :contactIds
        ]){
            lmsList.add(new LMSData(conRec));
        }
        for (User userRec : [SELECT Name, Email FROM User WHERE Id IN :userIds]) lmsList.add(new LMSData(userRec));

        System.debug(JSON.serializePretty(lmsList));
        String url = API_URL + 'users/bulk';
        Map<String, String> responseMap = makeHTTPRequest(ApiType.Users, url, 'POST', JSON.serialize(lmsList));
        List<Object> responseBodyList = (List<Object>) JSON.deserializeUntyped(responseMap.get('responseBody'));
        List<SObject> studentList = new List<SObject>();
        Set<String> sxIds = new Set<String>();  //storing sx ids for getting active status
        if (!responseBodyList.isEmpty()) {
            for (Object responseRec : responseBodyList) {
                Map<String, Object> responseRecMap = (Map<String, Object>) responseRec;
                Integer status = (Integer) responseRecMap.get('status');
                Date joined_date = Utility.dateValue(responseRecMap.get('joined_date'));
                Object external_ids = responseRecMap.get('external_ids');
                List<Object> recordIds = (List<Object>) external_ids;
                Id recordId = String.valueOf(recordIds.get(0));
                String lms_id = String.valueOf(responseRecMap.get('id'));

                Id lmsUserId = lmsUserByStudentId.get(recordId);
                SObject student = recordId.getSobjectType().newSObject(recordId);
                student.put('SX_User_ID__c', lms_id);
                student.put('SX_LMS_User__c', lmsUserId);
                //student.put('SX_Activation_Date__c', joined_date);
                if (status == 201) {
                    student.put('SX_Active_User__c', true);
                }else {
                    SX_LMS_User__c studentDetail = getUserDetails(lms_id);
                    student.put('SX_Active_User__c', studentDetail.SX_Active_User__c);
                }
                studentList.add(student);
                if (lmsUserId != null) {
                    SObject lmsUser = lmsUserId.getSobjectType().newSObject(lmsUserId);
                    lmsUser.put('SX_User_ID__c', lms_id);
                    lmsUser.put('SX_Active_User__c', student.get('SX_Active_User__c'));
                    lmsUser.put('SX_Activation_Date__c', joined_date);
                    studentList.add(lmsUser);
                }
            }
            System.debug(JSON.serializePretty(studentList));
        } else {
            System.debug(responseMap.get('responseBody'));
        }
        update studentList;
        return studentList;
    }

    //SchooxAPI.handleLMSUser('0034W0000374nhdQAA', new List<Integer>{1957825});
    public static SX_LMS_User__c handleLMSUser(Id studentId, List<Integer> jobIdList){
        if (studentId.getSobjectType() == Account.SObjectType) {
            Account acc = [SELECT Name, PersonContactId FROM Account WHERE Id = :studentId];
            studentId = acc.PersonContactId;
        }
        Contact con = [SELECT FirstName, LastName, Email, SX_User_Id__c, SX_Active_User__c, SX_Job_Lookup__r.SX_Job_ID__c, Account.SX_Unit_Lookup__r.SX_ID__c, Account.SX_Above_Unit_Lookup__r.SX_ID__c FROM Contact WHERE Id = :studentId LIMIT 1];
        if (String.isBlank(con.SX_User_Id__c)) {
            SX_LMS_User__c lmsUser = createLMSUser(studentId, jobIdList);
            insert lmsUser;
            Contact lmsCon = new Contact(
                    Id = studentId,
                    SX_LMS_User__c = lmsUser.Id,
                    SX_User_Id__c = lmsUser.SX_User_ID__c,
                    SX_Active_User__c = lmsUser.SX_Active_User__c
            );
            update lmsCon;
            return lmsUser;
        } else if(!con.SX_Active_User__c){
            throw new CalloutException('User is not active. Please activate the user first.');
        } else {
            updateLMSUser(studentId, jobIdList);
        }
        return null;
    }

    //SchooxAPI.createLMSUser('0034W0000374nhdQAA', new List<Integer>{1957825});
    public static SX_LMS_User__c createLMSUser(Id studentId, List<Integer> jobIdList) {
        System.debug('<-----------createLMSUser----------->');
        LMSData bodyData;
        if (studentId.getSobjectType() == Account.SObjectType) {
            Account acc = [SELECT Name, PersonContactId FROM Account WHERE Id = :studentId];
            studentId = acc.PersonContactId;
        }
        switch on String.valueOf(studentId.getSobjectType()) {
            when 'Contact' {
                Contact con = [SELECT FirstName, LastName, Email, SX_Job_Lookup__r.SX_Job_ID__c, Account.SX_Unit_Lookup__r.SX_ID__c, Account.SX_Above_Unit_Lookup__r.SX_ID__c FROM Contact WHERE Id = :studentId LIMIT 1];
                bodyData = new LMSData(con);
            }
            when 'User' {
                User member = [SELECT Name, Email FROM User WHERE Id = :studentId LIMIT 1];
                bodyData = new LMSData(member);
            }
            when else {
                //
            }
        }
        if (jobIdList != null) {
            if (bodyData.jobs == null || bodyData.jobs.isEmpty()) {
				bodyData.jobs = new List<JobData>{new JobData(jobIdList)};
            } else {
                bodyData.jobs.add(new JobData(jobIdList));
            }
        }
        //System.debug(JSON.serializePretty(bodyData));
        String url = API_URL + 'users';
        Map<String, String> responseMap = makeHTTPRequest(ApiType.User, url, 'POST', JSON.serialize(bodyData));
        String responseBody = responseMap.get('responseBody');
        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        System.debug(JSON.serializePretty(responseBodyMap));
        String error = String.valueOf(responseBodyMap.get('error'));
        System.debug('error: ' + error);
        String sxId = String.valueOf(responseBodyMap.get('id'));
        System.debug('sxId: ' + sxId);
        if (String.isNotBlank(error)) {
            if (String.isNotBlank(sxId)) {
                throw new CalloutException (sxId + ' ' + error);
            } else {
                throw new CalloutException (error);
            }
        }
        String lms_id = String.valueOf(responseBodyMap.get('id'));
        Integer status = (Integer) responseBodyMap.get('status');
        Date joined_date = Utility.dateValue(responseBodyMap.get('joined_date'));
        SX_LMS_User__c student = new SX_LMS_User__c(
            SX_User_ID__c = lms_id,
            API_Response__c = responseBody,
            SX_Activation_Date__c = joined_date
        );
		switch on String.valueOf(studentId.getSobjectType()) {
			when 'Contact' {
				student.RecordTypeId = Schema.SObjectType.SX_LMS_User__c.getRecordTypeInfosByDeveloperName().get('External').getRecordTypeId();
				student.SF_Contact__c = studentId;
			}
			when 'User' {
				student.RecordTypeId = Schema.SObjectType.SX_LMS_User__c.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
				student.SF_User__c = studentId;
			}
			when else {
				//
			}
		}
        if (status == 201) {
            student.SX_Active_User__c = true;
        }else {
            SX_LMS_User__c studentDetail = getUserDetails(lms_id);
            if (student != null) {
                student.SX_Active_User__c = studentDetail.SX_Active_User__c;
            }            
        }
        return student;
    }

    //SchooxAPI.updateLMSUser('001WL000005KfixYAC', new List<Integer>{1957825});
    public static void updateLMSUser(Id studentId, List<Integer> jobIdList) {
        System.debug('<-----------updateLMSUser----------->');
        LMSEditData bodyData;
        if (studentId.getSobjectType() == Account.SObjectType) {
            Account acc = [SELECT Name, PersonContactId FROM Account WHERE Id = :studentId];
            studentId = acc.PersonContactId;
        }
        Contact con = [SELECT FirstName, LastName, Email, SX_User_Id__c, SX_Job_Lookup__r.SX_Job_ID__c, Account.SX_Unit_Lookup__r.SX_ID__c, Account.SX_Above_Unit_Lookup__r.SX_ID__c FROM Contact WHERE Id = :studentId LIMIT 1];
        bodyData = new LMSEditData(con, jobIdList);

        System.debug(JSON.serializePretty(bodyData));
        String url = API_URL + 'users/' + con.SX_User_Id__c;
        Map<String, String> responseMap = makeHTTPRequest(ApiType.User, url, 'PUT', JSON.serialize(bodyData));
        String responseBody = responseMap.get('responseBody');
        System.debug(responseBody);
        if (String.isNotBlank(responseBody)) {
            throw new IllegalArgumentException(responseBody);
        }
    }

    //SchooxAPI.getUserDetails('1987174188');
    public static SX_LMS_User__c getUserDetails(String sxUserId) {
        System.debug('<-----------getUserDetails----------->');
        String url = API_URL + 'users/' + sxUserId;
        Map<String, String> responseMap = makeHTTPRequest(ApiType.UserDetails, url, 'GET', null);
        SX_LMS_User__c student;
        try {
            Map<String, Object> responseRecMap = (Map<String, Object>) JSON.deserializeUntyped(responseMap.get('responseBody'));
            Date joined_date = Utility.dateValue(responseRecMap.get('joined_date'));
            Boolean isActive = (Boolean) responseRecMap.get('active');
            Object external_ids = responseRecMap.get('external_ids');
            List<Object> recordIds = (List<Object>) external_ids;
            Id recordId = String.valueOf(recordIds.get(0));
            String lms_id = String.valueOf(responseRecMap.get('id'));

            student = new SX_LMS_User__c(
                // Id = recordId,
                SX_User_ID__c = lms_id,
                SX_Activation_Date__c = joined_date,
                SX_Active_User__c = isActive
            );
        } catch (Exception ex) {
            Utility.printException(ex);
        }
        return student;
    }

    public static Boolean removeLMSUser(String studentId) {
        System.debug('<-----------removeLMSUser----------->');
        String url = API_URL + 'users/' + studentId;
        Map<String, String> responseMap = makeHTTPRequest(ApiType.User, url, 'DELETE', null);
		//System.debug(responseMap.get('responseBody'));
		return !apiError;
    }

    public static Boolean reActivateLMSUser(String studentId) {
        System.debug('<-----------reActivateLMSUser----------->');
        Map<String, String> bodyMap = new Map<String, String>{
                'id' => studentId
        };
        String url = API_URL + 'users';
        Map<String, String> responseMap = makeHTTPRequest(ApiType.User, url, 'POST', JSON.serialize(bodyMap));
		//System.debug(responseMap.get('responseBody'));
		return !apiError;
    }

    //SchooxAPI.assignCourses('1987174188', new List<String>{'3021632', '3021631'});
    public static Map<String, Map<String, String>> assignCourses(String studentId, List<String> courseList) {
        System.debug('<-----------assignCourses----------->');
        String url = API_URL + 'users/' + studentId + '/courses';
        Map<String, List<String>> bodyMap = new Map<String, List<String>>{
            'courses' => courseList
        };
        Map<String, String> responseMap = makeHTTPRequest(ApiType.Enrollment, url, 'PUT', JSON.serialize(bodyMap));
        System.debug(JSON.serializePretty(responseMap));
        List<Object> responseBodyList = (List<Object>) JSON.deserializeUntyped(responseMap.get('responseBody'));
        Map<String, Map<String, String>> resultMap = new Map<String, Map<String, String>>();
        if (!responseBodyList.isEmpty()) {
            for (Object responseRec : responseBodyList) {
                Map<String, Object> responseRecMap = (Map<String, Object>) responseRec;
                String course_id = String.valueOf(responseRecMap.get('course_id'));
                String message = String.valueOf(responseRecMap.get('message'));
                
                resultMap.put(course_id, new Map<String, String>{
                    'course_id'=> course_id,
                    'message'=> message
                });
            }
            // System.debug(JSON.serializePretty(resultMap));
        } else {
            System.debug(responseBodyList);
        }
        return resultMap;
    }
    //SchooxAPI.assignCourse('1987174188', '3021632');
    public static String assignCourse(String courseId, String studentId) {
        System.debug('<-----------assignCourses----------->');
        String url = API_URL + 'users/' + studentId + '/courses';
        Map<String, List<String>> bodyMap = new Map<String, List<String>>{
            'courses' => new List<String>{courseId}
        };
        Map<String, String> responseMap = makeHTTPRequest(ApiType.User, url, 'PUT', JSON.serialize(bodyMap));
        List<Object> responseBodyList = (List<Object>) JSON.deserializeUntyped(responseMap.get('responseBody'));
        String message;
        if (!responseBodyList.isEmpty()) {
            Map<String, Object> responseRecMap = (Map<String, Object>) responseBodyList.get(0);
            message = String.valueOf(responseRecMap.get('message'));
            System.debug('message: ' + message);
        } else {
            System.debug(responseBodyList);
        }
        return message;
    }

    //SchooxAPI.getUserCourse('102200521');
    public static List<SX_Enrollment__c> getUserCourse(String sxUserId) {
        System.debug('<-----------getUserCourse----------->');
        String url = API_URL + 'dashboard/users/' + sxUserId + '/courses';
        Map<String, String> responseMap = makeHTTPRequest(ApiType.UserCourse, url, 'GET', null);
        try {
            return parseUserCourseData(sxUserId, responseMap.get('responseBody'));
        } catch (Exception ex) {
            Utility.printException(ex);
            throw new AuraHandledException(responseMap.get('responseBody'));
        }
    }

    public static List<SX_Enrollment__c> parseUserCourseData(String sxUserId, String responseBody){
        List<Object> responseBodyList = (List<Object>) JSON.deserializeUntyped(responseBody);
        List<SX_Enrollment__c> courseEnrollList = new List<SX_Enrollment__c>();
        if (!responseBodyList.isEmpty()) {
            for (Object responseRec : responseBodyList) {
                Map<String, Object> responseRecMap = (Map<String, Object>) responseRec;
                String courseId = String.valueOf(responseRecMap.get('id'));
                SX_Enrollment__c tempEnroll = new SX_Enrollment__c(
                    Student_Course_Id__c = sxUserId + '#' + courseId,
                    Student_ID__r = new SX_LMS_User__c(SX_User_ID__c = sxUserId),
                    SX_Course__r = new SX_Courses__c(SX_Course_ID__c = courseId),
                    SX_percent_Completed__c = Utility.decimalValue(responseRecMap.get('progress')),
                    SX_Enrollment_Date__c = Utility.dateValue(responseRecMap.get('enroll_date')),
                    SX_Completed_Date__c = Utility.dateValue(responseRecMap.get('timecompleted'))
                );
                courseEnrollList.add(tempEnroll);
            }
            // System.debug(JSON.serializePretty(courseEnrollList));
        } else {
            System.debug(responseBody);
        }
        return courseEnrollList;
    }

    //SchooxAPI.getAllCourse();
    public static List<SX_Courses__c> getAllCourse(String status) {
        System.debug('<-----------getAllCourse----------->');
        String url = API_URL + 'courses?';
        if (String.isNotBlank(status)) {
            url += 'status=' + status + '&';
        }
        Map<String, String> responseMap = makeHTTPRequest(ApiType.AllCourse, url, 'GET', null);
        return parseCourseData(responseMap.get('responseBody'));
    }

    public static List<SX_Courses__c> parseCourseData(String responseBody){
        List<Object> responseBodyList = (List<Object>) JSON.deserializeUntyped(responseBody);
        List<SX_Courses__c> courseList = new List<SX_Courses__c>();
        if (!responseBodyList.isEmpty()) {
            for (Object responseRec : responseBodyList) {
                Map<String, Object> responseRecMap = (Map<String, Object>) responseRec;
                SX_Courses__c tempCourse = new SX_Courses__c(
                    Name = (String) responseRecMap.get('title'),
                    SX_Course_ID__c = String.valueOf(responseRecMap.get('id')),
                    SX_Academy_ID__c = String.valueOf(responseRecMap.get('academy_id')),
                    SX_Course_Image_URL__c = (String) responseRecMap.get('image'),
                    SX_Course_URL__c = (String) responseRecMap.get('url'),
                    SX_Course_Description__c = (String) responseRecMap.get('description')
                );
                courseList.add(tempCourse);
            }
            // System.debug(JSON.serializePretty(courseList));
        } else {
            System.debug(responseBody);
        }
        return courseList;
    }

    //SchooxAPI.getAllJob();
    public static List<SX_Job__c> getAllJob() {
        System.debug('<-----------getAllJob----------->');
        String url = API_URL + 'jobs';

        Map<String, String> responseMap = makeHTTPRequest(ApiType.AllJob, url, 'GET', null);
        List<SX_Job__c> jobList = new List<SX_Job__c>();
        try {
            List<Object> responseBodyList = (List<Object>) JSON.deserializeUntyped(responseMap.get('responseBody'));
            if (!responseBodyList.isEmpty()) {
                for (Object responseRec : responseBodyList) {
                    Map<String, Object> responseRecMap = (Map<String, Object>) responseRec;
                    SX_Job__c tempJob = new SX_Job__c(
                        SX_Job_ID__c = String.valueOf(responseRecMap.get('id')),
                        Name = (String) responseRecMap.get('name'),
                        // external_id = responseRecMap.get('external_id'),
                        IsDeletable__c = Utility.booleanValue(responseRecMap.get('deletable'))
                    );
                    jobList.add(tempJob);
                }
                // System.debug(JSON.serializePretty(jobList));
            } else {
                System.debug(responseMap.get('responseBody'));
            }
        } catch (Exception ex) {
            printException(ex);
            throw new AuraHandledException(ex.getMessage());
        }
        return jobList;
    }

    //SchooxAPI.getAllUnits();
    public static Map<String, List<SObject>> getAllUnits() {
        System.debug('<-----------getAllUnit----------->');

        String url = API_URL + 'units?limit=1000';
        Map<String, String> responseMap = makeHTTPRequest(ApiType.AllUnit, url, 'GET', null);
        return parseUnitData(responseMap.get('responseBody'));
    }
    public static Map<String, List<SObject>> parseUnitData(String responseBody){
        List<Object> responseBodyList = (List<Object>) JSON.deserializeUntyped(responseBody);
        List<SX_Unit__c> unitList = new List<SX_Unit__c>();
        Set<SX_Above_Unit__c> aboveUnitList = new Set<SX_Above_Unit__c>();
        List<SX_Role__c> roleList = new List<SX_Role__c>();
        if (!responseBodyList.isEmpty()) {
            for (Object responseRec : responseBodyList) {
                Map<String, Object> responseRecMap = (Map<String, Object>) responseRec;
                SX_Unit__c tempUnit = new SX_Unit__c(
                    SX_ID__c = String.valueOf(responseRecMap.get('id')),
                    Name = (String) responseRecMap.get('name')
                );
                for (Object responseAboveRec : (List<Object>) responseRecMap.get('above_ids')) {
                    Map<String, Object> responseAboveRecMap = (Map<String, Object>) responseAboveRec;
                    SX_Above_Unit__c tempAboveUnit = new SX_Above_Unit__c(
                        SX_ID__c = String.valueOf(responseAboveRecMap.get('id')),
                        Name = (String) responseAboveRecMap.get('name'),
                        Type__c = (String) responseAboveRecMap.get('type')
                    );
                    aboveUnitList.add(tempAboveUnit);
                    SX_Role__c tempRole = new SX_Role__c(
                        Unit__r = new SX_Unit__c(SX_ID__c = tempUnit.SX_ID__c),
                        Above_Unit__r = new SX_Above_Unit__c(SX_ID__c = tempAboveUnit.SX_ID__c),
                        Unit_Above_Unit__c = tempUnit.SX_ID__c + '#' + tempAboveUnit.SX_ID__c
                        
                    );
                    roleList.add(tempRole);
                }
                unitList.add(tempUnit);
            }
        } else {
            System.debug(responseBody);
        }
        Map<String, List<SObject>> objectListByName = new Map<String, List<SObject>>();
        objectListByName.put('Unit', unitList);
        objectListByName.put('Above Unit', new List<SX_Above_Unit__c>(aboveUnitList));
        objectListByName.put('Role', roleList);
        // System.debug(JSON.serializePretty(objectListByName));
        return objectListByName;
    }

    //SchooxAPI.getAllAboveUnits();
    public static List<SX_Above_Unit__c> getAllAboveUnits() {
        System.debug('<-----------getAllUnit----------->');

        String url = API_URL + 'aboves';
        Map<String, String> responseMap = makeHTTPRequest(ApiType.AllAboveUnit, url, 'GET', null);
        return parseAboveData(responseMap.get('responseBody'));
    }
    public static List<SX_Above_Unit__c> parseAboveData(String responseBody){
        List<Object> responseBodyList = (List<Object>) JSON.deserializeUntyped(responseBody);
        List<SX_Above_Unit__c> aboveUnitList = new List<SX_Above_Unit__c>();
        if (!responseBodyList.isEmpty()) {
            for (Object responseRec : responseBodyList) {
                Map<String, Object> responseRecMap = (Map<String, Object>) responseRec;
                SX_Above_Unit__c tempAboveUnit = new SX_Above_Unit__c(
                    SX_ID__c = String.valueOf(responseRecMap.get('id')),
                    Name = (String) responseRecMap.get('name')
                );
                aboveUnitList.add(tempAboveUnit);
            }
        } else {
            System.debug(responseBody);
        }
        System.debug('aboveUnitList.size(): ' + aboveUnitList.size());
        return aboveUnitList;
    }

    //SchooxAPI.createLMSUnit();
    public static SX_Unit__c createLMSUnit(Account acc) {
        System.debug('<-----------createLMSUnit----------->');
        // Account acc = [SELECT Name, SX_Above_Unit_Lookup__c FROM Account WHERE Id = :accountId LIMIT 1];
        UnitData data = new UnitData(acc);
        String url = API_URL + 'units';
        Map<String, String> responseMap = makeHTTPRequest(ApiType.Unit, url, 'POST', JSON.serialize(data));
        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(responseMap.get('responseBody'));
        System.debug(JSON.serializePretty(responseBodyMap));
        if (responseBodyMap.containsKey('error')) {
            throw new AuraHandledException(String.valueOf(responseBodyMap.get('error')));
        }
        SX_Unit__c newUnit = new SX_Unit__c(
            Name = (String) responseBodyMap.get('name'),
            SX_ID__c = String.valueOf(responseBodyMap.get('id'))
        );
        return newUnit;
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
        System.debug(apiMethod + ' ' + type);
        System.debug(request.toString());
        Http http = new Http();
        HttpResponse response;
        if (Test.isRunningTest()) {
            response = testResponse;
        } else {
            response = http.send(request);
        }
        System.debug(response);
        System.debug(response.getBody());
        // System.debug('Status: ' + response.getStatus() + ' StatusCode: ' + response.getStatusCode());
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201 || response.getStatusCode() == 204) {
            apiError = false;
        } else {
            apiError = true;
        }
		System.debug('apiError: ' + apiError);
        return new Map<String, String>{
            'headerLink' => response.getHeader('Link'),
            'responseBody' => response.getBody()
        };
    }

    public static void printException(Exception ex) {
        System.debug('🚀 ~ Exception type caught: ' + ex.getTypeName());    
        System.debug('Message: ' + ex.getMessage());    
        System.debug('Cause: ' + ex.getCause());    // returns null
        System.debug('Line number: ' + ex.getLineNumber());
        System.debug('Stack trace: ' + ex.getStackTraceString());
    }
}