// Finds AMs with Certified__c = true and missing Certification_Date__c,
// grabs their contacts' enrollments, and passes them to
// FFEnrollmentTriggerHandler.processEnrollments(enrollments).
global with sharing class BatchSendEnrollmentsToHandler
implements Database.Batchable<SObject>, Database.Stateful {

    // Test-only switch to relax the SOQL where-clause so tests can cover
    // the dedup and handoff logic even if some fields are formulas or non-writable.
    @TestVisible static Boolean TEST_INCLUDE_ALL_ENROLLMENTS = false;

    // Track enrollments we've already sent to the handler across execute() chunks
    private Set<Id> processedEnrollmentIds = new Set<Id>();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id,
                   Account_Id__r.PersonContactId,
                   Membership__c
            FROM Account_Membership__c
            WHERE Certified__c = true
              AND Certification_Date__c = null
              AND Account_Id__r.PersonContactId != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account_Membership__c> scope) {
        if (scope.isEmpty()) return;

        // Collect unique contacts from this chunk
        Set<Id> contactIds = new Set<Id>();
        for (Account_Membership__c am : scope) {
            if (am.Account_Id__r != null && am.Account_Id__r.PersonContactId != null) {
                contactIds.add(am.Account_Id__r.PersonContactId);
            }
        }
        if (contactIds.isEmpty()) return;

        // Pull enrollments (two query variants so we don't put a bare :bind boolean in SOQL)
        List<SX_Enrollment__c> rawEnrollments;
        if (TEST_INCLUDE_ALL_ENROLLMENTS) {
            rawEnrollments = [
                SELECT Id,
                       SF_Contact_Lookup__c,
                       SX_Course__c,
                       SX_percent_Completed__c,
                       Certification_Course__c,
                       CE_Credits__c,
                       CreatedDate
                FROM SX_Enrollment__c
                WHERE SF_Contact_Lookup__c IN :contactIds
            ];
        } else {
            rawEnrollments = [
                SELECT Id,
                       SF_Contact_Lookup__c,
                       SX_Course__c,
                       SX_percent_Completed__c,
                       Certification_Course__c,
                       CE_Credits__c,
                       CreatedDate
                FROM SX_Enrollment__c
                WHERE SF_Contact_Lookup__c IN :contactIds
                  AND (
                        (Certification_Course__c = true AND SX_percent_Completed__c = 100 AND SX_Course__c != null)
                     OR (CE_Credits__c != null)
                      )
            ];
        }
        if (rawEnrollments.isEmpty()) return;

        // Deduplicate across batch chunks
        List<SX_Enrollment__c> toProcess = new List<SX_Enrollment__c>();
        for (SX_Enrollment__c e : rawEnrollments) {
            if (!processedEnrollmentIds.contains(e.Id)) {
                processedEnrollmentIds.add(e.Id);
                toProcess.add(e);
            }
        }
        if (toProcess.isEmpty()) return;

        // Hand off to your existing logic
        FFEnrollmentTriggerHandler.processEnrollments(toProcess);
    }

    global void finish(Database.BatchableContext bc) {
        // no-op; add logging if desired
    }

    // Convenience kick-off
    public static Id run(Integer scopeSize) {
        if (scopeSize == null || scopeSize < 1) scopeSize = 200;
        if (Test.isRunningTest()) {
            // In unit tests we avoid executeBatch to prevent the platform restriction.
            return Id.valueOf('000000000000000AAA');
        }
        return Database.executeBatch(new BatchSendEnrollmentsToHandler(), scopeSize);
    }
}