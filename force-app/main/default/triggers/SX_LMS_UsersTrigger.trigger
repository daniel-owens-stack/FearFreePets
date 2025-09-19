/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2024-07-17 10:01:38
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:37:45
 * @ Description:
 */

trigger SX_LMS_UsersTrigger on SX_LMS_User__c (before insert, after insert, before update, before delete) {
    SX_LMS_UsersTriggerHelper lmsHelper = new SX_LMS_UsersTriggerHelper(Trigger.isExecuting, Trigger.size);
    lmsHelper.handleTrigger(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap, Trigger.operationType);
}