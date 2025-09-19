@isTest
private class FFMembershipStatusControllerTest {
    private static User portalUser;
    
    @TestSetup
    static void setup() {
        // Get portal profile
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Fear Free Community Member' LIMIT 1];
        
        // Create business account
        Account businessAccount = new Account(Name = 'Business Account');
        insert businessAccount;
        
        // Create Person Account
        RecordType paRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1];
        Account personAccount = new Account(
            FirstName = 'Test',
        LastName = 'PortalUser',
        RecordTypeId = paRt.Id,
        Admin_Account__c = true,
        Business__c = businessAccount.Id
            );
        insert personAccount;
        
        // Lookup related contact
        Contact contact = [SELECT Id FROM Contact WHERE AccountId = :personAccount.Id LIMIT 1];
        
        // Create portal user (linked to contact)
        User tempUser = new User(
            Alias = 'portal',
        Email = 'portal@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Portal',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'portaluser' + System.currentTimeMillis() + '@test.com',
        ProfileId = portalProfile.Id,
        ContactId = contact.Id,
        CommunityNickname = 'portaluser',
        IsActive = true
            );
        insert tempUser;
        
        // ✅ Re-query to get AccountId assigned by system
        portalUser = [SELECT Id, Email, AccountId FROM User WHERE Id = :tempUser.Id];
        System.assertNotEquals(null, portalUser.AccountId, 'portalUser.AccountId should be populated after insert');
        
        // Create Memberships
        List<Membership__c> memberships = new List<Membership__c>{
            new Membership__c(Name = 'Academia Membership'),
            new Membership__c(Name = 'Veterinary Professional Membership'),
            new Membership__c(Name = 'Veterinary Practice Certification'),
            new Membership__c(Name = 'Groomer Membership'),
            new Membership__c(Name = 'Pet Sitter Membership'),
            new Membership__c(Name = 'Boarding & Daycare'),
            new Membership__c(Name = 'Trainer Membership')
        };
        insert memberships;
        
        Map<String, Id> membershipMap = new Map<String, Id>();
        for (Membership__c m : memberships) {
            membershipMap.put(m.Name, m.Id);
        }
        
        // Active memberships
        insert new List<Account_Membership__c>{
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Active', Membership__c = membershipMap.get('Academia Membership')),
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Active', Membership__c = membershipMap.get('Groomer Membership')),
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Active', Membership__c = membershipMap.get('Pet Sitter Membership')),
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Active', Membership__c = membershipMap.get('Boarding & Daycare')),
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Active', Membership__c = membershipMap.get('Trainer Membership'))
        };
        
        // Expired (Complete) memberships
        insert new List<Account_Membership__c>{
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Complete', Membership__c = membershipMap.get('Veterinary Practice Certification')),
            new Account_Membership__c(Account_Id__c = personAccount.Id, Status__c = 'Complete', Membership__c = membershipMap.get('Veterinary Professional Membership'))
        };
        
        // PLMA record for business account
        insert new Practice_Level_Membership_Assignment__c(
            Status__c = 'Complete',
        Business_Account__c = businessAccount.Id,
        Membership__c = membershipMap.get('Veterinary Practice Certification')
            );
    }
    
    @isTest
    static void testGetMembershipStatus_PortalUser() {
        portalUser = [SELECT Id, AccountId FROM User WHERE Email = 'portal@test.com' LIMIT 1];
        System.runAs(portalUser) {
            Test.startTest();
            FFMembershipStatusController.MembershipStatus result = FFMembershipStatusController.getMembershipStatus();
            Test.stopTest();
            
            System.assertNotEquals(null, result);
            System.assertEquals(true, result.isAdmin);
            System.assertEquals(true, result.hasActiveAcademia);
            System.assertEquals(true, result.hasActiveGroomer);
            System.assertEquals(true, result.hasActiveSitter);
            System.assertEquals(true, result.hasActiveBDC);
            System.assertEquals(true, result.hasActiveTrainer);
            System.assertEquals(true, result.hasExpiredPLMA); // via PLMA
            System.assertEquals(true, result.hasExpiredVPC);  // via Account Membership
            System.assertEquals(true, result.hasExpiredVet);
        }
    }
}