/*
 * Last Modified: 2024-09-04 19:31:01
 */

/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-09-12 23:06:27
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:38:22
 * @ Description: Test class is SX_LMS_UsersTriggerHelper_Test
 */

public with sharing class SX_LMS_UsersTriggerHelper {
    public static Boolean hasExecuted = false;
    public static Integer executingStack = 0;
    private Boolean m_isExecuting = false; 
    private Integer BatchSize = 0; 
    public static Boolean isError = false; 
    private Boolean isTriggerInsert = false; 
    private Boolean isTriggerUpdate = false; 
    private Boolean isTriggerDelete = false; 
    private Boolean isTriggerBefore = false; 
    private Boolean isTriggerAfter = false; 
    public SX_LMS_UsersTriggerHelper(Boolean isExecuting, Integer size) {
        executingStack++;
        m_isExecuting = isExecuting;
        BatchSize = size;
    }

    public void handleTrigger(List<SX_LMS_User__c> newSXUserList, Map<Id, SX_LMS_User__c> newSXUserMap, List<SX_LMS_User__c> oldSXUserList, Map<Id, SX_LMS_User__c> oldSXUserMap, System.TriggerOperation triggerEvent ) { 
        try { 
            System.debug('triggerEvent SX_LMS_UsersTriggerHelper: ' + triggerEvent + ' ' + executingStack);
            if (executingStack < 3) {
                switch on triggerEvent {
                    when BEFORE_INSERT {
                        isTriggerBefore = true;
                        isTriggerInsert = true;
                        checkSXUser(newSXUserList);
                    }
                    when AFTER_INSERT {
                        isTriggerAfter = true;
                        isTriggerInsert = true;
                        createSXUser(newSXUserList, oldSXUserMap);
                    }
                    when BEFORE_UPDATE {
                        isTriggerBefore = true;
                        isTriggerUpdate = true;
                        handleLMSUser(newSXUserList, oldSXUserMap);
                    }
                    when BEFORE_DELETE {
                        isTriggerBefore = true;
                        isTriggerDelete = true;
                        deleteSXUser(oldSXUserList, oldSXUserMap);
                    }
                    when else {
                        //TODO: do nothing
                        System.debug('Nothing');
                    }
                }
            }
            
        } catch (Exception ex) {
            Utility.printException(ex);
        }
    }

    private static void checkSXUser(List<SX_LMS_User__c> newSXUserList) {
        System.debug('----------- checkSXUser Start -----------');
        System.debug('newSXUserList: ' + newSXUserList.size());
        System.debug(JSON.serializePretty(newSXUserList));
        Set<Id> userIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for (SX_LMS_User__c newStudent : newSXUserList) {
            if (String.isNotBlank(newStudent.SF_User__c)) {
                userIds.add(newStudent.SF_User__c);
            } else {
                contactIds.add(newStudent.SF_Contact__c);
            }
        }

        Map<Id, Id> lmsUserByStudentId = new Map<Id, Id>();
        for (SX_LMS_User__c lmsRec : [
            SELECT SF_User__c, SF_Contact__c
            FROM SX_LMS_User__c 
            WHERE SF_User__c IN :userIds OR SF_Contact__c IN :contactIds
        ]){
            if (String.isNotBlank(lmsRec.SF_User__c)) {
                lmsUserByStudentId.put(lmsRec.SF_User__c, lmsRec.Id);
            } else {
                lmsUserByStudentId.put(lmsRec.SF_Contact__c, lmsRec.Id);
            }
        }
        System.debug('lmsUserByStudentId: ' + lmsUserByStudentId.size());
        System.debug(JSON.serializePretty(lmsUserByStudentId));
        for (SX_LMS_User__c newStudent : newSXUserList) {
            if (lmsUserByStudentId.containsKey(newStudent.SF_User__c)) {
                newStudent.addError('Selected User already exists in SX LMS User.');
            }
            if (lmsUserByStudentId.containsKey(newStudent.SF_Contact__c)) {
                newStudent.addError('Selected Contact already exists in SX LMS User.');
            }
        }
        System.debug('----------- checkSXUser End -----------');
    }

    private static void createSXUser(List<SX_LMS_User__c> newSXUserList, Map<Id, SX_LMS_User__c> oldSXUserMap) {
        System.debug('----------- createSXUser Start -----------');
        Set<Id> userIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for (SX_LMS_User__c newStudent : newSXUserList) {
            if (String.isNotBlank(newStudent.SX_User_ID__c)) {
                continue;
            }
            if (String.isNotBlank(newStudent.SF_User__c)) {
                userIds.add(newStudent.SF_User__c);
            } else {
                contactIds.add(newStudent.SF_Contact__c);
            }
        }
        Map<Id, String> emailById = new Map<Id, String>();
        for (Contact conRec : [SELECT Email FROM Contact WHERE Id IN :contactIds]) emailById.put(conRec.Id, conRec.Email);
        for (User userRec : [SELECT Email FROM User WHERE Id IN :userIds]) emailById.put(userRec.Id, userRec.Email);
        System.debug(JSON.serializePretty(emailById));
    
        Set<Id> studentIds = new Set<Id>();
        for (SX_LMS_User__c newStudent : newSXUserList) {
            if (String.isNotBlank(newStudent.SX_User_ID__c)) {
                continue;
            }
            if (String.isNotBlank(newStudent.SF_User__c)) {                
                if (String.isBlank(emailById.get(newStudent.SF_User__c))) {
                    newStudent.addError('Selected User doesn\'t have any email address.');
                } else {
                    studentIds.add(newStudent.SF_User__c);
                }
            } else {
                if (String.isBlank(emailById.get(newStudent.SF_Contact__c))) {
                    newStudent.addError('Selected Contact doesn\'t have any email address.');
                } else {
                    studentIds.add(newStudent.SF_Contact__c);
                }
            }
        }
        System.debug(JSON.serializePretty(studentIds));
        if (!studentIds.isEmpty()) {
            executeCreateAPI(studentIds);
        }        
        System.debug('----------- createSXUser End -----------');
    }

    private static void deleteSXUser(List<SX_LMS_User__c> oldSXUserList, Map<Id, SX_LMS_User__c> oldSXUserMap) {
        System.debug('----------- deleteSXUser Start -----------');
        List<SObject> studentList = new List<SObject>();
        Set<String> deactivatedStudentIds = new Set<String>();
        for (SX_LMS_User__c oldStudent : oldSXUserList) {
            Id recordId = String.isNotBlank(oldStudent.SF_User__c) ? oldStudent.SF_User__c : oldStudent.SF_Contact__c;
            SObject student = recordId.getSobjectType().newSObject(recordId);
            student.put('SX_User_ID__c', '');
            student.put('SX_Active_User__c', false);
            studentList.add(student);
            if (String.isNotBlank(oldStudent.SX_User_ID__c)) {
                deactivatedStudentIds.add(oldStudent.SX_User_ID__c);
            }
        }
        System.debug(JSON.serializePretty(deactivatedStudentIds));
        if (!deactivatedStudentIds.isEmpty()) {
            executeDeleteAPI(deactivatedStudentIds);
        }
        update studentList;
        System.debug('----------- deleteSXUser End -----------');
    }

    private static void handleLMSUser(List<SX_LMS_User__c> newSXUserList, Map<Id, SX_LMS_User__c> oldSXUserMap) {
        System.debug('----------- handleLMSUser Start -----------');
        List<SObject> studentList = new List<SObject>();
        Set<String> deactivatedStudentIds = new Set<String>();
        Set<String> reactivatedStudentIds = new Set<String>();
        for (SX_LMS_User__c newStudent : newSXUserList) {
            SX_LMS_User__c oldStudent = oldSXUserMap.get(newStudent.Id);
            Id recordId = String.isNotBlank(newStudent.SF_User__c) ? newStudent.SF_User__c : newStudent.SF_Contact__c;
            SObject student = recordId.getSobjectType().newSObject(recordId);
            student.put('SX_Active_User__c', newStudent.SX_Active_User__c);
            studentList.add(student);
            if (String.isNotBlank(newStudent.SX_User_ID__c) && newStudent.SX_Active_User__c != oldStudent.SX_Active_User__c) {
                if (newStudent.SX_Active_User__c) {
                    student.put('SX_User_ID__c', newStudent.SX_User_ID__c);
                    reactivatedStudentIds.add(newStudent.SX_User_ID__c);
                } else {
                    deactivatedStudentIds.add(newStudent.SX_User_ID__c);
                }
            }
        }
        System.debug('deactivatedStudentIds');
        System.debug(JSON.serializePretty(deactivatedStudentIds));
        if (!deactivatedStudentIds.isEmpty()) {
            executeDeleteAPI(deactivatedStudentIds);
        }
        System.debug('reactivatedStudentIds');
        System.debug(JSON.serializePretty(reactivatedStudentIds));
        if (!reactivatedStudentIds.isEmpty()) {
            executeReactivateAPI(reactivatedStudentIds);
        }
        update studentList;
        System.debug('----------- handleLMSUser End -----------');
    }

    @Future(Callout=true)
    private static void executeCreateAPI(Set<Id> studentIds){
        if (!Test.isRunningTest()) {
            SchooxAPI.createLMSUsers(studentIds);
        }        
    }

    @Future(Callout=true)
    private static void executeDeleteAPI(Set<String> studentIds){
        for (String studentId : studentIds) {
            SchooxAPI.removeLMSUser(studentId);
        }
    }
    @Future(Callout=true)
    private static void executeReactivateAPI(Set<String> studentIds){
        for (String studentId : studentIds) {
            SchooxAPI.reActivateLMSUser(studentId);
        }
    }
}