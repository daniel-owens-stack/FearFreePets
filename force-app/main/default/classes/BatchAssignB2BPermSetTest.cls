@IsTest
private class BatchAssignB2BPermSetTest {
    @IsTest
    static void testAssignPermSet() {
        // Get perm set + profile
        PermissionSet ps = [
            SELECT Id FROM PermissionSet 
            WHERE Name = 'Fear_Free_B2B_Store_Buyer' 
            LIMIT 1
        ];
        Profile commProfile = [
            SELECT Id FROM Profile 
            WHERE Name = 'Fear Free Community Member' 
            LIMIT 1
        ];
        Id paRt = [SELECT Id FROM RecordType 
                   WHERE SObjectType = 'Account' AND IsPersonType = true 
                   LIMIT 1].Id;

        // Create person account + contact
        Account acc = new Account(
            FirstName = 'Test',
            LastName = 'User',
            RecordTypeId = paRt,
            PersonEmail = 'permset@test.com'
        );
        insert acc;
        Contact con = [SELECT Id, Email FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

        // Create user
        User u = new User(
            Alias = 'tuser',
            Email = con.Email,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = commProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            ContactId = con.Id
        );

        Test.startTest();
        insert u;  // ⚠️ Insert inside Test.startTest so batch sees it

        // Run batch with scope 1 to guarantee single execute
        Database.executeBatch(new BatchAssignB2BPermSet(), 1);
        Test.stopTest();

        // Assert permission set got assigned
        List<PermissionSetAssignment> psaList = [
            SELECT Id 
            FROM PermissionSetAssignment
            WHERE AssigneeId = :u.Id AND PermissionSetId = :ps.Id
        ];
        System.assertEquals(1, psaList.size(), 
            'User should have received the Fear Free B2B Store Buyer perm set');
    }
}