@IsTest
public class directoryMembersControllerTest {

    @TestSetup
    static void setup() {
        // Create a parent Account
        Account parentAccount = new Account(Name = 'Parent Account');
        insert parentAccount;
    
        // Create child Accounts associated with the parent Account
        List<Account> childAccounts = new List<Account>{
            new Account(Name = 'Child Account 1', Business__c = parentAccount.Id, Directory_Opt_In__c = true),
            new Account(Name = 'Child Account 2', Business__c = parentAccount.Id, Directory_Opt_In__c = true),
            new Account(Name = 'Child Account 3', Business__c = parentAccount.Id, Directory_Opt_In__c = true)
        };
        insert childAccounts;
    
        // Create Account_Membership__c records to satisfy the filter in the SOQL
        List<Account_Membership__c> memberships = new List<Account_Membership__c>();
        for (Account acc : childAccounts) {
            memberships.add(new Account_Membership__c(
                Account_Id__c = acc.Id,
                Certified__c = true,
                Status__c = 'Active'
            ));
        }
        insert memberships;
    }
    

    @IsTest
    static void testGetChildAccounts() {
        // Get the parent account's Id
        Account parentAccount = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1];
        
        // Start the test
        Test.startTest();
        List<Account> results = directoryMembersController.getChildAccounts(parentAccount.Id);
        Test.stopTest();

        // Validate the results
        System.assertEquals(3, results.size(), 'The method should return 3 child accounts');
        Set<String> expectedChildNames = new Set<String>{'Child Account 1', 'Child Account 2', 'Child Account 3'};
        for (Account acc : results) {
            System.assert(expectedChildNames.contains(acc.Name), 'The returned account name should be one of the expected child accounts');
        }
    }

    @IsTest
    static void testGetChildAccounts_NoChildren() {
        // Create a parent account without children
        Account noChildParent = new Account(Name = 'No Child Parent Account');
        insert noChildParent;

        // Start the test
        Test.startTest();
        List<Account> results = directoryMembersController.getChildAccounts(noChildParent.Id);
        Test.stopTest();

        // Validate that no child accounts are returned
        System.assertEquals(0, results.size(), 'The method should return 0 child accounts for a parent with no children');
    }

    @IsTest
    static void testGetChildAccounts_InvalidParentId() {
        // Start the test
        Test.startTest();
        List<Account> results = directoryMembersController.getChildAccounts('InvalidParentId');
        Test.stopTest();

        // Validate that no accounts are returned for an invalid parent Id
        System.assertEquals(0, results.size(), 'The method should return 0 accounts for an invalid parent Id');
    }
}