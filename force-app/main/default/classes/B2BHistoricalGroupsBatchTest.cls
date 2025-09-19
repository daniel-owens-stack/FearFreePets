@isTest
public class B2BHistoricalGroupsBatchTest {

    @isTest
    static void runBatch() {
        Id businessRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Business Account' LIMIT 1].Id;
        Id personRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;

        Account biz = new Account(
            Name = 'Biz',
            RecordTypeId = businessRtId,
            Historical_Primary_Group__c = true,
            Original_System_ID__c = 'B001'
        );
        insert biz;

        Account person = new Account(
            FirstName = 'Test',
            LastName = 'Person',
            RecordTypeId = personRtId,
            Original_System_ID__c = 'U001'
        );
        insert person;

        Historical_Account_Group__c match = new Historical_Account_Group__c(
            Name = 'Match',
            Group_Id__c = 'B001',
            User_Id__c = 'U001'
        );

        Historical_Account_Group__c noBiz = new Historical_Account_Group__c(
            Name = 'NoBiz',
            Group_Id__c = 'B404',
            User_Id__c = 'U001'
        );

        Historical_Account_Group__c noUser = new Historical_Account_Group__c(
            Name = 'NoUser',
            Group_Id__c = 'B001',
            User_Id__c = 'U404'
        );

        insert new List<Historical_Account_Group__c>{ match, noBiz, noUser };

        Test.startTest();
        Database.executeBatch(new B2BProcessHistoricalAccountGroupsBatch(), 200);
        Test.stopTest();
    }
}