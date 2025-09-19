@IsTest
public class FFAccountTriggerTest {

    @TestSetup
    static void setup() {
        // No setup required since we're creating records directly in the test methods
    }

    // @IsTest
    // static void testBeforeInsert() {
    //     // Create an account with address fields populated
    //     Account acc = new Account(
    //         Name = 'Test Account Insert',
    //         Directory_Address__Street__s = '1600 Amphitheatre Parkway',
    //         Directory_Address__City__s = 'Mountain View',
    //         Directory_Address__StateCode__s = 'CA',
    //         Directory_Address__PostalCode__s = '94043',
    //         Directory_Address__CountryCode__s = 'US'
    //     );

    //     // Mock the callout
    //     Test.setMock(HttpCalloutMock.class, new GeocodeMock());

    //     // Start the test
    //     Test.startTest();
    //     insert acc;
    //     Test.stopTest();

    //     // Verify that the coordinates were updated based on the mock response
    //     Account insertedAcc = [SELECT Coordinates__Latitude__s, Coordinates__Longitude__s 
    //                            FROM Account 
    //                            WHERE Id = :acc.Id LIMIT 1];
    //     System.assertEquals(37.4219999, insertedAcc.Coordinates__Latitude__s, 'Latitude should be updated from the mock response.');
    //     System.assertEquals(-122.0840575, insertedAcc.Coordinates__Longitude__s, 'Longitude should be updated from the mock response.');
    // }

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

        // Verify that the coordinates were updated based on the mock response
        Account updatedAcc = [SELECT Coordinates__Latitude__s, Coordinates__Longitude__s 
                              FROM Account 
                              WHERE Id = :acc.Id LIMIT 1];
        System.assertEquals(37.4219999, updatedAcc.Coordinates__Latitude__s, 'Latitude should be updated from the mock response.');
        System.assertEquals(-122.0840575, updatedAcc.Coordinates__Longitude__s, 'Longitude should be updated from the mock response.');
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

        // Verify that no coordinates were updated
        Account insertedAcc = [SELECT Coordinates__Latitude__s, Coordinates__Longitude__s 
                               FROM Account 
                               WHERE Id = :acc.Id LIMIT 1];
        System.assertEquals(null, insertedAcc.Coordinates__Latitude__s, 'Latitude should not be updated when no address is provided.');
        System.assertEquals(null, insertedAcc.Coordinates__Longitude__s, 'Longitude should not be updated when no address is provided.');
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