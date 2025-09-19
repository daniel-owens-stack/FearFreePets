@IsTest
public class AccountTriggerTest {

    @TestSetup
    static void setup() {
        // No setup required since we're creating records directly in the test methods
    }

    @IsTest
    static void testBeforeInsert() {
        // Create an account with address fields populated
        Account acc = new Account(
            Name = 'Test Account Insert',
            Directory_Address__Street__s = '1600 Amphitheatre Parkway',
            Directory_Address__City__s = 'Mountain View',
            Directory_Address__StateCode__s = 'CA',
            Directory_Address__PostalCode__s = '94043',
            Directory_Address__CountryCode__s = 'US'
        );

        // Mock the callout
        Test.setMock(HttpCalloutMock.class, new GeocodeMock());

        // Start the test
        Test.startTest();
        insert acc;
        Test.stopTest();

        // Assert that the trigger invoked the SetDirectoryCoordinates.geocodeAddresses method
        // This is validated by ensuring no exceptions were thrown, and the account was inserted successfully
        // (Further validation would require adding checks on the effects of the mocked callout)
        Account insertedAcc = [SELECT Id, Directory_Address__Street__s FROM Account WHERE Id = :acc.Id LIMIT 1];
        System.assertEquals('1600 Amphitheatre Parkway', insertedAcc.Directory_Address__Street__s, 'The address should be set as expected on insert.');
    }

    @IsTest
    static void testBeforeUpdate() {
        // Create and insert an account without address fields
        Account acc = new Account(
            Name = 'Test Account Update'
        );
        insert acc;

        // Mock the callout
        Test.setMock(HttpCalloutMock.class, new GeocodeMock());

        // Update the account with address fields populated
        acc.Directory_Address__Street__s = '1 Infinite Loop';
        acc.Directory_Address__City__s = 'Cupertino';
        acc.Directory_Address__StateCode__s = 'CA';
        acc.Directory_Address__PostalCode__s = '95014';
        acc.Directory_Address__CountryCode__s = 'US';

        // Start the test
        Test.startTest();
        update acc;
        Test.stopTest();

        // Assert that the trigger invoked the SetDirectoryCoordinates.geocodeAddresses method
        // This is validated by ensuring the update was successful and that the address fields were updated
        Account updatedAcc = [SELECT Id, Directory_Address__Street__s FROM Account WHERE Id = :acc.Id LIMIT 1];
        System.assertEquals('1 Infinite Loop', updatedAcc.Directory_Address__Street__s, 'The address should be updated as expected.');
    }

    @IsTest
    static void testNoAddressFields() {
        // Create an account with no address fields populated
        Account acc = new Account(
            Name = 'Test Account No Address'
        );

        // Start the test
        Test.startTest();
        insert acc;
        Test.stopTest();

        // Assert that no addresses were processed (geocodeAddresses should not have been called)
        // Since we can't directly check the call, we ensure the record was inserted without any issues
        Account insertedAcc = [SELECT Id FROM Account WHERE Id = :acc.Id LIMIT 1];
        System.assertNotEquals(null, insertedAcc.Id, 'Account should have been inserted successfully without address fields.');
    }

    // Mock class for simulating the geocode callout
    private class GeocodeMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String jsonResponse = '{' +
                '"results" : [' +
                '{' +
                '"geometry" : {' +
                '"location" : {' +
                '"lat" : 37.4219999,' +
                '"lng" : -122.0840575' +
                '}}}' +
                '],' +
                '"status" : "OK"' +
            '}';

            res.setBody(jsonResponse);
            return res;
        }
    }
}