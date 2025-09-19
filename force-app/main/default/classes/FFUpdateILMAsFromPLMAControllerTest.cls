@IsTest
private class FFUpdateILMAsFromPLMAControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create Business Account
        Account businessAcct = new Account(
            Name = 'Test Business',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Business Account' LIMIT 1].Id
        );
        insert businessAcct;

        // Create PLMA
        Practice_Level_Membership_Assignment__c plma = new Practice_Level_Membership_Assignment__c(
            Business_Account__c = businessAcct.Id,
            Status__c = 'Active',
            Start_Date__c = Date.today()
        );
        insert plma;

        // Create ILMAs related to PLMA
        List<Account_Membership__c> ilmas = new List<Account_Membership__c>();
        for (Integer i = 0; i < 2; i++) {
            ilmas.add(new Account_Membership__c(
                Account_Id__c = businessAcct.Id,
                Practice_Level_Membership_Assignment__c = plma.Id,
                Status__c = 'Complete',
                Start_Date__c = Date.today().addDays(-10)
            ));
        }
        insert ilmas;
    }

    @IsTest
    static void testHasPLMA_true() {
        Account bizAcct = [SELECT Id FROM Account WHERE Name = 'Test Business' LIMIT 1];
        Test.startTest();
        Boolean result = FFUpdateILMAsFromPLMAController.hasPLMA(bizAcct.Id);
        Test.stopTest();
        System.assertEquals(true, result, 'Business account should have a PLMA');
    }

    @IsTest
    static void testHasPLMA_false() {
        Account noPlmaAcct = new Account(
            Name = 'No PLMA Business',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Business Account' LIMIT 1].Id
        );
        insert noPlmaAcct;

        Test.startTest();
        Boolean result = FFUpdateILMAsFromPLMAController.hasPLMA(noPlmaAcct.Id);
        Test.stopTest();
        System.assertEquals(false, result, 'Business account without PLMA should return false');
    }

    @IsTest
    static void testUpdateILMAs() {
        Account bizAcct = [SELECT Id FROM Account WHERE Name = 'Test Business' LIMIT 1];
        Practice_Level_Membership_Assignment__c plma = [SELECT Id, Status__c, Start_Date__c FROM Practice_Level_Membership_Assignment__c WHERE Business_Account__c = :bizAcct.Id LIMIT 1];

        Test.startTest();
        FFUpdateILMAsFromPLMAController.updateILMAs(bizAcct.Id);
        Test.stopTest();

        // Verify ILMAs got updated to match PLMA
        for (Account_Membership__c ilma : [
            SELECT Status__c, Start_Date__c 
            FROM Account_Membership__c 
            WHERE Practice_Level_Membership_Assignment__c = :plma.Id
        ]) {
            System.assertEquals(plma.Status__c, ilma.Status__c, 'ILMA status should match PLMA status');
            System.assertEquals(plma.Start_Date__c, ilma.Start_Date__c, 'ILMA start date should match PLMA start date');
        }
    }
}