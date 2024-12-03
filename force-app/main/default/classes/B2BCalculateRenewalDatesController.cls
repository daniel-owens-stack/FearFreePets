public class B2BCalculateRenewalDatesController {
    
    public static Date getIndividualLevelRenewalDate(String accountId) {
        try {
            List<Account_Membership__c> ilma = [
                SELECT Expiration_Date__c 
                FROM Account_Membership__c 
                WHERE Parent_Id__c =:accountId 
                AND Expiration_Date__c > TODAY
                ORDER BY Expiration_Date__c 
                LIMIT 1
            ];

            if(!ilma.isEmpty()) {
                return ilma[0].Expiration_Date__c;
            }
            return null;
        }
        catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BCalculateRenewalDatesController', 'getIndividualLevelRenewalDate');
            return null;
        }
    }

    public static Date getPracticeLevelRenewalDate(String accountId) {
        try {
            List<Practice_Level_Membership_Assignment__c> plma = [
                SELECT Expiration_Date__c 
                FROM Practice_Level_Membership_Assignment__c 
                WHERE Business_Account__c =:accountId 
                AND Expiration_Date__c > TODAY
                ORDER BY Expiration_Date__c 
                LIMIT 1
            ];

            if(!plma.isEmpty()) {
                return plma[0].Expiration_Date__c;
            }
            return null;
        }
        catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BCalculateRenewalDatesController', 'getPracticeLevelRenewalDate');
            return null;
        }
    }
}