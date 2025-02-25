@IsTest
public class B2BBatchApexInvocableTest {
    
    @isTest static void testExecuteBatchable() {
        B2BTestDataFactory.createAccount();

        Test.StartTest();
        try {
            B2BBatchApexInvocable.executeBatchable(new List<String>{'B2BBatchClassMock'});
        } 
        catch (Exception e) {}
        Test.StopTest();
    }

    @isTest static void testExecuteBatchable_exception() {
        B2BTestDataFactory.createAccount();

        Test.StartTest();
        try {
            B2BBatchApexInvocable.executeBatchable(new List<String>{'TestClass'});
        } 
        catch (Exception e) {}
        Test.StopTest();
    }
}