/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 10-10-2024 - FSM
 * @last modified by  : FSM
**/
@isTest(SeeAllData = true)
public with sharing class NumberReportViewControllerTest 
{
    @IsTest
    public static void getMembershipCountsTest()
    {
        Map<String,Integer> membershipDataMap = new Map<String,Integer>();
        User usr = [SELECT Id FROM User WHERE profile.name = 'Fear Free Community Member' LIMIT 1];

        Test.startTest();
            membershipDataMap = NumberReportViewController.getMembershipCounts(usr.Id);
            System.debug('membershipDataMap = ' + membershipDataMap);
        Test.stopTest();
    }

    @IsTest
    public static void getMembershipCountTest()
    {
        Map<String,Integer> membershipDataMap = new Map<String,Integer>();
        User usr = [SELECT Id FROM User WHERE profile.name = 'Fear Free Community Member' LIMIT 1];

        Test.startTest();
            membershipDataMap = NumberReportViewController.getMembershipCount(usr.Id, 'Unassigned_Pet_Sitter_Memberships');
            System.debug('membershipDataMap = ' + membershipDataMap);
        Test.stopTest();
    }
}