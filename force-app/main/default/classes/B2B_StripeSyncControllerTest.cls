/**
 * @description       : 
 * @author            : Harshvardhan Tiwari
 * @group             : 
 * @last modified on  : 09-18-2025
 * @last modified by  : Harshvardhan Tiwari
**/
@IsTest
public with sharing class B2B_StripeSyncControllerTest {
    
    @TestSetup
    static void makeData(){
        Account a = new Account();
        a.FirstName = 'Test';
        a.LastName = 'Account';
        a.BillingCountry = 'United States';
        a.BillingState = 'California';
        a.BillingCity = 'San Francisco';
        a.BillingStreet = 'Test Street';
        a.BillingPostalCode = '94115';
        a.PersonEmail = 'test@account.com';
        a.StripeCustomerId__c = 'cus_1234567890';
        insert a;
    }

    @IsTest
    static void updateStripeCustomerTest(){
        Account a = [SELECT Id FROM Account];
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('recordId', a.Id);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('stripeCustomer', 200, true));
        Map<String,Object> result = B2B_StripeSyncController.updateStripeCustomer(mapParams);
        Test.stopTest();
    }

    @IsTest
    static void updateStripeCustomerNegativeTest(){
        Map<String,Object> mapParams = new Map<String,Object>();
        Integer one = 1;
        mapParams.put('recordId', one);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new B2BStripeHttpCalloutMock('stripeCustomer', 200, true));
        Map<String,Object> result = B2B_StripeSyncController.updateStripeCustomer(mapParams);
        Test.stopTest();
    }
}