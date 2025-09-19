@IsTest
public class SearchAccountsControllerTest {

    static Double testLatitude = 34.0522;
    static Double testLongitude = -118.24837;
    static Id personAccId;

    @TestSetup
    static void setup() {
        // Get Person Account record type ID
        Id personRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        // Certified Practice Business Account
        Account cpAccount = new Account(
            Name = 'Certified Account 1',
            Directory_Email__c = 'certified1@example.com',
            Directory_Phone__c = '123-456-7890',
            Coordinates__Longitude__s = testLongitude,
            Coordinates__Latitude__s = testLatitude,
            Directory_Opt_In__c = true,
            Certified_Practice__c = 'Completed'
        );

        // Non-Certified Business Account
        Account nonCertified = new Account(
            Name = 'Non-Certified Account 1',
            Directory_Email__c = 'noncertified1@example.com',
            Directory_Phone__c = '987-654-3210',
            Coordinates__Longitude__s = testLongitude,
            Coordinates__Latitude__s = testLatitude,
            Directory_Opt_In__c = true
        );

        // Certified Person Account
        Account personAcc = new Account(
            RecordTypeId = personRtId,
            LastName = 'Certified Person Account',
            Directory_Email__c = 'person@example.com',
            Directory_Phone__c = '111-222-3333',
            Coordinates__Longitude__s = testLongitude,
            Coordinates__Latitude__s = testLatitude,
            Directory_Opt_In__c = true,
            Business__c = null,
            Admin_Account__c = false
        );

        insert new List<Account>{ cpAccount, nonCertified, personAcc };

        personAccId = personAcc.Id;

        // Practice-Level Membership Assignment
        insert new Practice_Level_Membership_Assignment__c(
            Business_Account__c = cpAccount.Id,
            Status__c = 'Active',
            Certified__c = true
        );

        // Certified Memberships
        insert new List<Account_Membership__c>{
            new Account_Membership__c(Account_Id__c = cpAccount.Id, Certified__c = true, Status__c = 'Active'),
            new Account_Membership__c(Parent_Id__c = nonCertified.Id, Certified__c = true, Status__c = 'Active'),
            new Account_Membership__c(Account_Id__c = personAcc.Id, Certified__c = true, Status__c = 'Active')
        };
    }

    @IsTest
    static void testSearchListingsWithoutCoordinates() {
        Test.startTest();
        List<SearchAccountsController.ListingWrapper> results = SearchAccountsController.searchListings(null, null, 20);
        Test.stopTest();
        System.assertEquals(0, results.size(), 'Should return 0 listings without coordinates');
    }

    @IsTest
    static void testSearchListingsOutsideRadius() {
        Test.startTest();
        List<SearchAccountsController.ListingWrapper> results = SearchAccountsController.searchListings(40.0d, -122.0d, 5);
        Test.stopTest();
        System.assertEquals(0, results.size(), 'Should return 0 listings outside radius');
    }

    @IsTest
    static void testSearchListingsWithinRadius() {
        Test.startTest();
        List<SearchAccountsController.ListingWrapper> results = SearchAccountsController.searchListings(testLatitude, testLongitude, 10);
        Test.stopTest();

        System.assertEquals(3, results.size(), 'Should return 3 listings within radius');

        Boolean foundCertified = false;
        Boolean foundNonCertified = false;

        for (SearchAccountsController.ListingWrapper wrapper : results) {
            if (wrapper.acc.Name == 'Certified Account 1') {
                System.assert(wrapper.cp, 'Certified account should have cp = true');
                foundCertified = true;
            } else if (wrapper.acc.Name == 'Non-Certified Account 1') {
                System.assert(!wrapper.cp, 'Non-certified account should have cp = false');
                foundNonCertified = true;
            }
        }

        System.assert(foundCertified, 'Certified listing should be returned');
        System.assert(foundNonCertified, 'Non-certified listing should be returned');
    }

    @IsTest
    static void testSearchListingsWithPersonAccount() {
        Double latitude = 34.0522;
        Double longitude = -118.24837;
    
        // Get Person Account record type
        Id personRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
    
        // Create and insert the person account
        Account personAcc = new Account(
            RecordTypeId = personRtId,
            LastName = 'Certified Person Account',
            Directory_Email__c = 'person@example.com',
            Directory_Phone__c = '111-222-3333',
            Coordinates__Longitude__s = longitude,
            Coordinates__Latitude__s = latitude,
            Directory_Opt_In__c = true,
            Business__c = null,
            Admin_Account__c = false
        );
        insert personAcc;
    
        // Add certified membership for person account
        insert new Account_Membership__c(
            Account_Id__c = personAcc.Id,
            Certified__c = true,
            Status__c = 'Active'
        );
    
        Test.startTest();
        List<SearchAccountsController.ListingWrapper> results = SearchAccountsController.searchListings(latitude, longitude, 10);
        Test.stopTest();
    
        Boolean foundPerson = false;
        for (SearchAccountsController.ListingWrapper wrapper : results) {
            if (wrapper.acc.Id == personAcc.Id) {
                System.assert(!wrapper.cp, 'Person account should have cp = false');
                foundPerson = true;
            }
        }
    
        System.assert(foundPerson, 'Certified person account should be returned');
    }    
}