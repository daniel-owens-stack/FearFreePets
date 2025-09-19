/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-09-06 22:03:04
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:38:54
 * @ Description: Test class is ContactCourses_CTRL_Test
 */

public with sharing class ContactCourses_CTRL {
    public ContactCourses_CTRL() {
    }

    @AuraEnabled( Cacheable=false )
    public static Integer getCourse(Id contactId, String sxUserId) {
        System.debug('contactId: ' + contactId);
        System.debug('sxUserId: ' + sxUserId);
        List<SX_Enrollment__c> enrollmentList = SchooxAPI.getUserCourse(sxUserId);

        for (SX_Enrollment__c courseEnroll : enrollmentList) {
            courseEnroll.SF_Contact_Lookup__c = contactId;
        }
        System.debug('Size: ' + enrollmentList.size());
        System.debug(JSON.serializePretty(enrollmentList));
        if (!enrollmentList.isEmpty()) {
            upsert enrollmentList Student_Course_Id__c;
        }
        return enrollmentList.size();
    }

    @AuraEnabled( Cacheable=false )
    public static String createUser(Id contactId) {
        SX_LMS_User__c lmsUser = SchooxAPI.createLMSUser(contactId, null);
        System.debug(JSON.serializePretty(lmsUser));
        insert lmsUser;
        Contact lmsCon = new Contact(
            Id = contactId,
            SX_LMS_User__c = lmsUser.Id,
            SX_User_Id__c = lmsUser.SX_User_ID__c,
            SX_Active_User__c = lmsUser.SX_Active_User__c
        );
        update lmsCon;
        System.debug(JSON.serializePretty(lmsCon));
        return lmsUser.SX_User_ID__c;
    }
}