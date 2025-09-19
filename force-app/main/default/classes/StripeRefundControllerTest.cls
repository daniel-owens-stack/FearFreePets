@IsTest(SeeAllData=true)
private class StripeRefundControllerTest {
    
    // ---- Stripe refund mock: always 200 OK ----
    private class StripeRefundMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod(), 'Expected POST');
            System.assert(req.getEndpoint().contains('/v1/refunds'), 'Expected /v1/refunds');
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"id":"re_test_123","object":"refund","status":"succeeded"}');
            return res;
        }
    }
    
    // ------- Shared setup using your factory pattern -------
    private static void ensureB2BSeed() {
        // Idempotent seeding using your factory methods
        if ([SELECT count() FROM WebStore WHERE Name = 'TestWebStore'] == 0) {
            B2BTestDataFactory.createWebStore();
        }
        if ([SELECT count() FROM Account WHERE Name = 'Test Account'] == 0) {
            String accountId = B2BTestDataFactory.createAccount();
            String contactId = B2BTestDataFactory.createContact(accountId);
            B2BTestDataFactory.createCommunityUser(contactId);
        }
        if ([SELECT count() FROM Product2 WHERE Name = 'Test Product1'] == 0) {
            B2BTestDataFactory.createProduct();
        }
    }
    
    private static Id createOrderSummaryWithProduct(Id productId) {
        ensureB2BSeed();
        
        Id accountId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        
        // Create the Order with the specified product
        Id orderId = B2BTestDataFactory.createOrder(accountId, productId);
        
        // Create the Order Summary (exactly your pattern)
        ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
        osir.orderId = orderId;
        osir.orderLifeCycleType = 'UNMANAGED';
        ConnectApi.OrderSummaryOutputRepresentation osor = ConnectApi.OrderSummaryCreation.createOrderSummary(osir);
        
        // Return the Order Summary Id (String type in ConnectApi, but valid 18-char Id)
        return (Id) osor.orderSummaryId;
    }
    
    // Convenience: set Payment Intent (controller requires it; type can be Long Text and is fine to update)
    private static void stampPaymentIntent(Id orderSummaryId, String pi) {
        OrderSummary os = [SELECT Id FROM OrderSummary WHERE Id = :orderSummaryId LIMIT 1];
        os.Payment_Intent__c = pi;
        update os;
    }
    
    // Build a "full refund" payload for every OIS on the OS (covers shipping/tax lines too)
    private static List<Object> buildFullRefundPayload(Id orderSummaryId) {
        List<OrderItemSummary> items = [
            SELECT Id, Quantity, TotalLineAmountWithTax
            FROM OrderItemSummary
            WHERE OrderSummaryId = :orderSummaryId
        ];
        List<Object> payload = new List<Object>();
        for (OrderItemSummary ois : items) {
            Integer q = 0;
            try { q = (ois.Quantity == null) ? 0 : Integer.valueOf(ois.Quantity); } catch (Exception ignore) {}
            if (q > 0) {
                payload.add(new Map<String, Object>{
                    'itemId' => String.valueOf(ois.Id),
                    'qtyToRefund' => q
                });
            } else {
                // If quantity is 0/null (can happen for shipping/tax lines), just refund the full amount by partialAmount
                Decimal amt = (ois.TotalLineAmountWithTax == null) ? 0 : ois.TotalLineAmountWithTax;
                if (amt > 0) {
                    payload.add(new Map<String, Object>{
                        'itemId' => String.valueOf(ois.Id),
                        'partialAmount' => amt
                    });
                }
            }
        }
        return payload;
    }
    
    // ------- Tests -------
    
    @IsTest
    static void partialRefund_byAmount_setsPartiallyRefunded() {
        // Create a simple active product
        Product2 p = new Product2(Name='PF-Amt', IsActive=true);
        insert p;
        
        Id osId = createOrderSummaryWithProduct(p.Id);
        stampPaymentIntent(osId, 'pi_partial_001');
        
        // Grab one line and refund a portion of it by amount
        OrderItemSummary oneLine = [
            SELECT Id, TotalLineAmountWithTax
            FROM OrderItemSummary
            WHERE OrderSummaryId = :osId
            LIMIT 1
        ];
        Decimal lineTotal = (oneLine.TotalLineAmountWithTax == null) ? 0 : oneLine.TotalLineAmountWithTax;
        System.assert(lineTotal > 0, 'Seeded line should have a positive total.');
        
        Decimal partial = (lineTotal / 2);
        if (partial == 0) partial = 1;
        
        List<Object> items = new List<Object>{
            new Map<String, Object>{
                'itemId' => String.valueOf(oneLine.Id),
                'partialAmount' => partial
            }
        };
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeRefundMock());
        StripeRefundController.refundSelectedItems(osId, 'partial by amount', items);
        Test.stopTest();
        
        OrderSummary after = [SELECT Id, Status FROM OrderSummary WHERE Id = :osId];
        System.assertEquals('Partially Refunded', after.Status, 'Should be Partially Refunded');
    }
    
    @IsTest
    static void fullRefund_allLines_setsRefunded() {
        // Two products so the order summary has multiple lines (the factory may aggregate; we handle all lines anyway)
        Product2 p1 = new Product2(Name='FR-Alpha', IsActive=true);
        Product2 p2 = new Product2(Name='FR-Beta',  IsActive=true);
        insert new List<Product2>{ p1, p2 };
        
        // Create one OS for p1, then add a second order/OS? The factory makes one product per order.
        // To keep a single OS with multiple lines, we’ll just create a second product **before** the order creation and
        // rely on the factory’s behavior; but if your factory creates one line per product only, a single product is fine.
        Id osId = createOrderSummaryWithProduct(p1.Id);
        // If you need to ensure multiple lines, you can also insert a second Order & OS and refund both; but here we
        // refund **all lines** found on this OS (shipping/tax included), which is what the controller status uses.
        stampPaymentIntent(osId, 'pi_full_001');
        
        List<Object> items = buildFullRefundPayload(osId);
        System.assert(!items.isEmpty(), 'Expected at least one line to refund');
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeRefundMock());
        StripeRefundController.refundSelectedItems(osId, 'full refund all lines', items);
        Test.stopTest();
        
        OrderSummary after = [SELECT Id, Status FROM OrderSummary WHERE Id = :osId];
        System.assertEquals('Refunded', after.Status, 'With every line fully refunded, order should be Refunded');
    }
    
    @IsTest
    static void fullRefund_renewalLine_cancelsILMA_and_setsRefunded() {
        // Renewal product
        Product2 pRenew = new Product2(Name='Renewal SKU', IsActive=true, Renewal_Product__c=true);
        insert pRenew;
        
        Id osId = createOrderSummaryWithProduct(pRenew.Id);
        stampPaymentIntent(osId, 'pi_full_renewal_001');
        
        // Create ILMA for the account used by the factory
        Id acctId = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        Account_Membership__c ilma = new Account_Membership__c(
            Account_Id__c = acctId,
        Status__c = 'Active'
            );
        insert ilma;
        
        // Link the ILMA to the renewal line
        OrderItemSummary renewLine = [
            SELECT Id, Quantity, TotalLineAmountWithTax
            FROM OrderItemSummary
            WHERE OrderSummaryId = :osId
            LIMIT 1
        ];
        renewLine.Individual_Membership_Assignment__c = ilma.Id;
        update renewLine;
        
        // Refund the renewal line fully (qty or full amount)
        List<Object> items = new List<Object>();
        Integer q = 0;
        try { q = (renewLine.Quantity == null) ? 0 : Integer.valueOf(renewLine.Quantity); } catch (Exception ignore) {}
        if (q > 0) {
            items.add(new Map<String, Object>{
                'itemId' => String.valueOf(renewLine.Id),
                'qtyToRefund' => q
            });
        } else {
            Decimal amt = (renewLine.TotalLineAmountWithTax == null) ? 0 : renewLine.TotalLineAmountWithTax;
            items.add(new Map<String, Object>{
                'itemId' => String.valueOf(renewLine.Id),
                'partialAmount' => amt
            });
        }
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeRefundMock());
        StripeRefundController.refundSelectedItems(osId, 'renewal full refund', items);
        Test.stopTest();
        
        OrderSummary after = [SELECT Id, Status FROM OrderSummary WHERE Id = :osId];
        ilma = [SELECT Id, Status__c FROM Account_Membership__c WHERE Id = :ilma.Id];
        
        System.assertEquals('Refunded', after.Status, 'Order should be Refunded after full renewal refund');
        System.assertEquals('Voided', ilma.Status__c, 'ILMA should be Voided for renewal product');
    }
    
    @IsTest(SeeAllData=true)
    static void getOrderItems_populatesIlmaExtras() {
        // Renewal product
        Product2 pRenew = new Product2(Name='GI-Renew', IsActive=true, Renewal_Product__c=true);
        insert pRenew;
        
        // OS with that product
        Id osId = createOrderSummaryWithProduct(pRenew.Id);
        
        // ILMA for the account your factory uses
        Id acctId = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1].Id;
        Account_Membership__c ilma = new Account_Membership__c(Account_Id__c = acctId, Status__c = 'Active');
        insert ilma;
        
        // Link ILMA on the OS line
        OrderItemSummary line = [
        SELECT Id, Individual_Membership_Assignment__c
        FROM OrderItemSummary
        WHERE OrderSummaryId = :osId
        LIMIT 1
    ];
        line.Individual_Membership_Assignment__c = ilma.Id;
        update line;
        
        // Exercise getOrderItems -> wrapper enrichment
        Test.startTest();
        List<StripeRefundController.OrderItemWrapper> rows =
            StripeRefundController.getOrderItems(osId);
        Test.stopTest();
        
        // Find our line and assert enrichment
        StripeRefundController.OrderItemWrapper w;
        for (StripeRefundController.OrderItemWrapper x : rows) {
            if (x.Id == String.valueOf(line.Id)) { w = x; break; }
        }
        System.assertNotEquals(null, w, 'Wrapper for the linked line should exist');
        System.assertEquals(true, w.IsRenewalProduct, 'Should flag renewal product');
        System.assertEquals(String.valueOf(acctId), w.IlmaAccountId, 'Should surface ILMA Account Id');
        String accName = [SELECT Name FROM Account WHERE Id = :acctId].Name;
        System.assertEquals(accName, w.IlmaAccountName, 'Should surface ILMA Account Name');
    }
    
}