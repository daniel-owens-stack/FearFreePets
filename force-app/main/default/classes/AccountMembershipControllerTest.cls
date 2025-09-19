@isTest
private class AccountMembershipControllerTest {

    @TestSetup
    static void setup() {
        // Create profiles
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Fear Free Community Member' LIMIT 1];

        // Create admin user
        User adminUser = new User(
            Alias = 'admin',
            Email = 'admin@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'adminuser' + System.currentTimeMillis() + '@test.com',
            IsActive = true
        );
        insert adminUser;

        // Create business account
        Account businessAccount = new Account(Name = 'Business Account');
        insert businessAccount;

        // Create Person Account (admin for the business)
        RecordType paRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1];
        Account personAccount = new Account(
            FirstName = 'Test',
            LastName = 'User',
            RecordTypeId = paRt.Id,
            Admin_Account__c = true,
            Business__c = businessAccount.Id
        );
        insert personAccount;

        // Retrieve related contact
        Contact personContact = [SELECT Id FROM Contact WHERE AccountId = :personAccount.Id LIMIT 1];

        // Create portal user
        User portalUser = new User(
            Alias = 'puser',
            Email = 'portal@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Portal',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = portalProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'portaluser' + System.currentTimeMillis() + '@test.com',
            ContactId = personContact.Id,
            IsActive = true
        );
        insert portalUser;

        // Create Memberships
        List<Membership__c> memberships = new List<Membership__c>{
            new Membership__c(Name = 'Veterinary Practice Certification - General Practice Membership'), // GP
            new Membership__c(Name = 'Veterinary Practice Certification - ER/Urgent Care Membership'), // ER
            new Membership__c(Name = 'Veterinary Practice Certification - House Call Membership'), // HC
            new Membership__c(Name = 'Veterinary Professional Membership'),
            new Membership__c(Name = 'Groomer Membership'),
            new Membership__c(Name = 'Pet Sitter Membership'),
            new Membership__c(Name = 'Trainer Membership'),
            new Membership__c(Name = 'Boarding & Daycare Individual Membership'),
            new Membership__c(Name = 'Veterinary Practice Certification'),
            new Membership__c(Name = 'Academia Membership')
        };
        insert memberships;

        Map<String, Id> membershipMap = new Map<String, Id>();
        for (Membership__c m : memberships) {
            membershipMap.put(m.Name, m.Id);
        }

        // Account Memberships
        List<Account_Membership__c> amList = new List<Account_Membership__c>{
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Active', Membership__c = membershipMap.get('Veterinary Practice Certification - General Practice Membership'), Certified__c = true),
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Active', Membership__c = membershipMap.get('Veterinary Practice Certification - ER/Urgent Care Membership'), Certified__c = true),
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Active', Membership__c = membershipMap.get('Veterinary Practice Certification - House Call Membership'), Certified__c = true),
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Active', Membership__c = membershipMap.get('Groomer Membership'), Certified__c = true),
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Active', Membership__c = membershipMap.get('Pet Sitter Membership'), Certified__c = true),
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Active', Membership__c = membershipMap.get('Trainer Membership'), Certified__c = false),
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Active', Membership__c = membershipMap.get('Boarding & Daycare Individual Membership'), Certified__c = true),
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Active', Membership__c = membershipMap.get('Veterinary Professional Membership'), Certified__c = true),
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Active', Membership__c = membershipMap.get('Academia Membership'), Certified__c = true)
        };
        insert amList;

        // Expired membership
        insert new Account_Membership__c(
            Account_Id__c = personAccount.Id,
            Status__c = 'Complete',
            Membership__c = membershipMap.get('Veterinary Professional Membership'),
            Certified__c = true
        );

        // PLMA entries
        insert new List<Practice_Level_Membership_Assignment__c>{
            new Practice_Level_Membership_Assignment__c(Status__c = 'Active', Business_Account__c = businessAccount.Id, Membership__c = membershipMap.get('Veterinary Practice Certification - General Practice Membership')),
            new Practice_Level_Membership_Assignment__c(Status__c = 'Active', Business_Account__c = businessAccount.Id, Membership__c = membershipMap.get('Veterinary Practice Certification - ER/Urgent Care Membership')),
            new Practice_Level_Membership_Assignment__c(Status__c = 'Active', Business_Account__c = businessAccount.Id, Membership__c = membershipMap.get('Veterinary Practice Certification - House Call Membership'))
        };
    }

    @isTest static void testAdminUser() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@test.com' LIMIT 1];
        System.runAs(adminUser) {
            Test.startTest();
            Map<String, Object> result = AccountMembershipController.checkMembershipStatus(
                true, true, true, true, true, true, true, true, true, true, true, false,
                false, false, // isExpired, anyStatus
                false, false, false, false, false, false, false, false, false, false
            );
            Test.stopTest();

            System.assertEquals(true, result.get('isAdmin'));
        }
    }

    @isTest static void testCertifiedStandardUser() {
        User portalUser = [SELECT Id FROM User WHERE Email = 'portal@test.com' LIMIT 1];
        System.runAs(portalUser) {
            Test.startTest();
            Map<String, Object> result = AccountMembershipController.checkMembershipStatus(
                true, true, true, true, true, true, true, true, true, true, true, true,
                false, false, // isExpired, anyStatus
                false, false, false, false, false, false, false, false, false, false
            );
            Test.stopTest();

            System.assertEquals(false, result.get('isAdmin'));
        }
    }

    @isTest static void testNonCertifiedStandardUser() {
        User portalUser = [SELECT Id FROM User WHERE Email = 'portal@test.com' LIMIT 1];
        System.runAs(portalUser) {
            Test.startTest();
            Map<String, Object> result = AccountMembershipController.checkMembershipStatus(
                true, true, true, false, false, false, true, true, true, true, true, false,
                false, false, // isExpired, anyStatus
                false, false, false, false, false, false, false, false, false, false
            );
            Test.stopTest();

            System.assertEquals(false, result.get('isAdmin'));
        }
    }

    @isTest static void testPLMAOnlyCheck() {
        User portalUser = [SELECT Id FROM User WHERE Email = 'portal@test.com' LIMIT 1];
        System.runAs(portalUser) {
            Test.startTest();
            Map<String, Object> result = AccountMembershipController.checkMembershipStatus(
                false, false, false, true, true, true, false, false, false, false, false, true,
                false, false, // isExpired, anyStatus
                false, false, false, false, false, false, false, false, false, false
            );
            Test.stopTest();

            System.assertEquals(true, result.get('hasActivePracticeLevelGPMembership'));
        }
    }

    @isTest static void testExclusionFlags() {
        User portalUser = [SELECT Id FROM User WHERE Email = 'portal@test.com' LIMIT 1];
        System.runAs(portalUser) {
            Test.startTest();
            Map<String, Object> result = AccountMembershipController.checkMembershipStatus(
                true, true, true, true, true, true, true, true, true, true, true, true,
                false, false, // isExpired, anyStatus
                true, true, true, true, true, true, true, true, true, true
            );
            Test.stopTest();

            System.assertEquals(false, result.get('hasActiveVetProLevelMembership'));
        }
    }

    @isTest static void testMissingAccountError() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User userWithoutAccount = new User(
            Alias = 'noacc',
            Email = 'noacc@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'NoAcc',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'noacc' + System.currentTimeMillis() + '@test.com',
            IsActive = true
        );
        insert userWithoutAccount;

        System.runAs(userWithoutAccount) {
            Test.startTest();
            Map<String, Object> result = AccountMembershipController.checkMembershipStatus(
                true, false, false, false, false, false, false, false, false, false, false, false,
                false, false, // isExpired, anyStatus
                false, false, false, false, false, false, false, false, false, false
            );
            Test.stopTest();

            System.assertNotEquals(null, result.get('error'));
        }
    }

    @isTest static void testExpiredMembershipCheck() {
        User portalUser = [SELECT Id FROM User WHERE Email = 'portal@test.com' LIMIT 1];
        System.runAs(portalUser) {
            Test.startTest();
            Map<String, Object> result = AccountMembershipController.checkMembershipStatus(
                true, true, true, false, false, false, false, false, false, false, false, false,
                true, false, // isExpired = true, anyStatus = false
                false, false, false, false, false, false, false, false, false, false
            );
            Test.stopTest();

            System.assertEquals(false, result.get('isAdmin'));
            System.assert(result.containsKey('hasActiveAccountMembership'));
        }
    }

    @isTest static void testAnyStatusFlag() {
        User portalUser = [SELECT Id FROM User WHERE Email = 'portal@test.com' LIMIT 1];
        System.runAs(portalUser) {
            Test.startTest();
            Map<String, Object> result = AccountMembershipController.checkMembershipStatus(
                true, true, true, true, true, true, true, true, true, true, true, false,
                false, true, // isExpired = false, anyStatus = ✅ true
                false, false, false, false, false, false, false, false, false, false
            );
            Test.stopTest();

            System.assertEquals(false, result.get('isAdmin'));
            System.assertEquals(true, result.get('hasActiveVetProLevelMembership'));
        }
    }
}