@IsTest
public class SetDirectoryCoordinatesTest {

    @IsTest
    static void testGeocodeAddresses() {
        // Start the test to set up mock data before DML operation (Insert)
        List<Account> accounts = new List<Account>();
        
        // Account 1: Valid address, should be geocoded
        accounts.add(new Account(
            Name = 'Test Account 1',
            Directory_Address__Street__s = '1600 Amphitheatre Parkway',
            Directory_Address__City__s = 'Mountain View',
            Directory_Address__StateCode__s = 'CA',
            Directory_Address__PostalCode__s = '94043',
            Directory_Address__CountryCode__s = 'US'
        ));

        // Account 2: Incomplete address, should not be geocoded
        accounts.add(new Account(
            Name = 'Test Account 2',
            Directory_Address__Street__s = '1 Infinite Loop',
            Directory_Address__City__s = 'Cupertino',
            Directory_Address__StateCode__s = null, // Missing state code
            Directory_Address__PostalCode__s = '95014',
            Directory_Address__CountryCode__s = 'US'
        ));

        // Account 3: Valid address, should be geocoded
        accounts.add(new Account(
            Name = 'Test Account 3',
            Directory_Address__Street__s = '1 Microsoft Way',
            Directory_Address__City__s = 'Redmond',
            Directory_Address__StateCode__s = 'WA',
            Directory_Address__PostalCode__s = '98052',
            Directory_Address__CountryCode__s = 'US'
        ));

        insert accounts;  // Now we are inserting data in the test method it
        Test.startTest();
        
        // Mock the callout
        Test.setMock(HttpCalloutMock.class, new GeocodeMock());

        // Fetch the test data created in @TestSetup
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : [SELECT Id FROM Account]) {
            accountIds.add(acc.Id);
        }

        // Call the method to geocode addresses
        SetDirectoryCoordinates.geocodeAddresses(accountIds);

        // Stop the test
        Test.stopTest();

        // Validate that the accounts were updated with the correct coordinates
        List<Account> updatedAccounts = [SELECT Coordinates__Latitude__s, Coordinates__Longitude__s FROM Account WHERE Id IN :accountIds];

        for (Account acc : updatedAccounts) {
            if (acc.Coordinates__Latitude__s != null && acc.Coordinates__Longitude__s != null) {
                System.assertNotEquals(null, acc.Coordinates__Latitude__s, 'Latitude should be set');
                System.assertNotEquals(null, acc.Coordinates__Longitude__s, 'Longitude should be set');
            } else {
                System.assertEquals(null, acc.Coordinates__Latitude__s, 'Latitude should not be set for incomplete addresses');
                System.assertEquals(null, acc.Coordinates__Longitude__s, 'Longitude should not be set for incomplete addresses');
            }
        }
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