/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 07-29-2025 - FSM
 * @last modified by  : FSM
**/
public without sharing class AccountMembershipInvocable {
    
    // Inner class to define the input structure for the invocable method
    public class InputRequest {
        @InvocableVariable(label='Account ID' description='The ID of the Account to retrieve memberships for.')
        public Id accountId;
        @InvocableVariable(label='Memership Type ID' description='The ID of the Membership Type to retrieve memberships for.')
        public Id membershipTypeID;
    }

    // Inner class to define the output structure for the invocable method
    public class OutputResult {
        @InvocableVariable(label='Memberships' description='A list of Account Membership records associated with the Account.')
        public List<Account_Membership__c> memberships;
    }

    @InvocableMethod(label='Get Account Memberships' description='Returns all Account_Membership__c records for accounts belonging to a business')
    public static List<OutputResult> getAccountMemberships(List<InputRequest> requests) {
        List<OutputResult> results = new List<OutputResult>();
        Set<Id> accountIds = new Set<Id>();

        // Collect all unique Account IDs from the input requests
        for (InputRequest request : requests) {
            if (request.accountId != null) {
                accountIds.add(request.accountId);
            }
        }
        // Collect Membership Type ID from the first request
        Id membershipTypeId = requests[0].membershipTypeId;

        // Query for all Accounts with their membership records
        Map<Id, List<Account_Membership__c>> accountMembershipsMap = new Map<Id, List<Account_Membership__c>>();
        
        for (Account acc : [
            SELECT Id, Business__c,
                           (SELECT Id, Name, Assigned_Account_Name__c, Expiration_Date__c, Status__c, Membership__c, Membership_Name__c, Membership_Level__c ,Account_Assignment_Date__c, Related_Course_Completion__c, Certified__c, Employment_Type__c, CreatedDate
                            FROM Account_Memberships__r
                            WHERE Membership__c = :membershipTypeId
                            AND Status__c NOT IN ('Early', 'Voided')
                            ORDER BY Account_Assignment_Date__c DESC NULLS LAST
                            LIMIT 1)
                    FROM Account
            WHERE Business__c IN :accountIds
        ]) {
            // Get or create the list for this business account
            if (!accountMembershipsMap.containsKey(acc.Business__c)) {
                accountMembershipsMap.put(acc.Business__c, new List<Account_Membership__c>());
            }
            
            // Add all memberships from this account to the business account's list
            for (Account_Membership__c membership : acc.Account_Memberships__r) {
                accountMembershipsMap.get(acc.Business__c).add(membership);
            }
        }

        // Populate the results list, ensuring one OutputResult per InputRequest
        for (InputRequest request : requests) {
            OutputResult res = new OutputResult();
            if (request.accountId != null && accountMembershipsMap.containsKey(request.accountId)) {
                res.memberships = accountMembershipsMap.get(request.accountId);
            } else {
                res.memberships = new List<Account_Membership__c>(); // Return an empty list if no memberships or invalid Account ID
            }
            results.add(res);
        }

        return results;
    }
}