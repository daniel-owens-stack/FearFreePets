@IsTest
private class BatchCreateILMAsFromCSVTest {

    // Sample CSV content - header + 2 data rows
    private static final String SAMPLE_CSV = 'GroupId,LeaderId,GroupName,UserLimit\n' +
                                             'G1,L1,Veterinary Certification Membership,2\n' +
                                             'G2,L2,Groomer Certification,1';

    @TestSetup
    static void setupTestData() {
        // Create test Accounts with Original_System_ID__c
        insert new Account(Name='Group 1', Original_System_ID__c='G1');
        insert new Account(Name='Leader 1', Original_System_ID__c='L1');
        insert new Account(Name='Group 2', Original_System_ID__c='G2');
        insert new Account(Name='Leader 2', Original_System_ID__c='L2');

        // Create Membership__c records matching names used in batch
        insert new Membership__c(Name='Veterinary Professional Membership');
        insert new Membership__c(Name='Groomer Membership');
        insert new Membership__c(Name='Pet Sitter Membership');
        insert new Membership__c(Name='Trainer Membership');
        insert new Membership__c(Name='Boarding & Daycare Individual Membership');
    }

    @IsTest
    static void testBatchExecuteAndStart() {
        // Query accounts to get Ids
        Map<String, Id> osidToId = new Map<String, Id>();
        for (Account a : [SELECT Id, Original_System_ID__c FROM Account WHERE Original_System_ID__c IN ('G1','L1','G2','L2')]) {
            osidToId.put(a.Original_System_ID__c, a.Id);
        }

        // Query memberships
        Map<String, Id> membershipMap = new Map<String, Id>();
        for (Membership__c m : [SELECT Id, Name FROM Membership__c WHERE Name LIKE '%Membership']) {
            if (m.Name.containsIgnoreCase('Veterinary')) membershipMap.put('Veterinary', m.Id);
            else if (m.Name.containsIgnoreCase('Groomer')) membershipMap.put('Groomer', m.Id);
            else if (m.Name.containsIgnoreCase('Pet Sitter')) membershipMap.put('Pet Sitter', m.Id);
            else if (m.Name.containsIgnoreCase('Trainer')) membershipMap.put('Trainer', m.Id);
            else if (m.Name.containsIgnoreCase('Boarding')) membershipMap.put('Boarding', m.Id);
        }

        Test.startTest();
        
        // Use the overloaded constructor injecting CSV content directly to cover start()
        BatchCreateILMAsFromCSV batch = new BatchCreateILMAsFromCSV('DummyResource', SAMPLE_CSV);
        Database.executeBatch(batch);

        Test.stopTest();

        // Verify Account_Membership__c records created correctly
        List<Account_Membership__c> insertedMemberships = [
            SELECT Id, Membership__c, Purchaser_Account__c, Parent_Id__c, Status__c
            FROM Account_Membership__c
        ];

        System.assertEquals(3, insertedMemberships.size(), 'Expected 3 Account_Membership__c records inserted');

        // Check that memberships are linked properly
        Integer vetCount = 0;
        Integer groomerCount = 0;
        for (Account_Membership__c am : insertedMemberships) {
            System.assertEquals('Active', am.Status__c, 'Status should be Active');
            if (am.Membership__c == membershipMap.get('Veterinary')) vetCount++;
            else if (am.Membership__c == membershipMap.get('Groomer')) groomerCount++;
        }
        System.assertEquals(2, vetCount, 'Should have 2 veterinary memberships');
        System.assertEquals(1, groomerCount, 'Should have 1 groomer membership');
    }

    @IsTest
    static void testExecuteWithInvalidData() {
        // Prepare invalid CSV content with blank fields and invalid userLimit
        String invalidCsv = 'GroupId,LeaderId,GroupName,UserLimit\n' +
                            ',L1,Veterinary Certification Membership,2\n' +    // Missing GroupId
                            'G1,,Groomer Certification,abc\n' +                 // Invalid userLimit
                            'G2,L2,Unrecognized Group,1\n' +                    // Unrecognized group name
                            'G2,L2,Trainer Certification,0\n';                  // userLimit zero

        Test.startTest();
        BatchCreateILMAsFromCSV batch = new BatchCreateILMAsFromCSV('DummyResource', invalidCsv);
        Database.executeBatch(batch);
        Test.stopTest();

        // No records should be inserted
        Integer count = [SELECT count() FROM Account_Membership__c];
        System.assertEquals(0, count, 'No memberships should be inserted for invalid data');
    }
}