public with sharing class B2BUtils {
    private final static String siteName = 'Fear_Free_B2B_Store1';

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
        return 'LoggedInMoreThanOnce';
    }

    public static String getFirstTimeLoginProduct() {
        updateUserDetails();

        String accountId = getUserAccountID();
        List<Account> account = [SELECT First_Time_Login_Product__c FROM Account WHERE Id = :accountId];
        if(account.size() > 0) {
            return account[0].First_Time_Login_Product__c;
        }
        return 'No Account';
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

    public static Decimal getProductPriceByAccountId(String accountId, String productId) {
        String webstoreId = getWebstoreID();
        return Decimal.valueOf(
            String.valueOf(ConnectApi.CommerceStorePricing.getProductPrice(webstoreId, productId, accountId).UnitPrice)
        );  
    }

    @AuraEnabled
    public static void updateCart(String cartId) {
        WebCart cart = [SELECT Id, Status FROM WebCart WHERE Id = :cartId];
        cart.Status = 'Active';
        update cart;
    }
}