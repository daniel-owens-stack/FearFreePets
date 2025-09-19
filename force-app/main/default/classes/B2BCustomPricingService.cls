public without sharing class B2BCustomPricingService extends commercestorepricing.PricingService {

    @TestVisible
    private static String testCartId;

    public override commercestorepricing.TransactionalPricingResponse processTransactionalPrice(commercestorepricing.TransactionalPricingRequest request) {

        String cartId = B2BUtils.getAccountActiveOrCheckoutWebCart();

        if (Test.isRunningTest() && testCartId != null) {
            cartId = testCartId;
        }

        List<CartItem> cartItems = [
            SELECT Id, Product2Id, Product2.Membership__r.Renewal_Amount__c, Individual_Membership_Assignment__c, Practice_Level_Membership_Assignment__c
            FROM CartItem
            WHERE CartId = :cartId
            AND Type = 'Product'
        ];
        
        commercestorepricing.TransactionalPricingResponse pricingResponse;
        if(!Test.isRunningTest()){
            pricingResponse = super.processTransactionalPrice(request);
        } else {
            pricingResponse = B2BTransactionalPricingResponseMock.processTransactionalPrice();
        }
        commercestorepricing.TxnPricingResponseItemCollection responseItems = pricingResponse.getTxnPricingResponseItems();

        Decimal totalListPrice = 0;
        Decimal totalProductAmount = 0;

        for (Integer i = 0; i < responseItems.size(); i++) {
            commercestorepricing.TransactionalPricingResponseItem item = responseItems.get(i);
            String productId = item.getProductId();
            Decimal quantity = item.getQuantity();

            Decimal productPrice = null;

            for(CartItem ci : cartItems) {
                if(ci.Product2Id == productId && (ci.Individual_Membership_Assignment__c != null || ci.Practice_Level_Membership_Assignment__c != null)) {
                    productPrice = ci.Product2.Membership__r.Renewal_Amount__c;
                    break;
                }
            }
            
            if (productPrice != null) {
                //Use renewal price
                item.setUnitPrice(productPrice);
                item.setListPrice(productPrice);

                Decimal totalPrice = quantity * productPrice;

                item.setTotalLineAmount(totalPrice);
                item.setTotalListPrice(totalPrice);
                item.setTotalPrice(totalPrice);

                totalListPrice += totalPrice;
                totalProductAmount += totalPrice;
            } else {
                // Use default pricing
                totalListPrice += item.getTotalListPrice();
                totalProductAmount += item.getTotalLineAmount();
            }
        }

        pricingResponse.setTotalListPrice(totalListPrice);
        pricingResponse.setTotalProductAmount(totalProductAmount);

        Decimal totalAdjustmentAmount = pricingResponse.getTotalAdjustmentAmount() != null
            ? pricingResponse.getTotalAdjustmentAmount()
            : 0;

        pricingResponse.setTotalAmount(totalProductAmount + totalAdjustmentAmount);

        return pricingResponse;
    }
}