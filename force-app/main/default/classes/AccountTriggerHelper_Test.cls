/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2024-08-31 20:44:35
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:38:43
 * @ Description: Test class for  AccountTriggerHelper
 */

@IsTest
private class AccountTriggerHelper_Test {
	@TestSetup static void setup() {
		TestDataFactory.insertLMSUserData();
	}

	@IsTest static void testAccount() {
		System.debug('<============ testAccount ============>');
		List<Account> accList = [SELECT PersonEmail, PersonContactId FROM Account WHERE IsPersonAccount = TRUE];
		Test.startTest();
		Set<Id> conIds = new Set<Id>();
		for (Account acc : accList){
			acc.PersonEmail += 'a';
			conIds.add(acc.PersonContactId);
		}
		update accList;

		SchooxAPI.testResponse = SchooxAPI_Test.getMockResponse(200, SchooxAPI.ApiType.Users);
		SchooxAPI.testResponse.setBody('');
		AccountTriggerHelper.updateLMSUser(conIds);
		Test.stopTest();
	}
}