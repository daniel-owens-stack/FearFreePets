@IsTest
private class BatchFixCertificationStatusTest {
    
    @IsTest
    static void testBatchCertificationUpdate() {
        // Create a System Administrator user for System.runAs
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            Alias = 'testadm',
        Email = 'testadmin@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'TestAdmin',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = adminProfile.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = 'testadmin' + System.currentTimeMillis() + '@test.com'
            );
        insert adminUser;
        
        System.runAs(adminUser) {
            // Create Account and Contact
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            
            Contact con = new Contact(LastName = 'Test', AccountId = acc.Id);
            insert con;
            
            // Create Membership records
            Membership__c mem1 = new Membership__c(Name = 'Membership 1');
            Membership__c mem2 = new Membership__c(Name = 'Membership 2');
            insert new List<Membership__c>{mem1, mem2};
            
            // Create SX_Courses
            SX_Courses__c course1 = new SX_Courses__c(Name = 'Course 1');
            SX_Courses__c course2 = new SX_Courses__c(Name = 'Course 2');
            insert new List<SX_Courses__c>{course1, course2};
            
            // Link Certification_Course__c to Membership and Course
            Certification_Course__c certCourse1 = new Certification_Course__c(
                Membership__c = mem1.Id,
            SX_Course__c = course1.Id
                );
            Certification_Course__c certCourse2 = new Certification_Course__c(
                Membership__c = mem2.Id,
            SX_Course__c = course2.Id
                );
            insert new List<Certification_Course__c>{certCourse1, certCourse2};
            
            // Create SX_LMS_User__c record
            SX_LMS_User__c lmsUser = new SX_LMS_User__c(
                SX_User_ID__c = '12345678',
            SF_Contact__c = con.Id,
            SX_Active_User__c = true
                );
            insert lmsUser;
            
            // Create enrollments
            SX_Enrollment__c enrollment1 = new SX_Enrollment__c(
                Student_ID__c = lmsUser.Id,
            SF_Contact_Lookup__c = con.Id,
            SX_Course__c = course1.Id,
            SX_percent_Completed__c = 100
                );
            SX_Enrollment__c enrollment2 = new SX_Enrollment__c(
                Student_ID__c = lmsUser.Id,
            SF_Contact_Lookup__c = con.Id,
            SX_Course__c = course2.Id,
            SX_percent_Completed__c = 50
                );
            insert new List<SX_Enrollment__c>{enrollment1, enrollment2};
            
            // Create Account_Membership__c records
            // Insert with Certified__c = true to mimic prod automation
            // Insert am1
            Account_Membership__c am1 = new Account_Membership__c(
                Account_Id__c = acc.Id,
            Membership__c = mem1.Id,
            Certified__c = true,
            Status__c = 'Active'
                );
            insert am1;
            
            // Reset am1's Certified__c to false (simulate missed certification)
            am1.Certified__c = false;
            update am1;
            
            // Create am2 separately and insert
            Account_Membership__c am2 = new Account_Membership__c(
                Account_Id__c = acc.Id,
            Membership__c = mem2.Id,
            Certified__c = true,
            Status__c = 'Active'
                );
            insert am2;
            
            // Verify initial state of your test records directly
            Account_Membership__c am1Check = [SELECT Certified__c, Status__c FROM Account_Membership__c WHERE Id = :am1.Id];
            System.assertEquals(false, am1Check.Certified__c, 'am1 should initially not be certified');
            System.assertEquals('Active', am1Check.Status__c, 'am1 should be active');
            
            Account_Membership__c am2Check = [SELECT Certified__c, Status__c FROM Account_Membership__c WHERE Id = :am2.Id];
            System.assertEquals(true, am2Check.Certified__c, 'am2 should initially be certified');
            System.assertEquals('Active', am2Check.Status__c, 'am2 should be active');
            
            // Run batch
            Test.startTest();
            BatchFixCertificationStatus batch = new BatchFixCertificationStatus();
            Database.executeBatch(batch, 100);
            Test.stopTest();
            
            // Reload Account_Membership__c to verify updates
            Account_Membership__c updatedAm1 = [SELECT Certified__c FROM Account_Membership__c WHERE Id = :am1.Id];
            Account_Membership__c updatedAm2 = [SELECT Certified__c FROM Account_Membership__c WHERE Id = :am2.Id];
            
            // Verify results
            System.assertEquals(true, updatedAm1.Certified__c, 'am1 should be certified after batch');
            System.assertEquals(true, updatedAm2.Certified__c, 'am2 remains certified after batch');
            
            // Optionally check the batch variable updatedCount if accessible (you can make it @TestVisible in the batch class)
            // System.assertEquals(1, batch.updatedCount, 'Expected one record updated');
        }
    }
}