public class FFEnrollmentTriggerHandler {
    
    public static void processEnrollments(List<SX_Enrollment__c> enrollments) {
        // Filter to only certification enrollments
        List<SX_Enrollment__c> filtered = new List<SX_Enrollment__c>();
        // Collect contacts for CE credits
        Set<Id> contactIdsForCE = new Set<Id>();
        
        for (SX_Enrollment__c e : enrollments) {
            if (e.SX_percent_Completed__c == 100 &&
                e.SX_Course__c != null &&
            e.SF_Contact_Lookup__c != null) {
                filtered.add(e);
            }
            if (e.CE_Credits__c != null && e.SF_Contact_Lookup__c != null) {
                contactIdsForCE.add(e.SF_Contact_Lookup__c);
            }
        }
        if (filtered.isEmpty() && contactIdsForCE.isEmpty()) return;
        
        // ------------------------
        // Certification Logic (+ set Certification_Date__c from SX_Completed_Date__c)
        // ------------------------
        if (!filtered.isEmpty()) {
            Set<Id> courseIds = new Set<Id>();
            for (SX_Enrollment__c e : filtered) {
                courseIds.add(e.SX_Course__c);
            }
            
            // Map course -> set of Memberships
            Map<Id, Set<Id>> courseToMemberships = new Map<Id, Set<Id>>();
            for (Certification_Course__c cc : [
                SELECT Membership__c, SX_Course__c
                FROM Certification_Course__c
                WHERE SX_Course__c IN :courseIds
            ]) {
                if (!courseToMemberships.containsKey(cc.SX_Course__c)) {
                    courseToMemberships.put(cc.SX_Course__c, new Set<Id>());
                }
                courseToMemberships.get(cc.SX_Course__c).add(cc.Membership__c);
            }
            
            if (!courseToMemberships.isEmpty()) {
                // Build: (AccountId-MembershipId) -> earliest completed date from enrollments
                Map<String, Date> keyToEarliestCompletion = new Map<String, Date>();
                Set<Id> accountIds = new Set<Id>();
                Set<Id> membershipIdsAll = new Set<Id>();
                for (Set<Id> mems : courseToMemberships.values()) membershipIdsAll.addAll(mems);
                
                // Requery the filtered enrollments to get AccountId + completed date
                for (SX_Enrollment__c e : [
                    SELECT Id,
                           SF_Contact_Lookup__c,
                           SF_Contact_Lookup__r.AccountId,
                           SX_Course__c,
                           SX_Completed_Date__c
                    FROM SX_Enrollment__c
                    WHERE Id IN :filtered
                ]) {
                    if (e.SF_Contact_Lookup__r == null) continue;
                    Id accountId = e.SF_Contact_Lookup__r.AccountId;
                    if (accountId == null) continue;
                    if (!courseToMemberships.containsKey(e.SX_Course__c)) continue;
                    
                    // Pull completion date as Date regardless of field type (Date vs Datetime)
                    Date completionDate;
                    Object o = e.get('SX_Completed_Date__c'); // dynamic access covers Date or Datetime
                    if (o != null) {
                        if (o instanceof Date)        completionDate = (Date)o;
                        else if (o instanceof Datetime) completionDate = ((Datetime)o).date();
                    }
                    // Only proceed if we have a completion date
                    if (completionDate == null) continue;
                    
                    accountIds.add(accountId);
                    for (Id memId : courseToMemberships.get(e.SX_Course__c)) {
                        String key = accountId + '-' + memId;
                        if (!keyToEarliestCompletion.containsKey(key) || completionDate < keyToEarliestCompletion.get(key)) {
                            keyToEarliestCompletion.put(key, completionDate);
                        }
                    }
                }
                
                if (!keyToEarliestCompletion.isEmpty()) {
                    // Pull the relevant ILMAs (Account_Membership__c) and update
                    List<Account_Membership__c> amsToUpdate = new List<Account_Membership__c>();
                    for (Account_Membership__c am : [
                        SELECT Id, Certified__c, Certification_Date__c, Account_Id__c, Membership__c
                        FROM Account_Membership__c
                        WHERE Account_Id__c IN :accountIds
                          AND Membership__c IN :membershipIdsAll
                    ]) {
                        String key = am.Account_Id__c + '-' + am.Membership__c;
                        if (!keyToEarliestCompletion.containsKey(key)) continue;
                        
                        Date newDate = keyToEarliestCompletion.get(key);
                        Boolean changed = false;
                        
                        // Ensure Certified__c is true
                        if (!am.Certified__c) { am.Certified__c = true; changed = true; }
                        
                        // Set date if blank, or keep the earliest date (optional min logic)
                        if (am.Certification_Date__c == null) {
                            am.Certification_Date__c = newDate;
                            changed = true;
                        } else if (newDate != null && newDate < am.Certification_Date__c) {
                            // If you never want to overwrite an existing date, remove this branch.
                            am.Certification_Date__c = newDate;
                            changed = true;
                        }
                        
                        if (changed) amsToUpdate.add(am);
                    }
                    
                    if (!amsToUpdate.isEmpty()) {
                        update amsToUpdate;
                    }
                }
            }
        }
        
        // ------------------------
        // CE Credits Roll-Up Logic (unchanged)
        // ------------------------
        if (!contactIdsForCE.isEmpty()) {
            Map<Id, Decimal> contactToCE = new Map<Id, Decimal>();
            for (AggregateResult ar : [
                SELECT SF_Contact_Lookup__c contactId, SUM(CE_Credits__c) totalCE
                FROM SX_Enrollment__c
                WHERE SF_Contact_Lookup__c IN :contactIdsForCE
                AND CE_Credits__c != null
                GROUP BY SF_Contact_Lookup__c
            ]) {
                contactToCE.put((Id)ar.get('contactId'), (Decimal)ar.get('totalCE'));
            }
            
            if (!contactToCE.isEmpty()) {
                List<Account> accountsToUpdate = new List<Account>();
                for (Contact c : [
                    SELECT Id, AccountId
                    FROM Contact
                    WHERE Id IN :contactToCE.keySet()
                    AND AccountId != null
                ]) {
                    Decimal total = contactToCE.get(c.Id);
                    accountsToUpdate.add(new Account(
                        Id = c.AccountId,
                    CE_Credits__c = total
                        ));
                }
                if (!accountsToUpdate.isEmpty()) {
                    update accountsToUpdate;
                }
            }
        }
    }
}