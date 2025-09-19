/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2024-08-16 23:26:56
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:38:46
 * @ Description: Test class is  AccountTriggerHelper_Test
 */

public with sharing class AccountTriggerHelper {
	public static Boolean hasExecuted = false;
	public static Integer executingStack = 0;
	private Boolean m_isExecuting = false;
	private Integer BatchSize = 0;
	public static Boolean isError = false;
	private Boolean isTriggerInsert = false;
	private Boolean isTriggerUpdate = false;
	private Boolean isTriggerDelete = false;
	private Boolean isTriggerBefore = false;
	private Boolean isTriggerAfter = false;
	public AccountTriggerHelper(Boolean isExecuting, Integer size) {
		executingStack++;
		m_isExecuting = isExecuting;
		BatchSize = size;
	}

	public void handleTrigger(List<Account> newAccountList, Map<Id, Account> newAccountMap, List<Account> oldAccountList, Map<Id, Account> oldAccountMap, System.TriggerOperation triggerEvent ) {
		try {
			System.debug('triggerEvent AccountTriggerHelper: ' + triggerEvent + ' ' + executingStack);
			if (executingStack < 2) {
				switch on triggerEvent {
					when AFTER_UPDATE {
						isTriggerAfter = true;
						isTriggerUpdate = true;
						handleLMSUser(newAccountList, oldAccountMap);
					}

					when else {
						//TODO: do nothing
						System.debug('Nothing');
					}
				}
			}

		} catch (Exception ex) {
			Utility.printException(ex);
		}
	}

	private static void handleLMSUser(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
		System.debug('----------- handleLMSUser Start -----------');
		List<SX_LMS_User__c> studentList = new List<SX_LMS_User__c>();
		Set<Id> conIds = new Set<Id>();
		for (Account newAcc : newAccountList) {
			Account oldAcc = oldAccountMap.get(newAcc.Id);
			if (newAcc.SX_LMS_User__pc != null) {
				if ( newAcc.SX_Active_User__pc != oldAcc.SX_Active_User__pc) {
					studentList.add(new SX_LMS_User__c(Id = newAcc.SX_LMS_User__pc, SX_Active_User__c = newAcc.SX_Active_User__pc));
				} else if (newAcc.FirstName != oldAcc.FirstName || newAcc.LastName != oldAcc.LastName || newAcc.PersonEmail != oldAcc.PersonEmail) {
					conIds.add(newAcc.PersonContactId);
				}
			}
		}
		System.debug('studentList: ' + studentList.size());
		System.debug(JSON.serializePretty(studentList));
		update studentList;

		System.debug('conIds: ' + conIds.size());
		if (!conIds.isEmpty()) {
			updateLMSUser(conIds);
		}

		System.debug('----------- handleLMSUser End -----------');
	}

	@TestVisible
	@Future(Callout=true)
	private static void updateLMSUser(Set<Id> conIds) {
		System.debug('----------- updateLMSUser for Activate / Deactivate Start -----------');
		for (Id conId : conIds) {
			SchooxAPI.updateLMSUser(conId, null);
		}
		System.debug('----------- updateLMSUser for Activate / Deactivate End -----------');
	}
}