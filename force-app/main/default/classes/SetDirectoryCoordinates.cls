public without sharing class SetDirectoryCoordinates {
    // Accept a Set of account IDs to process
    public static void geocodeAddresses(Set<Id> accountIds) {
        // Call the method to geocode the addresses asynchronously
        geocodeAddressesAsync(new List<Id>(accountIds));
    }

    // @future method for asynchronous callout
    @future(callout=true)
    private static void geocodeAddressesAsync(List<Id> accountIds) {
        List<Account> accountsToUpdate = [SELECT Id, Directory_Address__Street__s, Directory_Address__City__s, 
                                          Directory_Address__StateCode__s, Directory_Address__PostalCode__s, 
                                          Directory_Address__CountryCode__s, Coordinates__Latitude__s, Coordinates__Longitude__s
                                          FROM Account WHERE Id IN :accountIds];
        List<Account> updatedAccounts = new List<Account>();

        for (Account acc : accountsToUpdate) {
            if (acc.Directory_Address__StateCode__s != null && acc.Directory_Address__CountryCode__s != null) {
                // Call the method from GeocodeHelper to geocode the address
                Map<String, Object> result = GeocodeHelper.geocodeSingleAddress(
                    acc.Directory_Address__Street__s,
                    acc.Directory_Address__City__s,
                    acc.Directory_Address__StateCode__s,
                    acc.Directory_Address__PostalCode__s,
                    acc.Directory_Address__CountryCode__s
                );

                if (result.containsKey('latitude') && result.containsKey('longitude')) {
                    // Update the account with the coordinates
                    acc.Coordinates__Latitude__s = (Decimal) result.get('latitude');
                    acc.Coordinates__Longitude__s = (Decimal) result.get('longitude');
                    updatedAccounts.add(acc);
                }
            }
        }

        if (!updatedAccounts.isEmpty()) {
            // Update accounts asynchronously
            update updatedAccounts;
        }
    }
}