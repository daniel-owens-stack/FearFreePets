@IsTest
public class B2BBuyerGroupAssignmentInvocableTest {
    
    @TestSetup static void makeData(){
        String accountId = B2BTestDataFactory.createAccount();
    }

    @isTest static void testHandleTeamAdminChange() {
        Test.StartTest();
        Account account = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        List<Account> accounts = new List<Account>{account};

        B2BBuyerGroupAssignmentInvocable.handleTeamAdminChange(accounts);
        Test.StopTest();
    }
}