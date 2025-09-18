/**
 * @description       : 
 * @author            : Poojitha Anthati
 * @group             : 
 * @last modified on  : 09-18-2025
 * @last modified by  : Poojitha Anthati
**/
@IsTest
public class B2BSyncBuyerGroupsOnAccountTest {
    
    @TestSetup static void makeData(){
        String accountId = B2BTestDataFactory.createAccount();
    }

    @isTest static void testHandleBuyerGroupsSync() {
        Test.StartTest();
        Account account = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        List<Account> accounts = new List<Account>{account};

        B2BSyncBuyerGroupsOnAccount.handleBuyerGroupsSync(accounts);
        Test.StopTest();
    }
}