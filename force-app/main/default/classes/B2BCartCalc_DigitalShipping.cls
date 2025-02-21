// This sample is for the situations where Digital Shipping is required, meaning there is no shipping cost. 

// This class must extend the CartExtension.ShippingCartCalculator class to be processed.
public class B2BCartCalc_DigitalShipping extends CartExtension.ShippingCartCalculator {
  
    public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();
        // Clean up CVO based on Shipping
        CartExtension.CartValidationOutputList cartValidationOutputList = cart.getCartValidationOutputs();

        for (Integer i = (cartValidationOutputList.size() - 1); i >= 0; i--) {
            CartExtension.CartValidationOutput cvo = cartValidationOutputList.get(i);

            if (cvo.getType() == CartExtension.CartValidationOutputTypeEnum.SHIPPING) {
                cartValidationOutputList.remove(cvo);
            }
        }

        // To create the Cart delivery group methods, we need to get the ID of the cart delivery group.
        CartExtension.CartDeliveryGroupList cartDeliveryGroups = cart.getCartDeliveryGroups();
        if (cartDeliveryGroups.size() == 0) {
            CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
            CartExtension.CartValidationOutputTypeEnum.SHIPPING,
            CartExtension.CartValidationOutputLevelEnum.ERROR
            );
            cvo.setMessage('No Cart Delivery Groups have been defined');
            cartValidationOutputList.add(cvo);
        } else {
            CartExtension.CartItemList cartItems = cart.getCartItems();
            Integer numberOfUniqueItems = cartItems.size();
            CartExtension.CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups.get(0);
            CartExtension.CartDeliveryGroupMethodList cartDeliveryGroupMethods = cartDeliveryGroup.getCartDeliveryGroupMethods();

            // Clean up the CartDeliveryGroupMethods
            for (Integer i = (cartDeliveryGroupMethods.size() - 1); i >= 0; i--) {
                CartExtension.CartDeliveryGroupMethod method = cartDeliveryGroupMethods.get(i);
                cartDeliveryGroupMethods.remove(method);
            }
            // To clear selected Cart Delivery Group Method
            cartDeliveryGroup.setSelectedCartDeliveryGroupMethod(null);

            // Get the shipping product - in this case we use SKU to find the right shipping product
            List<Product2> shippingProducts = [SELECT Id FROM Product2 WHERE Name ='Delivery Charge' AND IsActive = true];
            String shippingProduct = shippingProducts.isEmpty() ? null : Id.valueOf(shippingProducts[0].Id);
            
            CartDeliveryGroup cdg = [SELECT ID,DeliverToCountry FROM CartDeliveryGroup WHERE CartId =: cart.getId() LIMIT 1];
            List<CartItem> lstWebCartItem = [
                SELECT Id, Product2Id, Product2.VolumeIn__c, 
                    Product2.Freight_Amount_US__c, Product2.Freight_Amount_INTL__c, 
                    Product2.IsShippingChargeNotApplicable, Quantity 
                FROM CartItem 
                WHERE CartId = :cart.getId()
            ];
            
            Decimal shipPrice = 0;
            Boolean isUS = cdg.DeliverToCountry == 'US';

            if (lstWebCartItem != null && !lstWebCartItem.isEmpty()){

                for (CartItem record : lstWebCartItem) {
                
                    if (record.Product2 != null && !record.Product2.IsShippingChargeNotApplicable) {
                        Decimal freightAmount = 0;
                        Integer quantity = (record.Quantity != null) ? Integer.valueOf(record.Quantity) : 0;

                        if (isUS && record.Product2.Freight_Amount_US__c != null) {
                            freightAmount = record.Product2.Freight_Amount_US__c;
                        } else if (!isUS && record.Product2.Freight_Amount_INTL__c != null) {
                            freightAmount = record.Product2.Freight_Amount_INTL__c;
                        }

                        shipPrice += freightAmount * quantity;
                    }
                }
            }        
            Decimal calculatedShipping = (shipPrice == 0) ? 0 : shipPrice;
            CartExtension.CartDeliveryGroupMethod cartDeliveryGroupMethod01 = new CartExtension.CartDeliveryGroupMethod('Shipping Charge', calculatedShipping, shippingProduct);
            cartDeliveryGroupMethod01.setCarrier('USPS');
            cartDeliveryGroupMethod01.setClassOfService('Digital Shipping');

            cartDeliveryGroupMethods.add(cartDeliveryGroupMethod01);

            // Set the delivery method ID that will be used for the order summary
            cartDeliveryGroup.setDeliveryMethodId(cartDeliveryGroupMethod01.getId());
        }
    }
}