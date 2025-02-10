public without sharing class B2BAccountCodeController {

    @AuraEnabled
    public static Boolean updateAccountFields(String code) {
        try {
            String accountId = B2BUtils.getUserAccountID();
            List<Account> account = [SELECT Id, Account_Code__c, Admin_Account__c, Business__c FROM Account WHERE Id=:accountId];
            
            if(account.size() > 0) {
                List<Account> accountsToBeUpdated = new List<Account>();
                List<Account> teamAccounts = new List<Account>();
                if(account[0].Admin_Account__c && account[0].Business__c != null) {
                    teamAccounts = [SELECT Account_Code__c 
                                    FROM Account 
                                    WHERE Business__c =:account[0].Business__c 
                                    OR Id =:account[0].Business__c];
                }
                if(code != null) {
                    List<Account_Code__c> accountCode = [SELECT Id FROM Account_Code__c 
                                                    WHERE Code__c =:code ORDER BY CreatedDate Desc];
                                                    
                    if(accountCode.size() > 0) {
                        if(teamAccounts.size() > 0) {  
                            for(Account acc : teamAccounts) {
                                acc.Account_Code__c = accountCode[0].Id;
                                accountsToBeUpdated.add(acc);
                            }
                            Database.update(accountsToBeUpdated);
                            return true;
                        }
                        else if(account[0].Business__c == null) {
                            account[0].Account_Code__c = accountCode[0].Id;
                            Database.update(account[0]);
                            return true;
                        }
                    }
                    return false;
                }
                else {
                    if(teamAccounts.size() > 0) {
                        for(Account acc : teamAccounts) {
                            acc.Account_Code__c = null;
                            accountsToBeUpdated.add(acc);
                        }
                        Database.update(accountsToBeUpdated);
                        return true;
                    }
                    else if(account[0].Business__c == null) {
                        account[0].Account_Code__c = null;
                        Database.update(account[0]);
                        return true;
                    }
                }
            }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BAccountCodeController', 'updateAccountFields');
        }
        return false;
    }

    @AuraEnabled
    public static AccountCodeWrapper manageAccountCode() {
        String accountId = B2BUtils.getUserAccountID();
        List<Account> account = [SELECT Id, Admin_Account__c, Business__c, Account_Code_Label__c, Account_Code__c 
                                 FROM Account 
                                 WHERE Id =:accountId
                                ];
        
        if(account.size() > 0) {
            AccountCodeWrapper acw = new AccountCodeWrapper();
            acw.accountCodeLabel = account[0].Account_Code__c != null ? account[0].Account_Code_Label__c : null;
            acw.onTeam = account[0].Business__c != null ? true : false;
            acw.teamAdmin = (account[0].Business__c != null && account[0].Admin_Account__c) ? true : false;

            return acw;
        }
        return null;
    }

    public class AccountCodeWrapper {

        @AuraEnabled
        public String accountCodeLabel { get; set; }

        @AuraEnabled
        public Boolean onTeam { get; set; }

        @AuraEnabled
        public Boolean teamAdmin { get; set; }
    }

    @AuraEnabled
    public static void deleteActiveCarts() {
        try {
            String accountId = B2BUtils.getUserAccountID();
            String userId = UserInfo.getUserId();

            List<WebCart> carts = [SELECT Id FROM WebCart 
                                WHERE AccountId =:accountId AND OwnerId =:userId 
                                AND (Status = 'Active' OR Status = 'Checkout')
                                ORDER BY CreatedDate Desc
                                ];

            List<WebCart> cartsToBeDeleted = new List<WebCart>();
            Integer minNumOfCarts = 1;
            if(Test.isRunningTest()) {
                minNumOfCarts = 0;
            }
            if(carts.size() > minNumOfCarts) {
                Boolean newCart = true;
                for(WebCart cart: carts) {
                    if(newCart) {
                        newCart = false;
                        continue;
                    }
                    else{
                        cartsToBeDeleted.add(cart);
                    }
                }
                delete cartsToBeDeleted;
            }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BAccountCodeController', 'deleteActiveCarts');
        }
    }
}