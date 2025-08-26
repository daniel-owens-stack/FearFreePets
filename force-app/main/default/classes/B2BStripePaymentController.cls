public without sharing class B2BStripePaymentController {
    private static final Map<String, String> TYPES_MAP = new Map <String, String>{
            'Cart' => 'Header',
            'Item' => 'SplitLine'
    };

    @AuraEnabled
    public static String getCustomerId(String accountId, String paymentOption) {
        
        Account account = [
                SELECT ShippingAddress, StripeCustomerId__c, Business__c, Admin_Account__c, PersonEmail, Invoice_Billing_Email__c, Invoice_Stripe_Id__c
                FROM Account
                WHERE Id = :accountId
        ];

        String customerId;

        if(paymentOption == 'paynow') {
            if (String.isBlank(account.StripeCustomerId__c) && account.PersonEmail != null) {
                B2BStripeWrapper.StripeCustomer existingCustomer = B2BStripeService.getStripeCustomerByEmail(account.PersonEmail);
                if(existingCustomer.id == null) {
                    B2BStripeWrapper.StripeCustomer response = B2BStripeService.createStripeCustomer(account.Id, account.PersonEmail);
                    account.StripeCustomerId__c = response.Id; 
                } else {
                    account.StripeCustomerId__c = existingCustomer.Id;
                }
                update account; 
            } 
            customerId = account.StripeCustomerId__c; 
        } 
        else if(paymentOption == 'invoice') {
            if (String.isBlank(account.Invoice_Stripe_Id__c) && account.Invoice_Billing_Email__c != null) {
                B2BStripeWrapper.StripeCustomer existingCustomer = B2BStripeService.getStripeCustomerByEmail(account.Invoice_Billing_Email__c);
                if(existingCustomer.id == null) {
                    B2BStripeWrapper.StripeCustomer response = B2BStripeService.createStripeCustomer(account.Id, account.Invoice_Billing_Email__c);
                    account.Invoice_Stripe_Id__c = response.Id; 
                } else {
                    account.Invoice_Stripe_Id__c = existingCustomer.Id;
                }
                update account; 
            } 
            customerId = account.Invoice_Stripe_Id__c; 
        }

        return customerId;
    }

    @AuraEnabled
    public static boolean canInvoice(String accountId){
        Account account = [SELECT Payment_Terms__c FROM Account WHERE Id =:accountId];
        if (account.Payment_Terms__c == 'Credit Card Only' || account.Payment_Terms__c == null){
            return false;
        }
        return true;
    }

    @AuraEnabled
    public static String createInvoice(Id webCartId, String customerId, String accountId) {
        Integer invoiceDueDate = B2BStripeService.getInvoiceDueDate(customerId, accountId);
        B2BStripeWrapper.Invoice invoice = B2BStripeService.createInvoice(customerId, invoiceDueDate, null);
        List<CartItem> items = B2BStripeServiceHelper.getCartItemsByCartId(webCartId);
        String stripeInvoiceId = invoice.id;
        createInvoiceItems(stripeInvoiceId, customerId, items);
        createTaxInvoiceItem(stripeInvoiceId, customerId, webCartId);
        String orderId = convertCartToOrder(webCartId, null, stripeInvoiceId );
        return orderId;
    }

    public static void createInvoiceItems(String invoiceId, String customerId, List<CartItem> items ) {
        for (CartItem item : items) {
            B2BStripeWrapper.InvoiceLineItem invoiceLineItem = B2BStripeService.createInvoiceLineItem(invoiceId, customerId, item);
        }
    }

    public static void createTaxInvoiceItem(String invoiceId, String customerId, String cartId) {
        B2BStripeWrapper.InvoiceLineItem invoiceLineItem = B2BStripeService.createTaxInvoiceLineItem(invoiceId, customerId, cartId);
    }

    @AuraEnabled
    public static B2BStripeWrapper.CheckoutSession processPayments(Id webCartId, String customerId, string href) {
        B2BStripeWrapper.CheckoutSession session = B2BStripeService.createCheckoutSession(customerId, webCartId, href);

        return session;
    }

    @AuraEnabled
    public static B2BStripeWrapper.ValidateSession validateSession(String sessionId, Id webCartId) {
        B2BStripeWrapper.CheckoutSession result = B2BStripeService.getCheckoutSession(sessionId);
        B2BStripeWrapper.ValidateSession validationResult = new B2BStripeWrapper.ValidateSession();

        validationResult.isSessionValid = (result.payment_status == 'paid') && (result.metadata.sf_id == webCartId);
        validationResult.paymentIntent = result.payment_intent;

        if(!validationResult.isSessionValid) {
            String errorMessage = 'Order creation failed for the Cart Id: ' + webCartId + 'as the stripe payment status is not updated to paid during checkout.| Payment Intent: ' + validationResult.paymentIntent;
            B2BHandleCustomException.LogException(new StringException(errorMessage), 'B2BStripePaymentController', 'validateSession');
        }
        return validationResult;
    }
    
    @AuraEnabled
    public static String convertCartToOrder(Id webCartId, String paymentIntent, String stripeInvoiceId) {
        OrderDeliveryMethod defaultDelivery = getOrderDeliveryMethod();

        String paymentMethod = null;
        if (paymentIntent != null) {
            try {
                B2BStripeWrapper.PaymentIntent intent =  B2BStripeService.retrievePaymentIntent(paymentIntent);
                paymentMethod = intent.payment_method;
            } catch (Exception e) {
                PaymentLog__c log = new PaymentLog__c(ErrorMessage__c = e.getMessage(), StackTrace__c = e.getStackTraceString(), Type__c = 'Stripe', Status__c = 'Fail');
                insert log;
            }
        }
        update new WebCart(Id = webCartId, Payment_Intent__c = paymentIntent, B2B_Cart_Id__c = webCartId);

        String cartQuery =
                'SELECT ' + String.join(getObjectFieldsForQuery(WebCart.SObjectType), ', ') + ', ' +
                        '    (SELECT ' + String.join(getObjectFieldsForQuery(CartDeliveryGroup.SObjectType), ', ') + ' FROM CartDeliveryGroups), ' +
                        '    (SELECT ' + String.join(getObjectFieldsForQuery(CartItem.SObjectType), ', ') + ' FROM CartItems), ' +
                        '    (SELECT ' + String.join(getObjectFieldsForQuery(CartItemPriceAdjustment.SObjectType), ', ') + ' FROM CartItemPriceAdjustments), ' +
                        '    (SELECT ' + String.join(getObjectFieldsForQuery(CartTax.SObjectType), ', ') + ' FROM CartItemTaxes), ' +
                        '    (SELECT ' + String.join(getObjectFieldsForQuery(WebCartAdjustmentGroup.SObjectType), ', ') + ' FROM WebCartAdjustmentGroups) ' +
                        'FROM WebCart ' +
                        'WHERE Id =: webCartId';

        Datetime now = Datetime.now();
        WebCart cart = Database.query(cartQuery);

        User cartUser = [SELECT Id, ContactId FROM User WHERE Id = :cart.OwnerId];
        Map<String, OrderDeliveryGroup> cartDeliveryToOrderGroup = new Map<String, OrderDeliveryGroup>();
        Map<String, OrderItem> orderItems = new Map<String, OrderItem>();
        Map<String, OrderAdjustmentGroup> orderAdjustmentGroups = new Map<String, OrderAdjustmentGroup>();
        Map<String, OrderItemAdjustmentLineItem> orderAdjustmentItems = new Map<String, OrderItemAdjustmentLineItem>();
        Map<String, OrderItemTaxLineItem> orderTaxItems = new Map<String, OrderItemTaxLineItem>();

        Order newOrder = new Order();

        transferMatchedFields(cart, newOrder);

        newOrder.Status = 'Draft';
        newOrder.OrderedDate = now;
        newOrder.EffectiveDate = Date.valueOf(now);
        newOrder.BillToContactId = cartUser.ContactId;
        newOrder.ShipToContactId = cartUser.ContactId;
        newOrder.CustomerAuthorizedById = cartUser.ContactId;
        newOrder.PoNumber = cart.PoNumber;
        newOrder.StripePaymentMethod__c = paymentMethod;
        newOrder.SalesStoreId = B2BUtils.getWebstoreID();
        newOrder.Payment_Intent__c = paymentIntent;
        newOrder.InvoiceId__c = stripeInvoiceId;
        newOrder.B2B_Cart_Id__c = webCartId;
        insert newOrder;

        //Start Delivery Group
        for (CartDeliveryGroup cartDeliveryGroupItem : cart.CartDeliveryGroups) {
            OrderDeliveryGroup deliveryGroup = new OrderDeliveryGroup();

            transferMatchedFields(cartDeliveryGroupItem, deliveryGroup);

            deliveryGroup.DeliveryInstructions = cartDeliveryGroupItem.ShippingInstructions;
            deliveryGroup.OrderDeliveryMethodId = cartDeliveryGroupItem.DeliveryMethodId != null 
                ? cartDeliveryGroupItem.DeliveryMethodId
                : defaultDelivery != null ? defaultDelivery.Id :null ;
            deliveryGroup.DeliverToName = cartDeliveryGroupItem.Name;
            deliveryGroup.OrderId = newOrder.Id;

            cartDeliveryToOrderGroup.put(cartDeliveryGroupItem.Id, deliveryGroup);
        }

        if (!cartDeliveryToOrderGroup.isEmpty()) {
            insert cartDeliveryToOrderGroup.values();
        }

        //Start Cart Item transfer
        for (CartItem cartItem : cart.CartItems) {
            OrderItem newOrderItem = new OrderItem();

            transferMatchedFields(cartItem, newOrderItem);

            newOrderItem.Type = cartItem.Type == 'Product' ? 'Order Product' : 'Delivery Charge';
            newOrderItem.OrderId = newOrder.Id;
            newOrderItem.OrderDeliveryGroupId = cartDeliveryToOrderGroup.get(cartItem.CartDeliveryGroupId).Id;
            newOrderItem.UnitPrice = cartItem.SalesPrice != null ? cartItem.SalesPrice : cartItem.ListPrice;
            newOrderItem.ListPrice = cartItem.ListPrice != null ? cartItem.ListPrice : cartItem.SalesPrice;
            newOrderItem.TotalLineAmount = cartItem.TotalPrice;

            orderItems.put(cartItem.Id, newOrderItem);
        }


        if (!orderItems.isEmpty()) {
            insert orderItems.values();
        }

        //Start Cart Adjustment Groups transfer
        for (WebCartAdjustmentGroup cartAdjustmentGroup : cart.WebCartAdjustmentGroups) {
            OrderAdjustmentGroup newOrderAdjustmentGroup = new OrderAdjustmentGroup();

            transferMatchedFields(cartAdjustmentGroup, newOrderAdjustmentGroup);

            newOrderAdjustmentGroup.OrderId = newOrder.Id;
            newOrderAdjustmentGroup.Type = TYPES_MAP.get(cartAdjustmentGroup.AdjustmentTargetType);
            orderAdjustmentGroups.put(cartAdjustmentGroup.Id, newOrderAdjustmentGroup);
        }

        if (!orderAdjustmentGroups.isEmpty()) {
            insert orderAdjustmentGroups.values();
        }

        Map<Id, CartItem> cartItems = new Map<Id, CartItem> (cart.CartItems);

        //Start Cart Item Price Adjustments transfer
        for (CartItemPriceAdjustment cartItemPriceAdjustment : cart.CartItemPriceAdjustments) {
            OrderItemAdjustmentLineItem newOrderAdjustmentItem = new OrderItemAdjustmentLineItem();

            transferMatchedFields(cartItemPriceAdjustment, newOrderAdjustmentItem);

            newOrderAdjustmentItem.OrderItemId = orderItems.get(cartItemPriceAdjustment.CartItemId).Id;
            newOrderAdjustmentItem.OrderAdjustmentGroup = orderAdjustmentGroups.get(cartItemPriceAdjustment.WebCartAdjustmentGroupId);
            newOrderAdjustmentItem.Amount = cartItemPriceAdjustment.TotalAmount != null
                    ? cartItemPriceAdjustment.TotalAmount
                    : cartItems.get(cartItemPriceAdjustment.CartItemId).NetAdjustmentAmount;

            orderAdjustmentItems.put(cartItemPriceAdjustment.Id, newOrderAdjustmentItem);
        }

        if (!orderAdjustmentItems.isEmpty()) {
            insert orderAdjustmentItems.values();
        }
       
        //Start Cart Tax transfer
        for (CartTax cartTax : cart.CartItemTaxes) {
            OrderItemTaxLineItem newOrderTaxItem = new OrderItemTaxLineItem();

            transferMatchedFields(cartTax, newOrderTaxItem);
            newOrderTaxItem.OrderItemId = orderItems.get(cartTax.CartItemId).Id;
            newOrderTaxItem.TaxEffectiveDate = cartTax.TaxCalculationDate;
            newOrderTaxItem.Type = cartTax.TaxType;
            newOrderTaxItem.Rate = cartTax.TaxRate;
            newOrderTaxItem.Amount = cartItems.get(cartTax.cartItemId).AdjustmentTaxAmount != null
                    ? cartItems.get(cartTax.cartItemId).AdjustmentTaxAmount
                    : cartTax.Amount;
            newOrderTaxItem.OrderItemAdjustmentLineItem = String.isNotBlank(cartTax.CartItemPriceAdjustmentId)
                    ? orderAdjustmentItems.get(cartTax.CartItemPriceAdjustmentId)
                    : null;

            orderTaxItems.put(cartTax.Id, newOrderTaxItem);
        }

        if (!orderTaxItems.isEmpty()) {
            insert orderTaxItems.values();
        }

        CartCheckoutSession session = [
                SELECT Id, WebCartId, State, OrderId, IsArchived
                FROM CartCheckoutSession
                WHERE IsArchived = false AND WebCartId = :cart.Id
        ];

        session.OrderId = newOrder.Id;
        update session;

        cart.Status = 'PendingDelete';
        update cart;

        newOrder.Status = 'Activated';
        update newOrder;

        ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
        osir.orderId = newOrder.Id;
        osir.status = 'Created';
        osir.name = UUID.randomUUID().toString().toUpperCase();
        osir.businessModel = 'B2B';
        osir.orderLifeCycleType = 'MANAGED';

        if (Test.isRunningTest()) {
            return newOrder.Id;
        } else {
            ConnectApi.OrderSummaryOutputRepresentation osor = ConnectApi.OrderSummaryCreation.createOrderSummary(osir);

            OrderSummary summary = [SELECT OrderNumber FROM OrderSummary WHERE Id = :osor.orderSummaryId];
            return summary.OrderNumber;
        }
    }

    public static void transferMatchedFields(SObject fromSobject, SObject toSObject) {
        Map<String, Schema.SObjectField> fromSObjectFields = fromSobject.getSObjectType().getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> toSObjectFields = toSObject.getSObjectType().getDescribe().fields.getMap();

        for (String field : fromSObjectFields.keySet()) {
            if (field == 'Id' || field == 'OwnerId' || field == 'Status') {
                continue;
            }

            SObjectField toField = toSObjectFields.get(field);
            //If field is empty it's not retrieved by the dynamic soql query. Setting null as from field doesn't have any value
            try {
                if (toField != null && (toField.getDescribe().isCreateable() || toField.getDescribe().isCustom())) {
                    toSObject.put(field, fromSobject.get(field));
                }
            } catch (System.SObjectException e) {
                toSObject.put(field, null);
            }
        }
    }

    public static List<String> getObjectFieldsForQuery(Schema.SObjectType objectType) {
        List<String> fields = new List<String>();

        for (Schema.SObjectField item : objectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult describe = item.getDescribe();

            if (describe.isAccessible() && (describe.isUpdateable() || describe.isCreateable())) {
                fields.add(describe.getName());
            }
        }

        fields.add('Id');
        System.debug('Fields: ' + fields);
        return fields;
    }


    public static OrderDeliveryMethod getOrderDeliveryMethod() {
        List<OrderDeliveryMethod> orderMethod = [SELECT Id FROM OrderDeliveryMethod WHERE IsActive = true];

        if(orderMethod.isEmpty()) {
            OrderDeliveryMethod orderDeliveryMethod = new OrderDeliveryMethod(Name = 'Default Delivery', IsActive = true);
            insert orderDeliveryMethod;

            return orderDeliveryMethod;
        }

        return orderMethod[0];
    }

    public class B2BStripeException extends Exception {
    }
}