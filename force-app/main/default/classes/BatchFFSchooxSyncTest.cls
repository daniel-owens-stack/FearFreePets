@IsTest
private class BatchFFSchooxSyncTest {

    // Create a PA if enabled; return null if PAs aren’t available
    private static Account tryCreatePersonAccount(String last, String email) {
        RecordType paRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1];
        if (paRt == null) return null;

        Account pa = new Account(
            RecordTypeId = paRt.Id,
            LastName     = last,
            PersonEmail  = email
        );
        insert pa;
        Contact con = [SELECT Id  FROM Contact WHERE AccountId = :pa.Id LIMIT 1];
        // Re-query to ensure PersonContactId populated
        pa = [SELECT Id, IsPersonAccount, PersonContactId FROM Account WHERE Id = :pa.Id];
        if (!pa.IsPersonAccount || pa.PersonContactId == null) return null;
        return pa;
    }

    @IsTest
    static void batchCoversCreateAndUpdatePaths() {
        // If Person Accounts aren’t enabled in this org, skip test gracefully
        Account paCreate = tryCreatePersonAccount('CreateUser', 'create.user@test.com');
        Account paUpdate = tryCreatePersonAccount('UpdateUser', 'update.user@test.com');
        if (paCreate == null || paUpdate == null) {
            System.assert(true, 'Person Accounts not enabled in this test org; skipping test.');
            return;
        }

        // Membership → Job mapping used by FFGetSchooxJobIds
        Membership__c mem = new Membership__c(Name = 'Test Mem');
        insert mem;
        FFGetSchooxJobIds.setTestMembershipToJobId(new Map<Id,Integer>{ mem.Id => 12345 });

        // Active memberships for each PA so job ids are found
        insert new Account_Membership__c(Account_Id__c = paCreate.Id, Status__c = 'Active', Membership__c = mem.Id);
        insert new Account_Membership__c(Account_Id__c = paUpdate.Id, Status__c = 'Active', Membership__c = mem.Id);

        // For UPDATE path, preseed contact + existing LMS record
        List<Contact> updCList = [SELECT Id, SX_User_Id__c FROM Contact WHERE Id = :paUpdate.PersonContactId LIMIT 1];
        System.assert(!updCList.isEmpty(), 'Update contact not found');
        Contact cUpdate = updCList[0];
        cUpdate.SX_User_Id__c = '1111';
        update cUpdate;

        SX_LMS_User__c existingLms = new SX_LMS_User__c(
            SF_Contact__c = cUpdate.Id,
            SX_User_ID__c = '1111',
            SX_Active_User__c = true
        );
        insert existingLms;

        // Use your mock
        Test.setMock(HttpCalloutMock.class, new SchooxHttpMock());

        // Run batch on both PAs
        Test.startTest();
        Database.executeBatch(new BatchFFSchooxSync(new List<Id>{ paCreate.Id, paUpdate.Id }), 50);
        Test.stopTest();

        // Assertions — CREATE path
        List<Contact> cCreateList = [SELECT Id, SX_User_Id__c, SX_LMS_User__c FROM Contact WHERE Id = :paCreate.PersonContactId LIMIT 1];
        System.assert(!cCreateList.isEmpty(), 'Create contact not found');
        Contact cCreate = cCreateList[0];

        List<SX_LMS_User__c> createdLmsList = [
            SELECT Id, SX_User_ID__c, SX_Process_Pending__c, Enrollments_Due_At__c, SF_Contact__c
            FROM SX_LMS_User__c
            WHERE SF_Contact__c = :cCreate.Id
            LIMIT 1
        ];
        System.assert(!createdLmsList.isEmpty(), 'LMS not created for create-contact');
        SX_LMS_User__c createdLms = createdLmsList[0];
        System.assertEquals(cCreate.Id, createdLms.SF_Contact__c);
        System.assertEquals(true, createdLms.SX_Process_Pending__c);
        System.assertNotEquals(null, createdLms.Enrollments_Due_At__c);
        System.assertEquals('9999', cCreate.SX_User_Id__c, 'Contact should be stamped with created SX id');
        System.assertNotEquals(null, cCreate.SX_LMS_User__c);

        // Assertions — UPDATE path (existing LMS flagged)
        SX_LMS_User__c updatedExisting = [
            SELECT Id, SX_User_ID__c, SX_Process_Pending__c, Enrollments_Due_At__c, SF_Contact__c
            FROM SX_LMS_User__c
            WHERE Id = :existingLms.Id
            LIMIT 1
        ];
        System.assertEquals('1111', updatedExisting.SX_User_ID__c);
        System.assertEquals(true, updatedExisting.SX_Process_Pending__c);
        System.assertNotEquals(null, updatedExisting.Enrollments_Due_At__c);

        // Contact still linked to existing LMS
        Contact cUpdateAfter = [SELECT Id, SX_User_Id__c, SX_LMS_User__c FROM Contact WHERE Id = :cUpdate.Id LIMIT 1];
        System.assertEquals('1111', cUpdateAfter.SX_User_Id__c);
        System.assertEquals(existingLms.Id, cUpdateAfter.SX_LMS_User__c);
    }
}