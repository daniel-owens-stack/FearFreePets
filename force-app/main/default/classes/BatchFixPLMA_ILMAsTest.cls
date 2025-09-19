@IsTest
private class BatchFixPLMA_ILMAsTest {

    @IsTest
    static void testBatchCreatesAndUpdatesILMAs() {
        // Create a Business Account
        Account business = new Account(Name = 'Test Business');
        insert business;

        // Get Person Account RecordType Id
        Id personRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;

        // Create two Person Accounts under the Business
        Account member1 = new Account(
            LastName = 'Member One',
            RecordTypeId = personRT,
            Business__c = business.Id
        );
        Account member2 = new Account(
            LastName = 'Member Two',
            RecordTypeId = personRT,
            Business__c = business.Id
        );
        insert new List<Account>{ member1, member2 };

        // Create a Membership record
        Membership__c membership = new Membership__c(Name = 'Test Membership');
        insert membership;

        // Create a PLMA (Active) with start date (formula will derive expiration)
        Practice_Level_Membership_Assignment__c plma = new Practice_Level_Membership_Assignment__c(
            Business_Account__c = business.Id,
            Membership__c = membership.Id,
            Status__c = 'Active',
            Start_Date__c = Date.today()
        );
        insert plma;

        // Member1 has NO ILMA → should get created
        // Member2 has an ILMA but no PLMA lookup → should get updated
        Account_Membership__c ilma2 = new Account_Membership__c(
            Account_Id__c = member2.Id,
            Membership__c = membership.Id,
            Status__c = 'Active'
            // Practice_Level_Membership_Assignment__c left null
        );
        insert ilma2;

        Test.startTest();
        Database.executeBatch(new BatchFixPLMA_ILMAs(), 50);
        Test.stopTest();

        // Verify Member1 got a new ILMA
        List<Account_Membership__c> member1ILMAs = [
            SELECT Id, Membership__c, Practice_Level_Membership_Assignment__c
            FROM Account_Membership__c
            WHERE Account_Id__c = :member1.Id
        ];
        System.assertEquals(1, member1ILMAs.size(), 'Member1 should now have an ILMA');
        System.assertEquals(plma.Id, member1ILMAs[0].Practice_Level_Membership_Assignment__c, 'Member1 ILMA should link to PLMA');

        // Verify Member2’s ILMA was updated
        Account_Membership__c updatedILMA2 = [
            SELECT Id, Practice_Level_Membership_Assignment__c
            FROM Account_Membership__c
            WHERE Id = :ilma2.Id
        ];
        System.assertEquals(plma.Id, updatedILMA2.Practice_Level_Membership_Assignment__c, 'Member2 ILMA should now link to PLMA');
    }

    @IsTest
    static void testBatchDoesNothingIfAlreadyLinked() {
        // Create Business + Member
        Account business = new Account(Name = 'Biz 2');
        insert business;

        Id personRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;
        Account member = new Account(
            LastName = 'Already Linked',
            RecordTypeId = personRT,
            Business__c = business.Id
        );
        insert member;

        // Create a Membership record
        Membership__c membership = new Membership__c(Name = 'Test Membership 2');
        insert membership;

        // PLMA
        Practice_Level_Membership_Assignment__c plma = new Practice_Level_Membership_Assignment__c(
            Business_Account__c = business.Id,
            Membership__c = membership.Id,
            Status__c = 'Active',
            Start_Date__c = Date.today().addYears(-1)
        );
        insert plma;

        // ILMA already linked
        Account_Membership__c ilma = new Account_Membership__c(
            Account_Id__c = member.Id,
            Membership__c = membership.Id,
            Account_Assignment_Date__c = Date.today().addYears(-1),
            Status__c = 'Active',
            Practice_Level_Membership_Assignment__c = plma.Id
        );
        insert ilma;

        Test.startTest();
        Database.executeBatch(new BatchFixPLMA_ILMAs(), 50);
        Test.stopTest();

        // Should still only be 1 ILMA, same Id
        List<Account_Membership__c> ilmAs = [
            SELECT Id, Practice_Level_Membership_Assignment__c
            FROM Account_Membership__c
            WHERE Account_Id__c = :member.Id
        ];
        System.assertEquals(1, ilmAs.size(), 'Should still only have one ILMA');
        System.assertEquals(plma.Id, ilmAs[0].Practice_Level_Membership_Assignment__c, 'ILMA remains linked');
    }
}