@isTest
public class B2BCreateHistoricalMembershipsBatchTest {

    @TestSetup
    static void setupData() {
        Id recordTypeId;
        if (Schema.SObjectType.Account.getRecordTypeInfosByName().containsKey('Person Account')) {
            recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        }

        Account personAccount = new Account(
            FirstName = 'Jane',
            LastName = 'Doe',
            PersonEmail = 'jane@example.com'
        );
        if (recordTypeId != null) {
            personAccount.RecordTypeId = recordTypeId;
        }
        insert personAccount;

        Membership__c individualMembership = new Membership__c(
            Name = 'Individual Membership',
            WC_Id__c = 'indiv_wc_id'
        );
        insert individualMembership;

        Historical_Membership__c validHm = new Historical_Membership__c(
            Start_Date__c = Date.today().addYears(-2),
            End_Date__c = Date.today().addYears(-1),
            Cancelled_Date__c = Date.today().addMonths(-6),
            User_Email__c = 'jane@example.com',
            Post_Parent__c = 'indiv_wc_id',
            Data_Status__c = 'Pending'
        );

        Historical_Membership__c missingStartDate = new Historical_Membership__c(
            User_Email__c = 'jane@example.com',
            Post_Parent__c = 'indiv_wc_id',
            Data_Status__c = 'Pending'
        );

        Historical_Membership__c invalidEmail = new Historical_Membership__c(
            Start_Date__c = Date.today().addYears(-1),
            User_Email__c = 'notfound@example.com',
            Post_Parent__c = 'indiv_wc_id',
            Data_Status__c = 'Pending'
        );

        Historical_Membership__c invalidPostParent = new Historical_Membership__c(
            Start_Date__c = Date.today().addYears(-1),
            User_Email__c = 'jane@example.com',
            Post_Parent__c = 'invalid_wc_id',
            Data_Status__c = 'Pending'
        );

        insert new List<Historical_Membership__c>{ validHm, missingStartDate, invalidEmail, invalidPostParent };
    }

    @isTest
    static void testBatchFullCoverage() {
        Test.startTest();
        B2BCreateHistoricalMembershipsBatch batch = new B2BCreateHistoricalMembershipsBatch();
        Database.executeBatch(batch, 200); // Prevents multiple execute calls
        Test.stopTest();
    }
}