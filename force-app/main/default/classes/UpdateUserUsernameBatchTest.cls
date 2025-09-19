@isTest
private class UpdateUserUsernameBatchTest {
    
    // Test method to verify batch functionality
    @isTest
    static void testUpdateUserUsernameBatch() {
        // Create test users
        List<User> testUsers = new List<User>();
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create 3 test users with different email and username scenarios
        User user1 = new User(
            Alias = 'test1',
            Email = 'test1@example.com',
            Username = 'oldusername1@example.com',
            LastName = 'Test1',
            ProfileId = standardProfile.Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        
        User user2 = new User(
            Alias = 'test2',
            Email = 'test2@example.com',
            Username = 'test2@example.com', // Email and username already match
            LastName = 'Test2',
            ProfileId = standardProfile.Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        
        User user3 = new User(
            Alias = 'test3',
            Email = 'test3@example.com',
            Username = 'oldusername3@example.com',
            LastName = 'Test3',
            ProfileId = standardProfile.Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            IsActive = false // Inactive user
        );
        
        testUsers.add(user1);
        testUsers.add(user2);
        testUsers.add(user3);
        
        insert testUsers;
        
        // Start the test
        Test.startTest();
        
        // Execute the batch job
        UpdateUserUsernameBatch batch = new UpdateUserUsernameBatch();
        Database.executeBatch(batch, 2); // Small batch size for testing
        
        Test.stopTest();
        
        // Verify results
        List<User> updatedUsers = [SELECT Id, Username, Email, IsActive FROM User WHERE Id IN :testUsers];
        
        for (User u : updatedUsers) {
            if (u.Id == user1.Id) {
                // Active user with mismatched username should be updated
                System.assertEquals(u.Email, u.Username, 'Username should match email for user1');
            } else if (u.Id == user2.Id) {
                // Active user with matching username should remain unchanged
                System.assertEquals(u.Email, u.Username, 'Username should remain unchanged for user2');
            } else if (u.Id == user3.Id) {
                // Inactive user should not be updated
                System.assertNotEquals(u.Email, u.Username, 'Inactive user3 username should not be updated');
            }
        }
    }
    
    // Test method to simulate a failure scenario
    @isTest
    static void testBatchFailure() {
        // Create a test user with an invalid email format
        User testUser = new User(
            Alias = 'test4',
            Email = 'invalid-email', // Invalid email format
            Username = 'oldusername4@example.com',
            LastName = 'Test4',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;
        
        // Start the test
        Test.startTest();
        
        // Execute the batch job
        UpdateUserUsernameBatch batch = new UpdateUserUsernameBatch();
        Database.executeBatch(batch, 1);
        
        Test.stopTest();
        
        // Verify that the username was not updated due to invalid email
        User updatedUser = [SELECT Username, Email FROM User WHERE Id = :testUser.Id];
        System.assertNotEquals(updatedUser.Email, updatedUser.Username, 'Username should not be updated for invalid email');
    }
}