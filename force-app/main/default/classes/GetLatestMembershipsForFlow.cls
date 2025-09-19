public with sharing class GetLatestMembershipsForFlow {
    public class Request {
        @InvocableVariable(required=true)
        public String businessId;  // Business__c value to filter accounts
        
        @InvocableVariable(required=false)
        public String customQuery; // Optional custom SOQL query
    }

    public class MembershipWrapper {
        @InvocableVariable public Id MembershipId;
        @InvocableVariable public String MembershipName;
        @InvocableVariable public Datetime CreatedDate;
        @InvocableVariable public Id AccountId;
        @InvocableVariable public String AccountName;
    }

    @InvocableMethod(label='Get Latest Account Memberships')
    public static List<MembershipWrapper> fetch(List<Request> requests) {
        List<MembershipWrapper> results = new List<MembershipWrapper>();

        if (requests == null || requests.isEmpty()) return results;

        for (Request req : requests) {
            String queryString;

            if (String.isNotBlank(req.customQuery)) {
                queryString = req.customQuery;
            } else {
                queryString = 
                    'SELECT Id, Name, ' +
                    '(SELECT Id, Name, CreatedDate ' +
                    ' FROM Account_Memberships__r ' +
                    ' ORDER BY CreatedDate DESC LIMIT 1) ' +
                    'FROM Account ' +
                    'WHERE Business__c = \'' + String.escapeSingleQuotes(req.businessId) + '\'';
            }

            List<Account> accounts = Database.query(queryString);

            for (Account acc : accounts) {
                if (acc.Account_Memberships__r != null && !acc.Account_Memberships__r.isEmpty()) {
                    Account_Membership__c mem = acc.Account_Memberships__r[0];
                    MembershipWrapper mw = new MembershipWrapper();
                    mw.MembershipId = mem.Id;
                    mw.MembershipName = mem.Name;
                    mw.CreatedDate = mem.CreatedDate;
                    mw.AccountId = acc.Id;
                    mw.AccountName = acc.Name;
                    results.add(mw);
                }
            }
        }
        return results;
    }
}