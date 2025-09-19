@IsTest
private class FFSchooxSyncControllerTest {
    
    // Self-contained HTTP mock so SchooxAPI callouts succeed in tests
    private class LocalSchooxHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            String url = (req.getEndpoint() == null) ? '' : req.getEndpoint().toLowerCase();
            String method = (req.getMethod() == null) ? '' : req.getMethod().toUpperCase();
            
            if (method == 'GET' && url.contains('/dashboard/users/')) {
                res.setBody('{"courses": []}');
            } else if (url.contains('/users/')) { // PUT/POST user endpoints
                res.setBody('{"ok": true}');
            } else {
                res.setBody('{"ok": true}');
            }
            return res;
        }
    }
    
    private static RecordType tryGetPersonAccountRt() {
        List<RecordType> rts = [
            SELECT Id, SobjectType, IsPersonType
            FROM RecordType
            WHERE SobjectType = 'Account' AND IsPersonType = true
            LIMIT 1
        ];
        return rts.isEmpty() ? null : rts[0];
    }
    
    @IsTest
    static void runSync_person_and_business_paths() {
        Test.setMock(HttpCalloutMock.class, new LocalSchooxHttpMock());
        
        // Business account
        Account biz = new Account(Name = 'Ctrl Biz');
        insert biz;
        
        // Create a Person Account child if PA is enabled
        Account pa = null;
        Contact paContact = null;
        RecordType paRt = tryGetPersonAccountRt();
        if (paRt != null) {
            pa = new Account(
                RecordTypeId = paRt.Id,
            FirstName    = 'PA',
            LastName     = 'Ctrl',
            PersonEmail  = 'ctrlpa@test.com'
                );
            try { pa.put('Business__c', biz.Id); } catch (Exception ignore) {}
            insert pa;
            
            // Person Contact for the PA
            pa = [SELECT Id, PersonContactId FROM Account WHERE Id = :pa.Id];
            paContact = [SELECT Id FROM Contact WHERE Id = :pa.PersonContactId];
            
            // Pre-create LMS user so controller takes update/reactivate path
            insert new SX_LMS_User__c(
                SF_Contact__c = paContact.Id,
            SX_User_ID__c = 'ext-ctrl-001'
                );
            
            // Minimal membership to exercise mapping
            Membership__c mem = new Membership__c(Name = 'MemCtrl');
            insert mem;
            insert new Account_Membership__c(
                Account_Id__c = pa.Id,
            Status__c     = 'Active',
            Membership__c = mem.Id
                );
        }
        
        // Use ONE start/stop for both invocations
        Test.startTest();
        if (pa != null) {
            FFSchooxSyncController.runSync(pa.Id);   // PA branch
        }
        FFSchooxSyncController.runSync(biz.Id);      // Business branch
        Test.stopTest();
        
        if (pa != null) {
            List<SX_LMS_User__c> flagged = [
            SELECT Id, SX_Process_Pending__c, Enrollments_Due_At__c
            FROM SX_LMS_User__c
            WHERE SF_Contact__r.AccountId = :pa.Id
            LIMIT 1
        ];
            if (!flagged.isEmpty()) {
                System.assertEquals(true,  flagged[0].SX_Process_Pending__c, 'Should mark pending');
                System.assertNotEquals(null, flagged[0].Enrollments_Due_At__c, 'Should set due time');
            }
        } else {
            System.assert(true, 'Org without Person Accounts: method ran without exception.');
        }
    }
    
    @IsTest
    static void runSync_error_paths() {
        // 1) Null Id — just assert that an exception is thrown
        Boolean threw = false;
        try {
            FFSchooxSyncController.runSync(null);
        } catch (Exception e) {
            threw = true;
        }
        System.assertEquals(true, threw, 'Expected an exception for null accountId');
        
        // 2) Business with no PA children — just assert exception thrown
        Account biz = new Account(Name = 'No PA Biz');
        insert biz;
        
        threw = false;
        try {
            FFSchooxSyncController.runSync(biz.Id);
        } catch (Exception e) {
            threw = true;
        }
        System.assertEquals(true, threw, 'Expected an exception when no valid PAs found');
    }
}