trigger FFAccountTrigger on Account (after insert, after update) {
    Set<Id> accountIds = new Set<Id>();

    // if (Trigger.isInsert) {
    //     // Check if any of the Directory Address fields are not null on insert
    //     for (Account acc : Trigger.new) {
    //         if (acc.Directory_Address__Street__s != null ||
    //             acc.Directory_Address__City__s != null ||
    //             acc.Directory_Address__StateCode__s != null ||
    //             acc.Directory_Address__PostalCode__s != null ||
    //             acc.Directory_Address__CountryCode__s != null) {
    //             accountIds.add(acc.Id);
    //         }
    //     }
    // } else 
    if (Trigger.isUpdate) {
        // Check if any of the Directory Address fields have changed (including null to non-null)
        for (Account acc : Trigger.new) {
            Account oldAcc = Trigger.oldMap.get(acc.Id);

            // Explicitly check for changes from null to non-null
            if (((oldAcc.Directory_Address__Street__s == null && acc.Directory_Address__Street__s != null) ||
                (oldAcc.Directory_Address__City__s == null && acc.Directory_Address__City__s != null) ||
                (oldAcc.Directory_Address__StateCode__s == null && acc.Directory_Address__StateCode__s != null) ||
                (oldAcc.Directory_Address__PostalCode__s == null && acc.Directory_Address__PostalCode__s != null) ||
                (oldAcc.Directory_Address__CountryCode__s == null && acc.Directory_Address__CountryCode__s != null)) ||
                ((acc.Directory_Address__Street__s != oldAcc.Directory_Address__Street__s) ||
                (acc.Directory_Address__City__s != oldAcc.Directory_Address__City__s) ||
                (acc.Directory_Address__StateCode__s != oldAcc.Directory_Address__StateCode__s) ||
                (acc.Directory_Address__PostalCode__s != oldAcc.Directory_Address__PostalCode__s) ||
                (acc.Directory_Address__CountryCode__s != oldAcc.Directory_Address__CountryCode__s))) {
                accountIds.add(acc.Id);
            }
        }
    }

    // Call the geocoding method if there are accounts to process
    if (!accountIds.isEmpty()) {
        SetDirectoryCoordinates.geocodeAddresses(accountIds);
    }
}