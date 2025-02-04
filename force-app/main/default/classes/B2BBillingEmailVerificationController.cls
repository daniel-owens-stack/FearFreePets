public without sharing class B2BBillingEmailVerificationController {
    
    @AuraEnabled
    public static AccountWrapper getAccountDetails() {
        String accountId = B2BUtils.getUserAccountID();
        List<Account> account = [SELECT Id, Name, Admin_Account__c, Billing_Email__c, Billing_Email_Verified__c, Business__c, Payment_Terms__c
                                 FROM Account 
                                 WHERE Id =: accountId
                                ];   

        AccountWrapper aw = new AccountWrapper();
        if(account.size() > 0) {
            aw.accountName = account[0].Name;
            aw.isAdminAccount = account[0].Admin_Account__c;
            aw.isOnTeam = account[0].Business__c != null ? true :false;
            aw.creditOnlyPaymentTerms = account[0].Payment_Terms__c == 'Credit Card Only' ? true : false;

            if(account[0].Business__c != null && account[0].Billing_Email__c == null) {
                List<Account> businessAccount = [SELECT Id, Billing_Email__c, Billing_Email_Verified__c FROM Account WHERE Id = :account[0].Business__c LIMIT 1];

                    if(businessAccount.size() > 0) {
                        aw.hasBillingEmail = businessAccount[0].Billing_Email__c != null ? true : false;
                        aw.billingEmail = businessAccount[0].Billing_Email__c;
                        aw.isBillingEmailVerified = businessAccount[0].Billing_Email_Verified__c;
                    }
            }
            else {
                aw.hasBillingEmail = account[0].Billing_Email__c != null ? true : false;
                aw.billingEmail = account[0].Billing_Email__c;
                aw.isBillingEmailVerified = account[0].Billing_Email_Verified__c;
            }
        }
        return aw;
    }

    public class AccountWrapper {

        @AuraEnabled
        public String accountName { get; set; }

        @AuraEnabled
        public Boolean isAdminAccount { get; set; }

        @AuraEnabled
        public Boolean isOnTeam { get; set; }

        @AuraEnabled
        public Boolean creditOnlyPaymentTerms { get; set; }

        @AuraEnabled
        public Boolean hasBillingEmail { get; set; }

        @AuraEnabled
        public String billingEmail { get; set; }

        @AuraEnabled
        public Boolean isBillingEmailVerified { get; set; }        
    }

    @AuraEnabled
    public static void updateAccount(String billingEmail, Boolean emailVerified) {
        try{
            String accountId = B2BUtils.getUserAccountID();

            List<Account> account = [SELECT Id, Billing_Email__c, Billing_Email_Verified__c, Business__c, StripeCustomerId__c, Admin_Account__c
                                    FROM Account 
                                    WHERE Id =: accountId
                                    ];

            if(account.size() > 0) {
                if(account[0].Business__c != null && account[0].Admin_Account__c) {
                    List<Account> businessAccount = [SELECT Id, Billing_Email__c, Billing_Email_Verified__c, StripeCustomerId__c FROM Account WHERE Id = :account[0].Business__c LIMIT 1];

                    if(businessAccount.size() > 0) {
                        businessAccount[0].Billing_Email__c = billingEmail;
                        businessAccount[0].Billing_Email_Verified__c = emailVerified;

                        if(!emailVerified) {
                            businessAccount[0].StripeCustomerId__c = null;
                        }
                        update businessAccount[0];
                    }
                }
                else {
                    account[0].Billing_Email__c = billingEmail;
                    account[0].Billing_Email_Verified__c = emailVerified;

                    if(!emailVerified) {
                        account[0].StripeCustomerId__c = null;
                    }

                    update account[0];
                }
            }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BBillingEmailVerificationController', 'updateAccount');
        }
    }

    @AuraEnabled
    public static Integer generateVerificationCode() {
        Integer randomCode = Crypto.getRandomInteger();
        Integer min = 100000;
        Integer max = 999999;
        return Math.abs(Math.mod(randomCode, max - min + 1)) + min;
    }
    
    @AuraEnabled
    public static Boolean verifyCode(String email, String code) {
        try{
        Email_Verification__c em = [
            SELECT Id, Verification_Code__c, Expiration_Time__c
            FROM Email_Verification__c
            WHERE Email_Address__c = :email
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (em != null) {
            // Check if code matches and is not expired
            if (em.Verification_Code__c == code && em.Expiration_Time__c > DateTime.now()) {
                updateAccount(email, true);
                return true;
            }
        }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BBillingEmailVerificationController', 'verifyCode');
        }
        return false;
    }  
    
    @InvocableMethod(label='Save Verification Code' description='Creates a Email Verification record to validate the code later') 
    public static void saveVerificationCode(List<FlowInputs> flowInputs) {

        try{
            String email = flowInputs[0].email;
            String code = flowInputs[0].code;
            DateTime expirationTime = DateTime.now().addMinutes(5);
            
            Email_Verification__c em = new Email_Verification__c();
            em.Email_Address__c = email;
            em.Verification_Code__c = code;
            em.Expiration_Time__c = expirationTime;
            
            insert em;
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BBillingEmailVerificationController', 'saveVerificationCode');
        }
    }

    public class FlowInputs {
        @InvocableVariable(required=true) 
        public String email;

        @InvocableVariable(required=true)
        public String code;
    }
}