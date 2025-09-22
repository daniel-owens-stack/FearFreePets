/**
 * @description       : 
 * @author            : Poojitha Anthati
 * @group             : 
 * @last modified on  : 09-22-2025
 * @last modified by  : Poojitha Anthati
**/
public without sharing class TaxCartCalculatorExtension extends CartExtension.TaxCartCalculator {
    // You MUST change this to be your service or you must launch your own Third Party Service
    // and add the host in Setup | Security | Remote site settings.
    private static String externalTaxHost = 'https://example.com';
  
    // You MUST change the useExternalService to True if you want to use the Third Party Service.
    private static Boolean useExternalService = false;
      
    public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
    CartExtension.Cart cart = request.getCart();
    try {
        if (request == null || request.getCart() == null) {
            throw new CalloutException('Request or Cart is null.');
        }

        // CartExtension.Cart cart = request.getCart();
        existingCartValidationMessageCleanUp(cart);
        existingCartTaxesCleanUp(cart);

        if (cart.getCartItems() == null) {
            throw new CalloutException('Cart items are null.');
        }
        
        CartExtension.CartItemList cartItems = cart.getCartItems();
        
        String webstoreId = cart.getWebstoreId();
        if (String.isEmpty(webstoreId)) {
            throw new CalloutException('WebstoreId is null or empty.');
        }

        TaxMetaData taxMetaData = getMetaData(webstoreId, '', '');
        if (taxMetaData == null) {
            throw new CalloutException('TaxMetaData is null.');
        }

        TaxProviderRequest taxProviderRequest = createTaxRequest(cart, taxMetaData);
        if (taxMetaData.customerTaxExemption) {
            setExemptionDetails(taxProviderRequest, taxMetaData);
        }

        TaxProvider tProvider = TaxProviderFactory.getTaxProvider(taxMetaData);

        if (tProvider == null || taxProviderRequest == null) {
            throw new CalloutException('TaxProvider or TaxProviderRequest is null.');
        }

        TaxProviderResponse tpResponse = tProvider.calculateTax(taxProviderRequest);

        if (!Test.isRunningTest()) {
            setTaxInCart(cart, taxMetaData, tpResponse);
        }
        } catch (Exception e) {  
            if(!cart.getCartDeliveryGroups().isEmpty()) {
              //Set custom error message
              CartExtension.CartValidationOutputList cartValidationOutputList = cart.getCartValidationOutputs();
              CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
                CartExtension.CartValidationOutputTypeEnum.TAXES,
                CartExtension.CartValidationOutputLevelEnum.ERROR
              );
              cvo.setMessage(Label.B2B_Custom_Tax_Exception_Message);
              cartValidationOutputList.add(cvo);
            }
            throw new CalloutException('There was a problem with the request.');
        }
        return;
    }
    
  
    public virtual void existingCartTaxesCleanUp(CartExtension.Cart cart) {
      CartExtension.CartItemList cartItemCollection = cart.getCartItems();
      for (Integer i = (cartItemCollection.size() - 1); i >= 0; i--) {
        CartExtension.CartItem cartItem = cartItemCollection.get(i);
        if (cartItem.getCartTaxes().size() > 0) {
          for (Integer j = (cartItem.getCartTaxes().size() - 1); j >= 0; j--) {
            cartItem.getCartTaxes().remove(cartItem.getCartTaxes().get(j));
          }
        }
        if (cartItem.getCartItemPriceAdjustments().size() > 0) {
          for (Integer k = (cartItem.getCartItemPriceAdjustments().size() - 1);k >= 0;  k--) {
            CartExtension.CartTaxList cipaTaxes = cartItem.getCartItemPriceAdjustments() .get(k) .getCartTaxes();
            if (cipaTaxes.size() > 0) {
              for (Integer l = (cartItem.getCartItemPriceAdjustments().size() - 1);l >= 0; l-- ) {
                cipaTaxes.remove(cipaTaxes.get(l));
              }
            }
          }
        }
      }
    }
  
    public virtual void existingCartValidationMessageCleanUp(CartExtension.Cart cart) {
      CartExtension.CartValidationOutputList cartValidationOutputCollection = cart.getCartValidationOutputs();
      for (Integer i = (cartValidationOutputCollection.size() - 1); i >= 0; i--) {
        CartExtension.CartValidationOutput cvo = cartValidationOutputCollection.get(i);
        if (cvo.getType() == CartExtension.CartValidationOutputTypeEnum.TAXES) {
          cartValidationOutputCollection.remove(cvo);
        }
      }
    }
  
    public virtual void setTaxInCart( CartExtension.Cart cart,TaxMetaData taxMetaData,TaxProviderResponse tpResponse) {
        Map<String, TaxableCartItem> tLineItems;
        if(!test.isRunningTest()){
              tLineItems = tpResponse.taxableCartItems;
        }else{
             tLineItems = new  Map<String, TaxableCartItem>();
        }
        
       CartExtension.CartItemList cartItemCollection = cart.getCartItems();
      for (Integer i = (cartItemCollection.size() - 1); i >= 0; i--) {
        CartExtension.CartItem cartItem = cartItemCollection.get(i);
        if (!taxMetaData.shippingItemsTaxable && cartItem.getType() == CartExtension.SalesItemTypeEnum.CHARGE  ) {
          continue;
        }
        TaxableCartItem tLineItem;
        if (cartItem.getType() == CartExtension.SalesItemTypeEnum.PRODUCT) {
          tLineItem = tLineItems.get(cartItem.getId());
        } else {
          tLineItem = tLineItems.get(cartItem.getCartDeliveryGroup().getId());
        }
         System.debug('tLineItem++'+ tLineItem);
        if (tLineItem != null) {
          for (LineItemTaxDetails litDetails : tLineItem.lineItemTexas) {
            CartExtension.CartTaxList cartTaxCollection = cartItem.getCartTaxes();
            CartExtension.CartTax cartTax = new CartExtension.CartTax(
              CartExtension.TaxTypeEnum.ESTIMATED,
              litDetails.tax,
              'Sales'
            );
            cartTax.setTaxRate(String.valueOf(litDetails.rate));
            cartTaxCollection.add(cartTax);
          }
        }
      }
    }
    public virtual TaxMetaData getMetaData(String webStoreId,String transactionType,String docType) {
      return TaxConfiguration.getMetaDataDTO(webStoreId,transactionType,docType);
    }
  
    public virtual TaxProviderRequest createTaxRequest(CartExtension.Cart cart,TaxMetaData taxMetaData) {
      Map<String, TaxableCartItem> taxableCartItems = new Map<String, TaxableCartItem>();
      TaxProviderRequest request = new TaxProviderRequest();
      String vatCode = (String) cart.getCustomField('B2B_International_Tax_Id__c');
      String cartId = cart.getId();
      request.cartId = cartId;
      request.taxMetaData = taxMetaData;
      request.currencyCode = cart.getCurrencyIsoCode();
      CartExtension.CartDeliveryGroupList cartDeliveryGroups = cart.getCartDeliveryGroups();
      if (cartDeliveryGroups.size() == 1) {
        CartExtension.CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups.get(
          0
        );
        request.hasMultipleShipments = false;
        request.street = cartDeliveryGroup.getDeliverToAddress().Street;
        request.city = cartDeliveryGroup.getDeliverToAddress().City;
        request.state = cartDeliveryGroup.getDeliverToAddress().State;
        request.postalCode = cartDeliveryGroup.getDeliverToAddress().PostalCode;
        request.country = cartDeliveryGroup.getDeliverToAddress().Country;
      } else {
        request.hasMultipleShipments = true;
      }
      CartExtension.CartItemList cartItemCollection = cart.getCartItems();
      for (Integer i = (cartItemCollection.size() - 1); i >= 0; i--) {
        CartExtension.CartItem cartItem = cartItemCollection.get(i);
        if ( !taxMetaData.shippingItemsTaxable && cartItem.getType() == CartExtension.SalesItemTypeEnum.CHARGE  ) {
          continue;
        }
  
        TaxableCartItem tcItem = new TaxableCartItem();
  
        tcItem.amount = cartItem.getTotalAmount();
        tcItem.quantity = cartItem.getQuantity();
        tcItem.sku = cartItem.getSku();
        tcItem.vatCode = vatCode;
        if (request.hasMultipleShipments) {
          tcItem.street = cartItem.getCartDeliveryGroup().getDeliverToAddress() .Street;
          tcItem.city = cartItem.getCartDeliveryGroup().getDeliverToAddress().City;
          tcItem.state = cartItem.getCartDeliveryGroup().getDeliverToAddress().State;
          tcItem.postalCode = cartItem.getCartDeliveryGroup().getDeliverToAddress() .PostalCode;
          tcItem.country = cartItem.getCartDeliveryGroup().getDeliverToAddress().Country;
        }
        if (cartItem.getType() == CartExtension.SalesItemTypeEnum.PRODUCT) {
          tcItem.id = cartItem.getId();
          tcItem.lineItemType = 'Product';
          taxableCartItems.put(cartItem.getId(), tcItem);
        } else {
          tcItem.id = cartItem.getCartDeliveryGroup().getId();
          tcItem.lineItemType = 'Charge';
          tcItem.sku = String.isNotBlank(cartItem.getSku()) ? cartItem.getSku() : 'Shipping-Item';
          taxableCartItems.put(cartItem.getCartDeliveryGroup().getId(), tcItem);
        }
      }
      // Fetching the details from DB as not available through CALC API 
      if (taxMetaData.useProductTaxCodes || taxMetaData.productTaxExemption) {
        String query = 'SELECT Id, Sku, TotalLineAmount, Quantity, Type, Product2Id,Name,Product2.Family,CartDeliveryGroup.Id,Product2.Taxable__c';
        if (taxMetaData.useProductTaxCodes) {
          query += ',Product2.Tax_Class_Id__c';
        }
        if (taxMetaData.productTaxExemption) {
          query += ',Product2.Entity_Use_Code__c,Product2.Exemption_Code__c';
        }
        query += ' FROM CartItem WHERE  cartId=:cartId';
        if (!taxMetaData.shippingItemsTaxable) {
          query += ' AND Type = \'Product\'';
        }
        TaxableCartItem tci;
        for (CartItem cartItem : Database.query(query)) {
          if (cartItem.Type.equals('Product')) {
            tci = taxableCartItems.get(cartItem.Id);
          } else {
            tci = taxableCartItems.get(cartItem.CartDeliveryGroup.Id);
          }
          if (tci != null) {
            if (
              taxMetaData.productTaxExemption && !cartItem.Product2.Taxable__c
            ) {
              tci.productExemptionCode = cartItem.Product2.Exemption_Code__c;
              tci.entityUseCode = cartItem.Product2.Entity_Use_Code__c;
            }
            if (taxMetaData.useProductTaxCodes && cartItem.Product2.Taxable__c) {
              if (cartItem.Product2.Tax_Class_Id__c != null) {
                tci.taxClassId = cartItem.Product2.Tax_Class_Id__c;
              } else if (cartItem.Type.equals('Product')) {
                tci.taxClassId = taxMetaData.defaultProductTaxCode;
              } else {
                tci.taxClassId = taxMetaData.defaultShippingTaxCode;
              }
            }
          }
        }
      }
      request.taxTransacionType = taxMetaData.documentType != null
        ? taxMetaData.documentType : 'SalesOrder';
      request.taxableCartItems = taxableCartItems;
      return request;
    }
  
    public virtual void setExemptionDetails(TaxProviderRequest taxProviderRequest,TaxMetaData taxMetaData) {
      if (taxMetaData.customerTaxExemption) {
        User user = [
          SELECT
            Id,
            AccountId,
            Account.Exemption_Code__c,
            Account.Entity_Use_Code__c
          FROM User
          WHERE id = :UserInfo.getUserId()
          LIMIT 1
        ];
        taxProviderRequest.customerExemptionCode = user.Account.Exemption_Code__c;
        taxProviderRequest.entityUseCode = user.Account.Entity_Use_Code__c;
      }
    }
  }