global class BatchCreateILMAsFromCSV implements Database.Batchable<String> {
    global String staticResourceName;
    private String csvContent; // Optional override for testing

    global BatchCreateILMAsFromCSV(String staticResourceName) {
        this.staticResourceName = staticResourceName;
    }

    // Overloaded constructor for test injection
    global BatchCreateILMAsFromCSV(String staticResourceName, String csvContent) {
        this.staticResourceName = staticResourceName;
        this.csvContent = csvContent;
    }

    global Iterable<String> start(Database.BatchableContext BC) {
        List<String> rows = new List<String>();

        String csvBody;

        // Use test-injected content if present
        if (Test.isRunningTest() && String.isNotBlank(csvContent)) {
            csvBody = csvContent;
        } else {
            StaticResource sr = [
                SELECT Body FROM StaticResource WHERE Name = :staticResourceName LIMIT 1
            ];
            csvBody = sr.Body.toString();
        }

        rows = csvBody.split('\n');

        // Remove header
        if (!rows.isEmpty()) {
            rows.remove(0);
        }

        return rows;
    }

    global void execute(Database.BatchableContext BC, List<String> scope) {
        Map<String, Id> accountMap = new Map<String, Id>();
        Map<String, Id> membershipMap = new Map<String, Id>();

        // Collect IDs from the CSV lines
        Set<String> osids = new Set<String>();
        for (String line : scope) {
            List<String> columns = line.split(',');
            if (columns.size() >= 4) {
                String groupId = columns[0]?.trim();
                String leaderId = columns[1]?.trim();
                if (String.isNotBlank(groupId)) osids.add(groupId);
                if (String.isNotBlank(leaderId)) osids.add(leaderId);
            }
        }

        if (!osids.isEmpty()) {
            for (Account a : [
                SELECT Id, Original_System_ID__c
                FROM Account
                WHERE Original_System_ID__c IN :osids
            ]) {
                accountMap.put(a.Original_System_ID__c, a.Id);
            }
        }

        for (Membership__c m : [
            SELECT Id, Name 
            FROM Membership__c 
            WHERE Name = 'Veterinary Professional Membership' 
               OR Name = 'Groomer Membership'
               OR Name = 'Pet Sitter Membership' 
               OR Name = 'Trainer Membership'
               OR Name = 'Boarding & Daycare Individual Membership'
        ]) {
            if (m.Name.containsIgnoreCase('Veterinary')) membershipMap.put('Veterinary', m.Id);
            else if (m.Name.containsIgnoreCase('Groomer')) membershipMap.put('Groomer', m.Id);
            else if (m.Name.containsIgnoreCase('Pet Sitter')) membershipMap.put('Pet Sitter', m.Id);
            else if (m.Name.containsIgnoreCase('Trainer')) membershipMap.put('Trainer', m.Id);
            else if (m.Name.containsIgnoreCase('Boarding')) membershipMap.put('Boarding', m.Id);
        }

        List<Account_Membership__c> membershipsToInsert = new List<Account_Membership__c>();

        for (String line : scope) {
            List<String> columns = line.split(',');
            if (columns.size() < 4) continue;

            String groupId = columns[0]?.trim();
            String leaderId = columns[1]?.trim();
            String groupName = columns[2]?.trim();

            if (String.isBlank(groupId) || String.isBlank(leaderId) || String.isBlank(groupName)) {
                System.debug('Skipping row with missing fields: ' + line);
                continue;
            }

            Integer userLimit;
            try {
                userLimit = Integer.valueOf(columns[3]?.trim());
            } catch (Exception e) {
                System.debug('Invalid userLimit in row: ' + line);
                continue;
            }

            if (userLimit <= 0) {
                System.debug('Skipping due to nonpositive userLimit: ' + line);
                continue;
            }

            Id purchaserId = accountMap.get(groupId);
            Id leaderSfId = accountMap.get(leaderId);
            Id membershipId;

            if (purchaserId == null || leaderSfId == null) {
                System.debug('Missing account(s) for row: ' + line);
                continue;
            }

           List <Account_Membership__c> existingAvailableMemberships = [
                SELECT Id, Membership__c 
                FROM Account_Membership__c 
                WHERE  Parent_Id__c = :leaderSfId 
                AND Status__c = 'Active'
                AND Account_Id__c = null
            ];

            if (!existingAvailableMemberships.isEmpty()) {
                System.debug('Skipping row due to existing unassigned memberships for leader already inserted: ' + leaderSfId);
                continue;
            }

            if (groupName.containsIgnoreCase('Veterinary Certification Membership')) {
                membershipId = membershipMap.get('Veterinary');
            } else if (groupName.containsIgnoreCase('Groomer Certification')) {
                membershipId = membershipMap.get('Groomer');
            } else if (groupName.containsIgnoreCase('Pet Sitter Certification')) {
                membershipId = membershipMap.get('Pet Sitter');
            } else if (groupName.containsIgnoreCase('Trainer Certification')) {
                membershipId = membershipMap.get('Trainer');
            } else if (groupName.containsIgnoreCase('Boarding and Daycare Certification')) {
                membershipId = membershipMap.get('Boarding');
            } else {
                System.debug('Unrecognized group name: ' + groupName);
                continue;
            }

            if (membershipId == null) {
                System.debug('No matching Membership__c record found for: ' + groupName);
                continue;
            }

            for (Integer i = 0; i < userLimit; i++) {
                membershipsToInsert.add(new Account_Membership__c(
                    Membership__c = membershipId,
                    Purchaser_Account__c = purchaserId,
                    Parent_Id__c = leaderSfId,
                    Status__c = 'Active'
                ));
            }
        }

        if (!membershipsToInsert.isEmpty()) {
            try {
                insert membershipsToInsert;
                System.debug('Inserted ' + membershipsToInsert.size() + ' memberships');
            } catch (DmlException e) {
                System.debug('DML Error: ' + e.getMessage());
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    System.debug('DML failure at index ' + e.getDmlIndex(i) + ': ' + e.getDmlMessage(i));
                }
                throw e;
            }
        } else {
            System.debug('No records to insert');
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch finished');
    }
}