public without sharing class B2BCustomAddToCartController {
    
    @AuraEnabled
    public static Boolean isVariantProduct(String productId) {
        String productClass = String.valueOf([SELECT ProductClass FROM Product2 WHERE Id = :productId]?.ProductClass);

        if (productClass == 'VariationParent') 
            return false;
        else
            return true;
    }

    @AuraEnabled
    public static String getProductGroup(String productId) {

        List<Product2> product = [SELECT Id, Product_Group__c FROM Product2 WHERE Id =:productId];

        if(product.size() > 0) {
            return product[0].Product_Group__c;
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isAdminAccount() {
        String accountId = B2BUtils.getUserAccountID();
        List<Account> account = [SELECT Id, Admin_Account__c FROM Account WHERE Id =:accountId];

        return account[0].Admin_Account__c;
    }

    @AuraEnabled
    public static List<Account_Membership__c> getIndividualLevelMemberships(String productId) {

        Product2 product = [SELECT Id, Membership__c FROM Product2 WHERE Id =: productId];

        String membershipId = product.Membership__c;
        String accountId = B2BUtils.getUserAccountID();

        List<Account_Membership__c> membershipList = [SELECT Id FROM Account_Membership__c 
                                                      WHERE Membership__c  =:membershipId 
                                                      AND Parent_Id__c =:accountId
                                                      AND Status__c = 'Active'
                                                     ];
        
        return membershipList;
    }

    @AuraEnabled
    public static List<Practice_Level_Membership_Assignment__c> getPracticeLevelMemberships(String productId) {

        Product2 product = [SELECT Id, Membership__c FROM Product2 WHERE Id =: productId];

        String accountId = B2BUtils.getUserAccountID();
        Account account = [SELECT Id, Business__c FROM Account WHERE Id =:accountId];

        List<Practice_Level_Membership_Assignment__c > practiceLevelMemberships = new List<Practice_Level_Membership_Assignment__c >();
        if(account.Business__c != null) {
            practiceLevelMemberships = [SELECT Id FROM Practice_Level_Membership_Assignment__c 
                                        WHERE Membership__c  =:product.Membership__c 
                                        AND Business_Account__c =:account.Business__c
                                        AND Status__c = 'Active'
                                       ];
        }
        
        return practiceLevelMemberships;
    }

    @AuraEnabled
    public static Boolean isProductPresentInCart(String productId) {
        String accountId;
        if(UserInfo.getUserType() == 'Guest') {
            accountId = [SELECT Id FROM GuestBuyerProfile LIMIT 1].Id;
        } else  {
            accountId = B2BUtils.getUserAccountID();
        }

        List<WebCart> cart = [SELECT Id FROM WebCart 
                              WHERE AccountId =:accountId AND (Status = 'Active' OR Status = 'Checkout')
                              Order By CreatedDate Desc LIMIT 1];

        if(cart.size() > 0) {
            List<CartItem> cartItems = [SELECT Id, Product2Id
                                        FROM CartItem
                                        WHERE CartId =:cart[0].Id
                                       ];
            
            if(cartItems.size() > 0) {
                for(CartItem ci : cartItems) {
                    if(ci.Product2Id == productId) {
                        return true;
                    }
                }
            }                             
        }
        return false;
    }
}