/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-10-11 16:04:22
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:42:44
 * @ Description: Test class is GetUserCourseBatch_Test
 * new GetUserCourseBatch().execute(null);
 * Id batchJobId = Database.executeBatch(new GetUserCourseBatch(), 5);
 * System.schedule('Schoox User Courses Sync', '0 0 06,18 ? * MON-FRI', new GetUserCourseBatch());
 */

public without sharing class GetUserCourseBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Schedulable{
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Name, SX_User_ID__c, SF_Contact__c, SF_User__c, RecordType.DeveloperName ';
        query += 'FROM SX_LMS_User__c ';
        query += 'WHERE ';
        query += 'SX_User_ID__c != null';
        // query += ' AND Id IN (SELECT Student_ID__c FROM SX_Enrollment__c)';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SX_LMS_User__c> lmsUserList) {
        List<SX_Enrollment__c> enrollmentListToUpdate = new List<SX_Enrollment__c>();
        for (SX_LMS_User__c lmsUser : lmsUserList) {
            List<SX_Enrollment__c> enrollmentList = SchooxAPI.getUserCourse(lmsUser.SX_User_ID__c);
            // System.debug(JSON.serializePretty(enrollmentList));
            if (lmsUser.RecordType.DeveloperName == 'External') {
                for (SX_Enrollment__c enrollment : enrollmentList) {
                    enrollment.SF_Contact_Lookup__c = lmsUser.SF_Contact__c;
                }
            } else {
                for (SX_Enrollment__c enrollment : enrollmentList) {
                    enrollment.SF_User_Lookup__c = lmsUser.SF_User__c;
                }
            }
            System.debug(JSON.serializePretty(enrollmentList));
            enrollmentListToUpdate.addAll(enrollmentList);
        }
        if (!enrollmentListToUpdate.isEmpty()) {
            upsert enrollmentListToUpdate Student_Course_Id__c;
            System.debug(enrollmentListToUpdate.size() + ' Enrollment updated');
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Execution Finish');
    }

    public void execute(SchedulableContext sc) {
        Id batchJobId = Database.executeBatch(new GetUserCourseBatch(), 90);
        System.debug('batchJobId: ' + batchJobId);
    }
}