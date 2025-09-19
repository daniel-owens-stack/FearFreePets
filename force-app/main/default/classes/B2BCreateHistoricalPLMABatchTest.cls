@isTest
public class B2BCreateHistoricalPLMABatchTest {

    @testSetup
    static void setupData() {
        Id businessRecordTypeId;
        Id personRecordTypeId;

        if (Schema.SObjectType.Account.getRecordTypeInfosByName().containsKey('Business Account')) {
            businessRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        }

        if (Schema.SObjectType.Account.getRecordTypeInfosByName().containsKey('Person Account')) {
            personRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        }

        Account businessAcct = new Account(Name = 'Test Business');
        if (businessRecordTypeId != null) {
            businessAcct.RecordTypeId = businessRecordTypeId;
        }
        insert businessAcct;

        Account personAcct = new Account(
            FirstName = 'TestFFP',
            LastName = 'Account',
            PersonEmail = 'test.123+1@gmail.com'
        );
        if (personRecordTypeId != null) {
            personAcct.RecordTypeId = personRecordTypeId;
        }
        insert personAcct;

        Membership__c membership1 = new Membership__c(Name = 'Test Membership 1', Membership_Level__c = 'Practice');
        Membership__c membership2 = new Membership__c(Name = 'Test Membership 2', Membership_Level__c = 'Practice');
        insert new List<Membership__c>{ membership1, membership2 };

        List<Account_Membership__c> ilmAs = new List<Account_Membership__c>{
            new Account_Membership__c(
                Membership__c = membership1.Id,
                Start_Date__c = Date.today().addYears(-1),
                Status__c = 'Active',
                Account_Id__c = personAcct.Id
            ),
            new Account_Membership__c(
                Membership__c = membership2.Id,
                Start_Date__c = Date.today().addMonths(-6),
                Status__c = 'Active',
                Account_Id__c = personAcct.Id
            )
        };
        insert ilmAs;

        personAcct.Business__c = businessAcct.Id;
        update personAcct;
    }

    @isTest
    static void testBatchCreatesPLMAs() {
        Test.startTest();
        B2BCreateHistoricalPLMABatch batch = new B2BCreateHistoricalPLMABatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
    }

    @isTest
    static void testBatchSkipsIfPLMAExists() {
        Account acct = [SELECT Id, Business__c FROM Account WHERE Business__c != null LIMIT 1];
        Membership__c membership = [SELECT Id FROM Membership__c LIMIT 1];

        Practice_Level_Membership_Assignment__c existingPlma = new Practice_Level_Membership_Assignment__c(
            Membership__c = membership.Id,
            Business_Account__c = acct.Business__c,
            Start_Date__c = Date.today().addYears(-2),
            Status__c = 'Active',
            Welcome_Kit_Status__c = 'Unavailable',
            Need_Historical_Review__c = true
        );
        insert existingPlma;

        Test.startTest();
        B2BCreateHistoricalPLMABatch batch = new B2BCreateHistoricalPLMABatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
    }
}