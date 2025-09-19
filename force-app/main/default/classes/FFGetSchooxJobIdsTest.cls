@IsTest
private class FFGetSchooxJobIdsTest {

    // Helper to create a Person Account (skip test if PAs aren’t enabled)
    private static Account createPersonAccount(String last, String email) {
        List<RecordType> paRts = [
            SELECT Id, IsPersonType
            FROM RecordType
            WHERE SObjectType = 'Account' AND IsPersonType = true
            LIMIT 1
        ];
        if (paRts.isEmpty()) return null;

        Account pa = new Account(
            RecordTypeId = paRts[0].Id,
            LastName     = last,
            PersonEmail  = email
        );
        insert pa;
        pa = [SELECT Id, IsPersonAccount, PersonContactId FROM Account WHERE Id = :pa.Id];
        return (pa.IsPersonAccount && pa.PersonContactId != null) ? pa : null;
    }

    @IsTest
    static void test_getForContacts_mapsActiveMemberships() {
        // Arrange: two PAs, with different membership combinations
        Account pa1 = createPersonAccount('One', 'one@test.com');
        Account pa2 = createPersonAccount('Two', 'two@test.com');
        System.assert(pa1 != null && pa2 != null, 'Person Accounts must be enabled for this test.');

        Contact c1 = [SELECT Id FROM Contact WHERE Id = :pa1.PersonContactId LIMIT 1];
        Contact c2 = [SELECT Id FROM Contact WHERE Id = :pa2.PersonContactId LIMIT 1];

        // Membership catalog
        Membership__c mA = new Membership__c(Name = 'Mapped A');
        Membership__c mB = new Membership__c(Name = 'Mapped B');
        Membership__c mUnmapped = new Membership__c(Name = 'Unmapped');
        insert new List<Membership__c>{ mA, mB, mUnmapped };

        // Provide the job map to the utility (covers the “missing map” complaint)
        FFGetSchooxJobIds.setTestMembershipToJobId(new Map<Id, Integer>{
            mA.Id => 1001,
            mB.Id => 2002
            // mUnmapped intentionally missing
        });

        // Active memberships for pa1: A + B (both mapped)
        insert new Account_Membership__c(Account_Id__c = pa1.Id, Membership__c = mA.Id, Status__c = 'Active');
        insert new Account_Membership__c(Account_Id__c = pa1.Id, Membership__c = mB.Id, Status__c = 'Active');

        // pa2: one active unmapped + one inactive mapped (both should be ignored)
        insert new Account_Membership__c(Account_Id__c = pa2.Id, Membership__c = mUnmapped.Id, Status__c = 'Active');
        insert new Account_Membership__c(Account_Id__c = pa2.Id, Membership__c = mA.Id, Status__c = 'Complete');

        // Act
        Map<Id, List<Integer>> byContact =
            FFGetSchooxJobIds.getForContacts(new Set<Id>{ c1.Id, c2.Id });

        // Assert
        System.assertNotEquals(null, byContact, 'Result map should not be null');

        // c1 should have both job IDs
        System.assertEquals(true, byContact.containsKey(c1.Id), 'c1 should be present');
        System.assertEquals(
            new Set<Integer>{1001, 2002},
            new Set<Integer>(byContact.get(c1.Id)),
            'c1 should aggregate both mapped jobs'
        );

        // c2 should be absent or empty (unmapped active + inactive mapped)
        if (byContact.containsKey(c2.Id)) {
            System.assertEquals(0, byContact.get(c2.Id).size(),
                'c2 should not have any job IDs (unmapped or inactive memberships only)');
        }
    }

    @IsTest
    static void test_getForContacts_handlesEmptyAndNonPAContacts() {
        // Empty input → empty result
        Map<Id, List<Integer>> emptyRes = FFGetSchooxJobIds.getForContacts(new Set<Id>());
        System.assertEquals(0, emptyRes.size(), 'Empty input should return empty map');

        // Non-PA contact should not be mapped
        Account biz = new Account(Name = 'Biz');
        insert biz;
        Contact c = new Contact(LastName = 'X', AccountId = biz.Id, Email = 'x@test.com');
        insert c;

        Map<Id, List<Integer>> res = FFGetSchooxJobIds.getForContacts(new Set<Id>{ c.Id });
        System.assertEquals(0, res.size(),
            'Non-PA contact should not resolve to a Person Account mapping');
    }
}