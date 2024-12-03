public class B2BCreateHistoricalMembershipsBatch implements Database.Batchable<sObject>, Database.Stateful {

    public B2BCreateHistoricalMembershipsBatch() { }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Cancelled_Date__c, Course_Id__c, End_Date__c, First_Name__c, Historical_Order_Id__c, Last_Name__c, Name, Post_Id__c, Product_Id__c, Start_Date__c, Successful_Insert__c, User_Email__c, User_Id__c,  User_Membership_Date__c FROM Historical_Membership__c WHERE Successful_Insert__c = false';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Historical_Membership__c> scope){

        try {
            Set<String> wcIds = new Set<String>();
            for(Historical_Membership__c hm : scope) {
                wcIds.add(hm.Product_Id__c);
            }

            List<Product2> products = [SELECT Id, Name, Membership__r.Membership_Level__c, Membership__c, WC_Id__c 
                                       FROM Product2 
                                       WHERE WC_Id__c IN :wcIds];
           
            List<Map<String, String>> membershipMapList = new List<Map<String, String>>();
            List<Map<String, String>> membershipLevelMapList = new List<Map<String, String>>();
            if(products.size() > 0) {
                for(Product2 p : products) {
                    Map<String, String> membershipMap = new Map<String, String>();
                    Map<String, String> membershipLevelMap = new Map<String, String>();
                    
                    if(p.WC_Id__c != null) {
                        membershipMap.put(p.WC_Id__c, p.Membership__c);
                        membershipMapList.add(membershipMap);

                        membershipLevelMap.put(p.WC_Id__c, p.Membership__r.Membership_Level__c);
                        membershipLevelMapList.add(membershipLevelMap);
                    }
                }
            }
            
            List<Account_Membership__c> accountMemberships = new List<Account_Membership__c>();
            List<Practice_Level_Membership_Assignment__c> practiceMemberships = new List<Practice_Level_Membership_Assignment__c>();
            for(Historical_Membership__c hm : scope) {

                String membershipId;

                if(membershipMapList.size() > 0) {
                    for(Map<String, String> existingMap : membershipMapList) {
                        if(existingMap.containsKey(hm.Product_Id__c)) {
                            membershipId = existingMap.get(hm.Product_Id__c);
                            break;
                        }
                    }
                }

                String membershipLevel;
                if(membershipLevelMapList.size() > 0) {
                    for(Map<String, String> existingMap : membershipLevelMapList) {
                        if(existingMap.containsKey(hm.Product_Id__c)) {
                            membershipLevel = existingMap.get(hm.Product_Id__c);
                            break;
                        }
                    }
                } 

                if(membershipId != null && membershipLevel != null) {
                    if(membershipLevel == 'Individual') {
                        Account_Membership__c am = new Account_Membership__c();
                        am.Account_Assignment_Date__c = hm.User_Membership_Date__c;
                        am.Start_Date__c = hm.Start_Date__c;
                        am.Historical_End_Date__c = hm.End_Date__c;
                        am.Welcome_Kit_Status__c = 'Unavailable';
                        am.Historical_Order_Id__c = hm.Historical_Order_Id__c;
                        am.Historical_User_Id__c = hm.User_Id__c;
                        am.Cancelled_Date__c = hm.Cancelled_Date__c;
                        am.Membership__c = membershipId;

                        accountMemberships.add(am);
                    }
                    else if(membershipLevel == 'Practice') {
                        Practice_Level_Membership_Assignment__c pm = new Practice_Level_Membership_Assignment__c();
                        pm.Start_Date__c = hm.Start_Date__c;
                        pm.Welcome_Kit_Status__c = 'Unavailable';
                        pm.Historical_Order_Id__c = hm.Historical_Order_Id__c;
                        pm.Historical_User_Id__c = hm.User_Id__c;
                        pm.Membership__c = membershipId;

                        practiceMemberships.add(pm);
                    }
                }
            }

            List<Historical_Membership__c> historicalMembershipsToBeUpdated = new List<Historical_Membership__c>();
            if(!accountMemberships.isEmpty()) {
                insert accountMemberships;
            }
            if(!practiceMemberships.isEmpty()) {
                insert practiceMemberships;
            }

            for(Historical_Membership__c hm : scope) {
                hm.Successful_Insert__c = true;
                historicalMembershipsToBeUpdated.add(hm);
            }
            update historicalMembershipsToBeUpdated;
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'Historical Memberships', 'Membership Creation');
        }        
    }

    public void finish(Database.BatchableContext bc){

    }
}