@isTest
public class B2BCreateHistoricalMembershipsBatchTest {
    
    @TestSetup static void makeData(){
        Historical_Membership__c hm = new Historical_Membership__c();
        hm.Course_Id__c = '12345';
        hm.Product_Id__c = '234567';
        hm.User_Membership_Date__c = Date.valueOf('2020-09-10');
        hm.Start_Date__c = Date.valueOf('2020-09-09');
        hm.End_Date__c = Date.valueOf('2022-09-09');
        hm.Historical_Order_Id__c = '45176';
        hm.User_Id__c = '888';
        hm.Cancelled_Date__c = Date.valueOf('2022-07-02');
        hm.Successful_Insert__c = false;

        insert hm;

        Historical_Membership__c hm1 = new Historical_Membership__c();
        hm1.Course_Id__c = '123456';
        hm1.Product_Id__c = '934567';
        hm1.User_Membership_Date__c = Date.valueOf('2020-09-10');
        hm1.Start_Date__c = Date.valueOf('2020-09-09');
        hm1.End_Date__c = Date.valueOf('2022-09-09');
        hm1.Historical_Order_Id__c = '45176';
        hm1.User_Id__c = '888';
        hm1.Cancelled_Date__c = Date.valueOf('2022-07-02');
        hm1.Successful_Insert__c = false;

        insert hm1;

        //Create Memberships
        Membership__c individualMembership = new Membership__c();
        individualMembership.Membership_Level__c = 'Individual';
        individualMembership.Name = 'Test Individual Membership';

        insert individualMembership;

        Membership__c practiceMembership = new Membership__c();
        practiceMembership.Membership_Level__c = 'Practice';
        practiceMembership.Name = 'Test Practice Membership';

        insert practiceMembership;

        //Create Products
        Product2 imp = new Product2(
            Name = 'Individual Membership Product',
            WC_Id__c = '234567',
            Membership__c = individualMembership.Id
        );
        insert imp;

        Product2 pmp = new Product2(
            Name = 'Practice Membership Product',
            WC_Id__c = '934567',
            Membership__c = practiceMembership.Id
        );
        insert pmp;
    }

    @isTest static void testCreateHistoricalMembershipBatch_noMembership() {

        Test.StartTest();
        B2BCreateHistoricalMembershipsBatch b = new B2BCreateHistoricalMembershipsBatch();
        Database.executeBatch(b);
        Test.StopTest();
    }

}