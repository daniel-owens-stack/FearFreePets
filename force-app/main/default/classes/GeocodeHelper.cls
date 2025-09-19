public without sharing class GeocodeHelper {

    // Method to geocode a single address
    public static Map<String, Object> geocodeSingleAddress(String street, String city, String state, String postalCode, String country) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // Construct the request to Google Maps Geocoding API
        String address = EncodingUtil.urlEncode(street + ', ' + city + ', ' + state + ' ' + postalCode + ', ' + country, 'UTF-8');
        request.setEndpoint('https://maps.googleapis.com/maps/api/geocode/json?address=' + address + '&key=AIzaSyDR72pjyhyVBimnl-Stk_fmmvEsRWiASXU');
        request.setMethod('GET');
        HttpResponse response = http.send(request);

        Map<String, Object> result = new Map<String, Object>();

        if (response.getStatusCode() == 200) {
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if (responseBody.containsKey('results') && !((List<Object>) responseBody.get('results')).isEmpty()) {
                Map<String, Object> location = (Map<String, Object>) ((Map<String, Object>) ((List<Object>) responseBody.get('results'))[0]).get('geometry');
                if (location != null && location.containsKey('location')) {
                    result.put('latitude', ((Map<String, Object>) location.get('location')).get('lat'));
                    result.put('longitude', ((Map<String, Object>) location.get('location')).get('lng'));
                }
            }
        }

        return result;
    }

    // Method to geocode multiple accounts
    public static void geocodeAccounts(Set<Id> accountIds) {
        List<Account> accountsToUpdate = new List<Account>();

        // Query accounts that need geocoding
        List<Account> accounts = [SELECT Id, Directory_Address__Street__s, Directory_Address__City__s, Directory_Address__StateCode__s, Directory_Address__PostalCode__s, Directory_Address__CountryCode__s
                                  FROM Account WHERE Id IN :accountIds];

        // Loop through each account and geocode the address
        for (Account acc : accounts) {
            if (acc.Directory_Address__Street__s != null && acc.Directory_Address__City__s != null && 
                acc.Directory_Address__StateCode__s != null && acc.Directory_Address__PostalCode__s != null && 
                acc.Directory_Address__CountryCode__s != null) {

                // Call geocodeSingleAddress to get coordinates
                Map<String, Object> coordinates = geocodeSingleAddress(
                    acc.Directory_Address__Street__s, acc.Directory_Address__City__s, 
                    acc.Directory_Address__StateCode__s, acc.Directory_Address__PostalCode__s, acc.Directory_Address__CountryCode__s
                );

                // If coordinates are returned, update the account
                if (coordinates.containsKey('latitude') && coordinates.containsKey('longitude')) {
                    acc.Coordinates__Latitude__s = (Decimal) coordinates.get('latitude');
                    acc.Coordinates__Longitude__s = (Decimal) coordinates.get('longitude');
                    accountsToUpdate.add(acc);
                }
            }
        }

        // Perform DML to update accounts with coordinates
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}