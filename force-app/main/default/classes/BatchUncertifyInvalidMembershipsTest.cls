@IsTest
private class BatchUncertifyInvalidMembershipsTest {
    
    @IsTest
    static void testBatchUncertifyInvalids() {
        // Create a System Administrator user for System.runAs
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            Alias = 'testadm2',
            Email = 'testadmin2@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestAdmin2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testadmin2' + System.currentTimeMillis() + '@test.com'
        );
        insert adminUser;
        
        System.runAs(adminUser) {
            // Create Account + Contact
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            
            Contact con = new Contact(LastName = 'Tester', AccountId = acc.Id);
            insert con;
            
            // Create Memberships
            Membership__c mem1 = new Membership__c(Name = 'Membership A');
            Membership__c mem2 = new Membership__c(Name = 'Membership B');
            insert new List<Membership__c>{mem1, mem2};
            
            // Create SX_Courses
            SX_Courses__c course1 = new SX_Courses__c(Name = 'Course A');
            SX_Courses__c course2 = new SX_Courses__c(Name = 'Course B');
            insert new List<SX_Courses__c>{course1, course2};
            
            // Link Memberships to Courses via Certification_Course__c
            insert new List<Certification_Course__c>{
                new Certification_Course__c(Membership__c = mem1.Id, SX_Course__c = course1.Id),
                new Certification_Course__c(Membership__c = mem2.Id, SX_Course__c = course2.Id)
            };
            
            // Create SX_LMS_User__c
            SX_LMS_User__c lmsUser = new SX_LMS_User__c(
                SX_User_ID__c = '987654321',
                SF_Contact__c = con.Id,
                SX_Active_User__c = true
            );
            insert lmsUser;
            
            // Create enrollment for only course1 (100%)
            SX_Enrollment__c enrollment1 = new SX_Enrollment__c(
                Student_ID__c = lmsUser.Id,
                SF_Contact_Lookup__c = con.Id,
                SX_Course__c = course1.Id,
                SX_percent_Completed__c = 100
            );
            insert enrollment1;
            
            // Account_Membership__c: mark both as Certified=true initially
            Account_Membership__c am1 = new Account_Membership__c(
                Account_Id__c = acc.Id,
                Membership__c = mem1.Id,
                Certified__c = true,
                Status__c = 'Active'
            );
            Account_Membership__c am2 = new Account_Membership__c(
                Account_Id__c = acc.Id,
                Membership__c = mem2.Id,
                Certified__c = true,
                Status__c = 'Active'
            );
            insert new List<Account_Membership__c>{am1, am2};
            
            // Verify setup
            System.assertEquals(true, [SELECT Certified__c FROM Account_Membership__c WHERE Id = :am1.Id].Certified__c, 'am1 should start certified');
            System.assertEquals(true, [SELECT Certified__c FROM Account_Membership__c WHERE Id = :am2.Id].Certified__c, 'am2 should start certified');
            
            // Run batch
            Test.startTest();
            BatchUncertifyInvalidMemberships batch = new BatchUncertifyInvalidMemberships();
            Database.executeBatch(batch, 100);
            Test.stopTest();
            
            // Reload records
            Account_Membership__c updatedAm1 = [SELECT Certified__c FROM Account_Membership__c WHERE Id = :am1.Id];
            Account_Membership__c updatedAm2 = [SELECT Certified__c FROM Account_Membership__c WHERE Id = :am2.Id];
            
            // Assertions
            System.assertEquals(true, updatedAm1.Certified__c,
                'am1 should remain certified since enrollment was completed');
            System.assertEquals(false, updatedAm2.Certified__c,
                'am2 should be uncertified since no enrollment exists for its course');
        }
    }
}