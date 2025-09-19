/*
 * Last Modified: 2024-09-04 00:40:09
 */

/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2024-08-16 10:22:56
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:37:41
 * @ Description: Test class is  AccountTriggerHelper_Test
 */
trigger SXAccountTrigger on Account (after update) {
    AccountTriggerHelper accHelper = new AccountTriggerHelper(Trigger.isExecuting, Trigger.size);
    accHelper.handleTrigger(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap, Trigger.operationType);
}