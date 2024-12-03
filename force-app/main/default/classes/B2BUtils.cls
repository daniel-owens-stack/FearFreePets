public with sharing class B2BUtils {
    private final static String siteName = 'Fear_Free_B2B_Store1';
    private static final Integer RENEWAL_OFFSET_IN_DAYS = Integer.valueOf(System.Label.B2B_Renewal_Offset_In_Days);


    public static String getWebstoreID() {
        String webstoreName = null;
        if(Test.isRunningTest()) {webstoreName = 'TestWebStore';}
        return System.Label.Webstore_ID;
    }
    
    public static String getUserAccountID() {
        String userId = UserInfo.getUserId();
        String contactId = [SELECT ContactId FROM User WHERE Id = :userId].ContactId;
        return [SELECT AccountId FROM Contact WHERE Id = :contactId].AccountId;
    }
    
    public static String createWebCart() {
        String effectiveAccountId = B2BUtils.getUserAccountID();
        String effectiveWebstoreId = B2BUtils.getWebstoreID();

        if(!Test.isRunningTest()) {
            ConnectApi.CartInput cartInput = new ConnectApi.CartInput();
            cartInput.effectiveAccountId = null;//effectiveAccountId;
            ConnectApi.CommerceCart.createCart(effectiveWebstoreId, cartInput);
        }
        return getAccountActiveOrCheckoutWebCart();
    }
    
    public static String getAccountActiveOrCheckoutWebCart() {
        String effectiveAccountId = getUserAccountID();
        List <WebCart> wcs = [SELECT Id FROM WebCart WHERE (Status = 'Checkout' OR Status = 'Active') AND accountId = :effectiveAccountId ORDER BY CreatedDate DESC LIMIT 1];
        if (wcs.isEmpty()) {
            return null;
        }
        return wcs[0].Id;
    }
    
    public static String getCartDeliveryGroupId(String cartId) {
        return [SELECT Id FROM CartDeliveryGroup WHERE CartId = :cartId].Id;
    }

    public static String getUserContactID(){
        String userId = UserInfo.getUserId();
        return [SELECT ContactId FROM User WHERE Id = :userId].ContactId;
    }

    public static String getWebStoreBaseURL(){
        Site mySite = [select Id
                       from Site
                       WHERE Name =:siteName
                       LIMIT 1];
        SiteDetail mySiteDetail = [select SecureURL
                                   from SiteDetail
                                   where DurableId = :mySite.Id];
        String BASE_URL = mySiteDetail.SecureURL;
        return BASE_URL;
    }

    @AuraEnabled
    public static String isFirstTimeLogin() {

        String userId = UserInfo.getUserId();
        List<AuthSession> authSession = [SELECT Id FROM AuthSession WHERE UsersId = :userId AND Users.Has_LoggedIn_More_Than_Once__c = false];

        if(authSession.size() > 0) {
            String result = getFirstTimeLoginProduct();
            return result;
        }
        return null;
    }

    public static String getFirstTimeLoginProduct() {
        updateUserDetails();

        String accountId = getUserAccountID();
        List<Account> account = [SELECT First_Time_Login_Product__c FROM Account WHERE Id = :accountId];
        if(account.size() > 0) {
            return account[0].First_Time_Login_Product__c;
        }
        return null;
    }

    public static void updateUserDetails() {
        try {
            String userId = UserInfo.getUserId();
            List<User> user = [SELECT Id, Has_LoggedIn_More_Than_Once__c FROM User WHERE Id = :userId LIMIT 1];
            if(user.size() > 0) {
                user[0].Has_LoggedIn_More_Than_Once__c = true;
                update user[0];
            }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BUtils', 'updateUserDetails');
        }
    }

    public static Boolean isRenewalMembership(String accountId, String membershipId) {
        Boolean isIndividualLevelMembership = true;
        
        try {
            Membership__c membership = [SELECT Id, Membership_Level__c FROM Membership__c WHERE Id = :membershipId LIMIT 1];
            isIndividualLevelMembership = membership.Membership_Level__c != 'Practice';
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BUtils', 'isRenewalMembership: Membership Query');
            return false;
        } 
    
        if (isIndividualLevelMembership) {
            try {
                Account_Membership__c am = 
                    [
                        SELECT Id 
                        FROM Account_Membership__c 
                        WHERE can_be_fully_reassigned__c = FALSE 
                        AND Membership__c = :membershipId 
                        AND Account_Id__c = :accountId
                        LIMIT 1
                    ];
                if (am == null) {
                    return false;
                }
                return true;
            } catch (Exception e) {
                B2BHandleCustomException.LogException(e, 'B2BUtils', 'isRenewalMembership: Account_Membership Query');
                return false;
            }
        } else {
            try {
                Account account = [SELECT Id, Business__c FROM Account WHERE Id = :accountId];
                Practice_Level_Membership_Assignment__c plma = 
                    [
                        SELECT Id
                        FROM Practice_Level_Membership_Assignment__c
                        WHERE Membership__c = :membershipId 
                        AND Business_Account__c = :account.Business__c 
                        LIMIT 1
                    ];
                if (plma == null) {
                    return false;
                }
                return true;
            } catch (Exception e) {
                B2BHandleCustomException.LogException(e, 'B2BUtils', 'isRenewalMembership: Practice_Level_Membership_Assignment Query');
                return false;
            }
        }
    }

    public static Decimal getIndividualMembershipRenewalPrice(String accountMembershipId) {
        try {
            Account_Membership__c accountMembership = [SELECT Id, Renewal_Amount__c, Membership__c FROM Account_Membership__c WHERE Id =:accountMembershipId];
            if (accountMembership.Renewal_Amount__c != null) {
                return accountMembership.Renewal_Amount__c;
            }
            
            Membership__c membership = [SELECT Id, Renewal_Amount__c FROM Membership__c WHERE Id=:accountMembership.Membership__c];
            return membership.Renewal_Amount__c;
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BUtils', 'getIndividualMembershipRenewalPrice');
            return null;
        }
    }

    public static Decimal getPracticeMembershipRenewalPrice(String practiceLevelMembershipId) {
        try {
           return 50;
            
           
        } catch (Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BUtils', 'getPracticeMembershipRenewalPrice');
            return null;
        }
    }

    public static Date getTargetRenewalDate() {
        return Date.today().addDays(RENEWAL_OFFSET_IN_DAYS);
    }

    public static String getTargetRenewalDateForSOQL() {
        Date targetDate = Date.today().addDays(RENEWAL_OFFSET_IN_DAYS);
        String year = String.valueOf(targetDate.year());
        String month = targetDate.month() < 10 ? '0' + String.valueOf(targetDate.month()) : String.valueOf(targetDate.month());
        String day = targetDate.day() < 10 ? '0' + String.valueOf(targetDate.day()) : String.valueOf(targetDate.day());
        
        return year + '-' + month + '-' + day;
    }
    
    public static Decimal getProductPriceByAccountId(String accountId, String productId) {
        String webstoreId = getWebstoreID();
        return Decimal.valueOf(
            String.valueOf(ConnectApi.CommerceStorePricing.getProductPrice(webstoreId, productId, accountId).UnitPrice)
        );
        
    }

    public static Map<String, String> calculateMinMaxRenewalOffsetRange() {
        Date today = Date.today();

        if(Test.isRunningTest()) {
            String todaysDate = convertDateToString(today);
    
            return new Map<String, String>{
                'minDate' => todaysDate,
                'maxDate' => todaysDate
            };
        }
        
        Integer day = today.day();

        if(day != 24 || day != 7) {
            // return null; //should be uncommented when below line is deleted
            //The below line is added for testing should be removed later
            day = day < 15 ? 7 : 24;
        }
        
        Date minDate;
        Date maxDate;

        if (day == 24) {
            minDate = today.addMonths(1).toStartOfMonth(); // 1st of next month
            maxDate = minDate.addDays(12); // 13th of next month
        }
        else if (day == 7) {
            minDate = today.toStartOfMonth().addDays(13); // 14th of current month
            maxDate = today.toStartOfMonth().addMonths(1).addDays(-1); // End of current month
        }

        String minDate_string = convertDateToString(minDate);
        String maxDate_string = convertDateToString(maxDate);

        return new Map<String, String>{
            'minDate' => minDate_string,
            'maxDate' => maxDate_string
        };
    }

    public static String convertDateToString(Date dateValue) {
        String year = String.valueOf(dateValue.year());
        String month = dateValue.month() < 10 ? '0' + String.valueOf(dateValue.month()) : String.valueOf(dateValue.month());
        String day = dateValue.day() < 10 ? '0' + String.valueOf(dateValue.day()) : String.valueOf(dateValue.day());
        
        return year + '-' + month + '-' + day;
    }
}