@isTest
public class B2BBuyerGroupAssignemntControllerTest {
    
    // @TestSetup static void makeData(){
    //     B2BTestDataFactory.createWebStore();
    //     String webStoreId  = [SELECT Id FROM WebStore WHERE Name = 'TestWebStore' LIMIT 1].Id;
    //     String accountId = B2BTestDataFactory.createAccount();
    //     String contactId = B2BTestDataFactory.createContact(accountId);
    //     User user = B2BTestDataFactory.createCommunityUser(contactId);
    //     B2BTestDataFactory.createWebCart(webStoreId, accountId, user.Id);
    //     B2BTestDataFactory.createProduct();

    //     Membership__c m = new Membership__c(
    //         Name = 'Test Membership'
    //     );
    //     insert m;

    //     BuyerAccount ba = new BuyerAccount(
    //         BuyerId = accountId,
    //         Name = 'Test Buyer Account',
    //         IsActive = true
    //     );
    //     insert ba;

    //     BuyerGroup bg = [SELECT Id FROM BuyerGroup WHERE Name = 'Test Buyer Group' LIMIT 1];

    //     BuyerGroupMember bg_member = new BuyerGroupMember(
    //         BuyerId = accountId,
    //         BuyerGroupId = bg.Id
    //     );
    //     insert bg_member;

    //     Buyer_Group_Membership__c bg_membership = new Buyer_Group_Membership__c(
    //         Membership__c = m.Id,
    //         Buyer_Group__c = bg.Id,
    //         Certified__c = true
    //     );
    //     insert bg_membership;

    //     Id personAccountRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;

    //     Account personAccount = new Account(
    //         FirstName = 'Test Person',
    //         LastName = 'Account',
    //         RecordTypeId = personAccountRecordTypeId
    //     );
    //     insert personAccount;

    //     BuyerAccount ba_person = new BuyerAccount(
    //         BuyerId = personAccount.Id,
    //         Name = 'Test Person Buyer Account',
    //         IsActive = true
    //     );
    //     insert ba_person;

    //     BuyerGroupMember bg_member_person = new BuyerGroupMember(
    //         BuyerId = personAccount.Id,
    //         BuyerGroupId = bg.Id
    //     );
    //     insert bg_member_person;

    //     Buyer_Group_Membership__c bg_membership_person = new Buyer_Group_Membership__c(
    //         Membership__c = m.Id,
    //         Buyer_Group__c = bg.Id,
    //         Certified__c = true
    //     );
    //     insert bg_membership_person;
    // }

    // @isTest static void testAssignOrRemoveBuyerGroups() {
    //     String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
    //     String membershipId = [SELECT Id FROM Membership__c WHERE Name = 'Test Membership' LIMIT 1].Id;

    //     Account_Membership__c am = new Account_Membership__c(
    //         Membership__c = membershipId,
    //         Account_Id__c = accountId,
    //         Parent_Id__c = accountId,
    //         Account_Assignment_Date__c = Date.valueOf('2024-09-01'),
    //         Start_Date__c = Date.valueOf('2024-09-01'),
    //         Welcome_Kit_Status__c = 'Unclaimed',
    //         Status__c = 'Active'
    //     );
    //     insert am;

    //     B2BBuyerGroupAssignemntController.Request request = new B2BBuyerGroupAssignemntController.Request();
    //     request.membershipId = membershipId;
    //     request.accountId = accountId;

    //     List<B2BBuyerGroupAssignemntController.Request> requests = new List<B2BBuyerGroupAssignemntController.Request>{request};

    //     Test.StartTest();
    //     B2BBuyerGroupAssignemntController.assignOrRemoveBuyerGroups(requests);
    //     Test.StopTest();
    // }

    // @isTest static void testAssignOrRemoveBuyerGroups_nullam() {
    //     String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
    //     String membershipId = [SELECT Id FROM Membership__c WHERE Name = 'Test Membership' LIMIT 1].Id;

    //     B2BBuyerGroupAssignemntController.Request request = new B2BBuyerGroupAssignemntController.Request();
    //     request.membershipId = membershipId;
    //     request.accountId = accountId;

    //     List<B2BBuyerGroupAssignemntController.Request> requests = new List<B2BBuyerGroupAssignemntController.Request>{request};

    //     Test.StartTest();
    //     B2BBuyerGroupAssignemntController.assignOrRemoveBuyerGroups(requests);
    //     Test.StopTest();
    // }

    // @isTest static void testAssignOrRemoveBuyerGroups_newbgm() {
    //     String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
    //     String membershipId = [SELECT Id FROM Membership__c WHERE Name = 'Test Membership' LIMIT 1].Id;

    //     BuyerGroup bg = new BuyerGroup(
    //         Name = 'New Buyer Group'
    //     );
    //     insert bg;

    //     Buyer_Group_Membership__c bgm = new Buyer_Group_Membership__c(
    //         Membership__c = membershipId,
    //         Buyer_Group__c = bg.Id
    //     );
    //     insert bgm;

    //     Account_Membership__c am = new Account_Membership__c(
    //         Membership__c = membershipId,
    //         Account_Id__c = accountId,
    //         Parent_Id__c = accountId,
    //         Account_Assignment_Date__c = Date.valueOf('2024-09-01'),
    //         Start_Date__c = Date.valueOf('2024-09-01'),
    //         Welcome_Kit_Status__c = 'Unclaimed',
    //         Status__c = 'Active'
    //     );
    //     insert am;

    //     B2BBuyerGroupAssignemntController.Request request = new B2BBuyerGroupAssignemntController.Request();
    //     request.membershipId = membershipId;
    //     request.accountId = accountId;

    //     List<B2BBuyerGroupAssignemntController.Request> requests = new List<B2BBuyerGroupAssignemntController.Request>{request};

    //     Test.StartTest();
    //     B2BBuyerGroupAssignemntController.assignOrRemoveBuyerGroups(requests);
    //     Test.StopTest();

    //     List<Id> buyerGroupIds = new List<Id>{bg.Id};
    //     B2BBuyerGroupAssignemntController.Response response = new B2BBuyerGroupAssignemntController.Response(buyerGroupIds);
    // }

    // @isTest static void testAssignBuyerGroupsPLM() {

    //     Account businessAccount = new Account(
    //         Name = 'Test Business Account'
    //     );
    //     insert businessAccount;

    //     Account personAccount = [SELECT Id, Business__c, Admin_Account__c FROM Account WHERE LastName = 'Account' LIMIT 1];
    //     personAccount.Business__c = businessAccount.Id;
    //     personAccount.Admin_Account__c = true;
    //     update personAccount;

    //     String membershipId = [SELECT Id FROM Membership__c WHERE Name = 'Test Membership' LIMIT 1].Id;

    //     Practice_Level_Membership_Assignment__c pm = new Practice_Level_Membership_Assignment__c(
    //         Start_Date__c = Date.valueOf('2024-09-01'),
    //         Welcome_Kit_Status__c = 'Unclaimed',
    //         Membership__c = membershipId,
    //         Business_Account__c = businessAccount.Id,
    //         Status__c = 'Active',
    //         Certified__c = true
    //     );
    //     insert pm;

    //     Test.StartTest();
    //     B2BBuyerGroupAssignemntController.assignBuyerGroupsPLM(businessAccount.Id, pm.Id);
    //     Test.StopTest();
    // }

    // @isTest static void testAssignBuyerGroupsPLM_newbgm() {

    //     Account businessAccount = new Account(
    //         Name = 'Test Business Account'
    //     );
    //     insert businessAccount;

    //     Account personAccount = [SELECT Id, Business__c, Admin_Account__c FROM Account WHERE LastName = 'Account' LIMIT 1];
    //     personAccount.Business__c = businessAccount.Id;
    //     personAccount.Admin_Account__c = true;
    //     update personAccount;

    //     BuyerGroup bg = new BuyerGroup(
    //         Name = 'New Buyer Group'
    //     );
    //     insert bg;

    //     String membershipId = [SELECT Id FROM Membership__c WHERE Name = 'Test Membership' LIMIT 1].Id;

    //     Buyer_Group_Membership__c bgm = new Buyer_Group_Membership__c(
    //         Membership__c = membershipId,
    //         Buyer_Group__c = bg.Id,
    //         Certified__c = true
    //     );
    //     insert bgm;

    //     Practice_Level_Membership_Assignment__c pm = new Practice_Level_Membership_Assignment__c(
    //         Start_Date__c = Date.valueOf('2024-09-01'),
    //         Welcome_Kit_Status__c = 'Unclaimed',
    //         Membership__c = membershipId,
    //         Business_Account__c = businessAccount.Id,
    //         Status__c = 'Active',
    //         Certified__c = true
    //     );
    //     insert pm;

    //     Test.StartTest();
    //     B2BBuyerGroupAssignemntController.assignBuyerGroupsPLM(businessAccount.Id, pm.Id);
    //     Test.StopTest();
    // }

    // @isTest static void testHelperGetMethods() {
    //     String accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
    //     String membershipId = [SELECT Id FROM Membership__c WHERE Name = 'Test Membership' LIMIT 1].Id;

    //     Test.StartTest();
    //     B2BBuyerGroupAssignmentServiceHelper.getAccount(accountId);
    //     B2BBuyerGroupAssignmentServiceHelper.getMembership(membershipId);
    //     Test.StopTest();
    // }
}