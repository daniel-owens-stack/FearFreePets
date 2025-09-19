public without sharing class FFGetSchooxJobIds {

    /**
     * Map of Membership__c.Id -> Schoox Job Id (Integer).
     * In prod, populate from your permanent mapping.
     */
    private static final Map<Id, Integer> DEFAULT_MEMBERSHIP_TO_JOB = new Map<Id, Integer>{
        'a04TR00000GtVQEYA3' => 1957821,
        'a04TR00000GtVQFYA3' => 1957823,
        'a04TR00000GtVQGYA3' => 1957822,
        'a04TR00000GtVQDYA3' => 1957825,
        'a04TR00000GtVQCYA3' => 1937025,
        'a04TR00000GtVQIYA3' => 2213608,
        'a04TR00000GtVQJYA3' => 1957820,
        'a04TR00000GtVQKYA3' => 2213609
    };

    // Test override hook so unit tests can inject their own membership mapping.
    @TestVisible private static Map<Id, Integer> testOverrideMembershipToJob;

    /** Allow tests to override mapping. */
    @TestVisible
    public static void setTestMembershipToJobId(Map<Id, Integer> overrideMap) {
        testOverrideMembershipToJob = overrideMap == null ? null : new Map<Id,Integer>(overrideMap);
    }

    /** Internal getter with test-awareness. */
    private static Map<Id, Integer> getMembershipToJobMap() {
        if (Test.isRunningTest() && testOverrideMembershipToJob != null) {
            return testOverrideMembershipToJob;
        }
        return DEFAULT_MEMBERSHIP_TO_JOB;
    }

    /**
     * Return Account.Id -> List<Integer> Schoox job IDs
     * for the given set of *Person Account* Ids, based on ACTIVE Account_Membership__c.
     *
     * @param personAccountIds Set of Account Ids (Person Accounts)
     */
    public static Map<Id, List<Integer>> getForAccounts(Set<Id> personAccountIds) {
        Map<Id, List<Integer>> accToJobs = new Map<Id, List<Integer>>();
        if (personAccountIds == null || personAccountIds.isEmpty()) return accToJobs;

        Map<Id, Integer> memToJob = getMembershipToJobMap();

        for (Account_Membership__c am : [
            SELECT Account_Id__c, Membership__c, Status__c
            FROM Account_Membership__c
            WHERE Account_Id__c IN :personAccountIds
        ]) {
            if (am.Status__c == 'Active' && memToJob.containsKey(am.Membership__c)) {
                if (!accToJobs.containsKey(am.Account_Id__c)) {
                    accToJobs.put(am.Account_Id__c, new List<Integer>());
                }
                accToJobs.get(am.Account_Id__c).add(memToJob.get(am.Membership__c));
            }
        }
        return accToJobs;
    }

    /**
     * Convenience: given Contact Ids for Person Accounts’ PersonContactId,
     * return Contact.Id -> List<Integer> job IDs by internally mapping through the parent Account.
     */
    public static Map<Id, List<Integer>> getForContacts(Set<Id> personContactIds) {
        Map<Id, List<Integer>> contactToJobs = new Map<Id, List<Integer>>();
        if (personContactIds == null || personContactIds.isEmpty()) return contactToJobs;

        // Map contacts -> parent Account (Person Account)
        Map<Id, Id> contactToAccount = new Map<Id, Id>();
        for (Account pa : [
            SELECT Id, PersonContactId
            FROM Account
            WHERE IsPersonAccount = true AND PersonContactId IN :personContactIds
        ]) {
            contactToAccount.put(pa.PersonContactId, pa.Id);
        }
        if (contactToAccount.isEmpty()) return contactToJobs;

        Map<Id, List<Integer>> jobsByAccount = getForAccounts(new Set<Id>(contactToAccount.values()));
        for (Id cId : personContactIds) {
            Id accId = contactToAccount.get(cId);
            if (accId != null && jobsByAccount.containsKey(accId)) {
                contactToJobs.put(cId, jobsByAccount.get(accId));
            }
        }
        return contactToJobs;
    }
}