trigger FFEnrollmentTrigger on SX_Enrollment__c (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            FFEnrollmentTriggerHandler.processEnrollments(Trigger.new);
        }
    }
}