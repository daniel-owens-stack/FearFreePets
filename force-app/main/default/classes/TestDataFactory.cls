/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-11-11 09:03:46
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:38:17
 * @ Description:
 */

@IsTest
public with sharing class TestDataFactory {
    private static final Integer DATA_SIZE = 5;

    public static List<Account> insertAccountData() {
        Account acc = new Account(
            Name = 'TEST ADMIN',
            Phone  = '12346789',
            AccountNumber = '123'
        );

        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        List<Account> testAccts = new List<Account>{acc};
        for(Integer i=0 ; i < DATA_SIZE ; i++) {
            Account tempAccount = new Account(
                FirstName  = 'TEST',
                LastName   = 'Account' + i,
                RecordTypeId = personAccountRecordTypeId,
                PersonEmail  = 'ridowan' + i + '@test.com',
                Phone  = '12346789'
            );
            testAccts.add(tempAccount);
        }
        insert testAccts;
        return testAccts;
    }
    
    public static List<Contact> insertContactData() {
        List<Account> testAccts = [SELECT Id FROM Account WHERE IsPersonAccount = FALSE];
        if (testAccts.isEmpty()) {
            testAccts = insertAccountData();
            testAccts = [SELECT Id FROM Account WHERE IsPersonAccount = FALSE];
        }
        List<Contact> testContacts = new List<Contact>();
        for(Integer i=0 ; i < testAccts.size() ; i++) {
            Contact con = new Contact(
                AccountId  = testAccts.get(Math.mod(i, testAccts.Size())).Id,
                FirstName  = 'Ridowan' + i,
                LastName   = 'Ahmed' + i,
                Salutation = 'Mr.', 
                Email	   = i + 'ridowan@mi6.co.uk',
                Phone	   = '0881234567',
                MobilePhone= '0631226777',
                MailingCountry = 'United States'
            );
            testContacts.add(con);
        }
        testContacts.get(0).SX_User_Id__c = '123';
        insert testContacts;
        return testContacts;
    }

    public static List<SX_LMS_User__c> insertLMSUserData() {
        List<Contact> testContacts = [SELECT Name FROM Contact];
        if (testContacts.isEmpty()) {
            testContacts = insertContactData();
        }
        List<SX_LMS_User__c> lmsList = new List<SX_LMS_User__c>();
        for(Integer i=0 ; i < testContacts.size() ; i++) {
            SX_LMS_User__c lms = new SX_LMS_User__c(
                SF_Contact__c  = testContacts.get(i).Id
            );
            lmsList.add(lms);
        }
        lmsList.get(0).SX_User_ID__c = '123';
        lmsList.get(0).SF_Contact__c = null;
        lmsList.get(0).SF_User__c = UserInfo.getUserId();
        insert lmsList;
        return lmsList;
    }

    public static List<SX_Courses__c> insertCourseData() {
        List<SX_Courses__c> courseList = new List<SX_Courses__c>();
        for(Integer i=0 ; i < DATA_SIZE ; i++) {
            SX_Courses__c testCourse = new SX_Courses__c(
                Name  = 'Test ' + i,
                SX_Course_ID__c = '32' + i
            );
            courseList.add(testCourse);
        }
        insert courseList;
        System.debug(JSON.serializePretty(courseList));
        return courseList;
    }

    public static List<SX_Above_Unit__c> insertAboveUnitData() {
        List<SX_Above_Unit__c> aboveUnitList = new List<SX_Above_Unit__c>();
        for(Integer i=0 ; i < DATA_SIZE ; i++) {
            SX_Above_Unit__c tempAboveUnit = new SX_Above_Unit__c(
                Name  = 'Test ' + i,
                SX_ID__c = '10' + i
            );
            aboveUnitList.add(tempAboveUnit);
        }
        insert aboveUnitList;
        return aboveUnitList;
    }
}