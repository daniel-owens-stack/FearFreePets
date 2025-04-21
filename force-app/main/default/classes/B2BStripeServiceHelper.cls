public without sharing class B2BStripeServiceHelper {
    public static String TAX_STRIPE_PRODUCT_ID = System.Label.B2B_Tax_Stripe_Product_Id;
 
    public static List<String> CART_ITEMS_QUERY_FIELDS = new List<String> {
        'Quantity', 'UnitAdjustedPriceWithItemAdj', 'Product2.Name', 'Product2.Stripe_Product_Id__c', 'ListPrice', 'Type'
    };

    public static List<String> CART_QUERY_FIELDS = new List<String> {
        'Id', 'Name', 'PONumber', 'TotalTaxAmount'
    };

    public static List<String> CART_DELIVERY_GROUP_FIELDS = new List<String> {
        'DeliverToStreet', 'DeliverToName', 'DeliverToCity', 'DeliverToState', 'DeliverToPostalCode', 'DeliverToCountry'
    };

    //You can use formulas here , but result of the formula should be a string
    // If you need to have Integer or Boolean use TEXT({yourformula}) function
    public static Map<String,String> CART_ITEMS_MAP = new Map<String,String> {
        '[quantity]' => 'TEXT(IF(Quantity = 0, 1, Quantity))',
        '[price_data][currency]' => '{static} usd',
        '[price_data][product]' => 'Product2.Stripe_Product_Id__c'
    };
    
    public static Map<String,String> CART_METADATA_MAP = new Map<String,String> {
        '[SF_Cart_Id]' => 'Id',
        '[SF_Cart_Name]' => 'Name',
        '[PO_Number]' => 'PONumber'
    };

    public static Map<String,String> CART_DELIVERY_GROUP_METADATA_MAP = new Map<String,String> {
        '[DeliverToStreet]' => 'DeliverToStreet',
        '[DeliverToName]' => 'DeliverToName',
        '[DeliverToCity]' => 'DeliverToCity',
        '[DeliverToState]' => 'DeliverToState',
        '[DeliverToPostalCode]' => 'DeliverToPostalCode',
        '[DeliverToCountry]' => 'DeliverToCountry'
    };

    public static String createCheckoutRequestString(String customerId, String webCartId , String href) {
        String checkoutMode = 'payment';
        String result = 'customer=' + customerId + 
        '&success_url=' + href + '?session={CHECKOUT_SESSION_ID}' + 
        '&cancel_url=' + href;

        String cartItemsQuery = 'SELECT ' + String.join(CART_ITEMS_QUERY_FIELDS, ',') + ' FROM CartItem WHERE CartId =: webCartId';
        List<CartItem> items = Database.query(cartItemsQuery);

        List<String> params = new List<String>();

        for(Integer index = 0; items.size() > index; index++) {
            // Dynamically choose UnitAdjustedPriceWithItemAdj or ListPrice based on CartItem.Type
            CartItem cartItem = items[index];

            String adjustedPrice = (cartItem.Type == 'Product') 
                ? 'TEXT(IF(ISNULL(UnitAdjustedPriceWithItemAdj), 0, ROUND(UnitAdjustedPriceWithItemAdj * 100, 0)))' 
                : 'TEXT(IF(ISNULL(ListPrice), 0, ROUND(ListPrice * 100, 0)))';
            
            CART_ITEMS_MAP.put('[price_data][unit_amount]', adjustedPrice);

            for(String key : CART_ITEMS_MAP.keySet()) {
                String value = getFieldValue((SObject) items[index], CART_ITEMS_MAP.get(key));

                params.add('line_items[' + index + ']' + key + '=' + value);
            }
        }

        String cartQuery = 'SELECT ' + String.join(CART_QUERY_FIELDS, ',') + ' FROM Webcart WHERE Id =: webCartId';
        WebCart cart = Database.query(cartQuery);

        //Adding Tax Line Item
        Integer totalTaxAmount = Math.round(cart.TotalTaxAmount * 100);
        params.add('line_items[' + items.size() + '][price_data][unit_amount]=' + totalTaxAmount);
        params.add('line_items[' + items.size() + '][price_data][product]=' + TAX_STRIPE_PRODUCT_ID);
        params.add('line_items[' + items.size() + '][price_data][currency]=usd');
        params.add('line_items[' + items.size() + '][quantity]=1');

        for(String key : CART_METADATA_MAP.keySet()) {
            String value = getFieldValue((SObject) cart, CART_METADATA_MAP.get(key));

            params.add('payment_intent_data[metadata]' + key + '=' + value);
        }
        params.add('payment_intent_data[setup_future_usage]=on_session');
        params.add('metadata[sf_id]=' + webCartId);


        String deliveryGroupQuery = 'SELECT ' + String.join(CART_DELIVERY_GROUP_FIELDS, ',') + ' FROM CartDeliveryGroup WHERE CartId =: webCartId LIMIT 1';
        List<CartDeliveryGroup> deliveryGroup = Database.query(deliveryGroupQuery);

        if(!deliveryGroup.isEmpty()) {
            for(String key : CART_DELIVERY_GROUP_METADATA_MAP.keySet()) {
                String value = getFieldValue((SObject) deliveryGroup[0], CART_DELIVERY_GROUP_METADATA_MAP.get(key));

                params.add('payment_intent_data[metadata]' + key + '=' + value);
            }
        }

        params.add('&mode=' + checkoutMode);
        params.add('&payment_intent_data[setup_future_usage]=off_session');
        System.debug(result + String.join(params, '&'));
        return result + '&' + String.join(params, '&');
    }

    public static String createInvoiceLineItemsString(String invoiceId, String customerId, CartItem cartItem) {
        String result = 'customer=' + customerId + '&currency=usd&invoice=' + invoiceId;
        
        Integer unitAmount = cartItem.Type == 'Product' ? Math.round(cartItem.UnitAdjustedPriceWithItemAdj * 100) : Math.round(cartItem.ListPrice * 100);
        result += '&quantity=' + cartItem.Quantity + '&description=' + cartItem.Product2.Name;
        result += '&price_data[product]=' + cartItem.Product2.Stripe_Product_Id__c ;
        result += '&price_data[currency]=usd';
        result += '&price_data[unit_amount]=' + unitAmount;
        return result;
    }

    public static String getFieldValue(SObject obj, String field) {
        if(field.startsWith('{static} ')) {
            field = field.replace('{static} ', '');
            return field;
        }

        FormulaEval.FormulaInstance evaluator = Formula.builder()
                            .withReturnType(FormulaEval.FormulaReturnType.STRING)
                            .withType(obj.getSObjectType())
                            .withFormula(field)
                            .build();
        String result = String.valueOf(evaluator.evaluate(obj));
        return String.isNotBlank(result) ? EncodingUtil.urlEncode(result, 'UTF-8') : '';
    }

    public static Account getAccountById(String accountId) {
        return [
                SELECT Name,
                        Billing_Email__c,
                        StripeCustomerId__c
                FROM Account
                WHERE Id =:accountId
        ];
    }

    public static List<CartItem> getCartItemsByCartId(String cartId) {
        return [
                SELECT Name,
                        CartId,
                        Quantity,
                        TotalPrice,
                        ListPrice,
                        Product2.Name,
                        Product2.Stripe_Renewal_Product_Id__c,
                        Product2.Membership__c,
                        Product2.Stripe_Product_Id__c,
                        UnitAdjustedPriceWithItemAdj,
                        Type
                FROM CartItem
                WHERE CartId = :cartId AND Type = 'Product'
        ];
    }

    public static Account getAccountByStripeId(String stripeCustomerId, String accountId) {
        return [
                SELECT Id, Payment_Terms__c
                FROM Account
                WHERE Invoice_Stripe_Id__c=:stripeCustomerId 
                AND Id = :accountId
                LIMIT 1 
        ];
    }

    public static String createTaxInvoiceLineItemsString(String invoiceId, String customerId, String cartId) {
        String result = 'customer=' + customerId + '&currency=usd&invoice=' + invoiceId;

        WebCart cart = [SELECT Id, TotalTaxAmount FROM WebCart WHERE Id = :cartId LIMIT 1];
        Integer totalTaxAmount = Math.round(cart.TotalTaxAmount * 100);

        result += '&quantity=1&description=Tax';
        result += '&price_data[product]=' + TAX_STRIPE_PRODUCT_ID;
        result += '&price_data[currency]=usd';
        result += '&price_data[unit_amount]=' + totalTaxAmount;
        return result; 
    }
}