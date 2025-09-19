@isTest
public class B2BCreatePLMATest {
    @testSetup
    public static void createData(){
        Id recordTypeId;
        if (Schema.SObjectType.Account.getRecordTypeInfosByName().containsKey('Person Account')) {
            recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        }
        
        Account personAccount = new Account(
            FirstName = 'Jane',
            LastName = 'Doe',
            PersonEmail = 'jane@example.com',
            Original_System_ID__c = '123489'
        );
        if (recordTypeId != null) {
            personAccount.RecordTypeId = recordTypeId;
        }
        insert personAccount;
        
        Membership__c individualMembership = new Membership__c(
            Name = 'Veterinary Practice Certification - ER/Urgent Care Membership'
        );
        insert individualMembership;
        
        
        
    }
    @isTest
    public static void testBatch(){
        Historical_PLMA__c historical = new Historical_PLMA__c(
            Cert_Date__c = System.today() + 10,
            Cert_Status__c = true,
            Admin_Id__c = '123489',
            End_Date__c =System.today() + 30,
            Group_ID__c = '123489',
            Start_Date__c = system.today()-30,
            Status__c = 'active',
            Membership_Type__c = 'VPC-ER',
            Data_Status__c = 'Pending'
        );
        insert historical;
        Test.startTest();
        Database.executeBatch(new B2BCreatePracticeHistoricalMembership());
        Test.stopTest();
        Historical_PLMA__c historical1 = [SELECT Id,Data_Status__c FROM Historical_PLMA__c LIMIT 1];
    }
    
    @isTest
    public static void testGroupBlank(){
        Historical_PLMA__c historical = new Historical_PLMA__c(
            Cert_Date__c = System.today() + 10,
            Cert_Status__c = true,
            Admin_Id__c = '123489',
            End_Date__c =System.today() + 30,
            Start_Date__c = system.today()-30,
            Status__c = 'active',
            Membership_Type__c = 'VPC-ER',
            Data_Status__c = 'Pending'
        );
        insert historical;
        Test.startTest();
        String qry = 'SELECT Id,Cert_Date__c,Cert_Status__c,Admin_Id__c,PLMA_Status__c,'+
            'End_Date__c,Group_ID__c,Membership_Type__c,Start_Date__c,Status__c'+
            ' FROM Historical_PLMA__c WHERE Id = \''+historical.Id+'\'';
        Database.executeBatch(new B2BCreatePracticeHistoricalMembership(qry));
        Test.stopTest();
        Historical_PLMA__c historical1 = [SELECT Id,Data_Status__c FROM Historical_PLMA__c LIMIT 1];
    }
    
}