/**
 * @ Author: GRidowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-09-18 20:55:43
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:41:11
 * @ Description: Test class is Enrollment_CTRL_Test
 */

public with sharing class Enrollment_CTRL {
    @AuraEnabled(Cacheable=true)
    public static List<SX_Courses__c> getCourses(Id recordId, String searchTerm) {
        System.debug(recordId);
        System.debug(searchTerm);
        searchTerm = '%' + searchTerm + '%';
        if (recordId.getSobjectType() == Schema.Contact.getSObjectType()) {
            return [
                SELECT 
                    Name, SX_Course_ID__c, SX_Course_Image_URL__c, SX_Course_URL__c, SX_Course_Active__c, SX_Course_Description__c
                FROM SX_Courses__c
                WHERE SX_Course_Active__c = TRUE  AND Name LIKE :searchTerm AND
                    Id NOT IN (SELECT SX_Course__c FROM SX_Enrollment__c WHERE SF_Contact_Lookup__c = :recordId)
            ];
        } else {
            return [
                SELECT 
                    Name, SX_Course_ID__c, SX_Course_Image_URL__c, SX_Course_URL__c, SX_Course_Active__c, SX_Course_Description__c
                FROM SX_Courses__c
                WHERE SX_Course_Active__c = TRUE  AND Name LIKE :searchTerm AND
                    Id NOT IN (SELECT SX_Course__c FROM SX_Enrollment__c WHERE Student_ID__c = :recordId)
            ];
        }
    }

    @AuraEnabled(Cacheable=true)
    public static List<SX_LMS_User__c> getStudents(Id recordId, String searchTerm) {
        System.debug(searchTerm);
        searchTerm = '%' + searchTerm + '%';
        return [
            SELECT 
                Name, SX_User_ID__c, LMS_User__c, LMS_User_Name__c, RecordType.Name
            FROM SX_LMS_User__c
            WHERE   SX_Active_User__c = true AND LMS_User_Name__c LIKE :searchTerm AND
                    Id NOT IN (SELECT Student_ID__c FROM SX_Enrollment__c WHERE SX_Course__c = :recordId)
            ORDER BY LMS_User_Name__c
        ];
    }

    @AuraEnabled(Cacheable=false)
    public static Map<String, Map<String, String>> enrollCourses(String studentId, List<String> courseIds) {
        System.debug('studentId: ' + studentId);
        System.debug(JSON.serializePretty(courseIds));
        SX_LMS_User__c lmsUser = [SELECT SF_User__c, SF_Contact__c, RecordType.DeveloperName FROM SX_LMS_User__c WHERE SX_User_ID__c = :studentId LIMIT 1];
        Map<String, Map<String, String>> resultMap = SchooxAPI.assignCourses(studentId, courseIds);
        List<SX_Enrollment__c> enrollmentList = new List<SX_Enrollment__c>();
        for (Map<String, String> result : resultMap.values()) {
            String courseId = result.values()[0];
            String message = result.values()[1];
            if (message == 'User successfully assigned') {
                SX_Enrollment__c tempEnrollment = new SX_Enrollment__c(
                        Student_Course_Id__c = studentId + '#' + courseId,
                        Student_ID__r = new SX_LMS_User__c(SX_User_ID__c = studentId),
                        SX_Course__r = new SX_Courses__c(SX_Course_ID__c = courseId),
                        SX_percent_Completed__c = 0,
                        SX_Enrollment_Date__c = Date.today()
                );
                if (lmsUser.RecordType.DeveloperName == 'External') {
                    tempEnrollment.SF_Contact_Lookup__c = lmsUser.SF_Contact__c;
                } else {
                    tempEnrollment.SF_User_Lookup__c = lmsUser.SF_User__c;
                }
                enrollmentList.add(tempEnrollment);
            }
        }
        System.debug(JSON.serializePretty(enrollmentList));
        upsert enrollmentList Student_Course_Id__c;
        return resultMap;
    }

    @AuraEnabled(Cacheable=false)
    public static String enrollStudent(String courseId, String studentId) {
        return SchooxAPI.assignCourse(courseId, studentId);
    }

    @AuraEnabled(Cacheable=false)
    public static List<SX_Enrollment__c> updateEnrollment(String courseId, List<String> studentIds) {
        System.debug('<--------- updateEnrollment --------->');
        Map<String, SX_LMS_User__c> lmsUserById = new Map<String, SX_LMS_User__c>();
        for (SX_LMS_User__c lmsUser : [
            SELECT SX_User_ID__c, SF_User__c, SF_Contact__c, RecordType.DeveloperName
            FROM SX_LMS_User__c
            WHERE SX_User_ID__c IN :studentIds
        ]) {
            lmsUserById.put(lmsUser.SX_User_ID__c, lmsUser);
        }
        List<SX_Enrollment__c> enrollmentList = new List<SX_Enrollment__c>();
        for (String studentId : studentIds) {
            SX_Enrollment__c tempEnrollment = new SX_Enrollment__c(
                Student_Course_Id__c = studentId + '#' + courseId,
                Student_ID__r = new SX_LMS_User__c(SX_User_ID__c = studentId),
                SX_Course__r = new SX_Courses__c(SX_Course_ID__c = courseId),
                SX_percent_Completed__c = 0,
                SX_Enrollment_Date__c = Date.today()

            );
            SX_LMS_User__c lmsUser = lmsUserById.get(studentId);
            if (lmsUser.RecordType.DeveloperName == 'External') {
                tempEnrollment.SF_User_Lookup__c = lmsUser.SF_User__c;
            } else {
                tempEnrollment.SF_Contact_Lookup__c = lmsUser.SF_Contact__c;
            }
            enrollmentList.add(tempEnrollment);
        }
        System.debug(JSON.serializePretty(enrollmentList));
        upsert enrollmentList Student_Course_Id__c;
        return enrollmentList;
    }
}