/**
 * @ Author: Gary Guthrie
 * @ Create Time: 2022-11-11 09:09:44
 * @ Modified by: Gary Guthrie
 * @ Modified time: 2022-11-18 06:49:27
 * @ Description:
 */

@isTest
private class Utility_Test {
    @testSetup static void setup() {
        TestDataFactory.insertAccountData();
    }

    @isTest static void testUtility() {
        System.debug('testUtility');     
        Test.startTest();
        Utility.decimalValue((Object) '123');
        Utility.integerValue((Object) '123');
        Utility.booleanValue((Object) 'true');
        Utility.dateValue((Object) '2022-07-01');
        
        List<Account> accountList = [SELECT Id FROM Account LIMIT 1];        
        Utility.updateObject(accountList.get(0));
        try {
            Utility.insertObject(accountList.get(0));
        } catch (Exception ex) {
            Utility.printException(ex);
        }
        try {
            Utility.insertObject(accountList.get(2));
        } catch (Exception ex) {
            Utility.printException(ex);
        }
        Test.stopTest();
	}
}