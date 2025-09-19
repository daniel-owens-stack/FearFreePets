public without sharing class StripeRefundController {
    
    public class ItemRefundWrapper {
        @AuraEnabled public String itemId;
        @AuraEnabled public Integer qtyToRefund;
        @AuraEnabled public Decimal partialAmount;
    }
    
    public class OrderItemWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String ProductName;
        @AuraEnabled public Decimal TotalAmtWithTax;
        @AuraEnabled public Decimal RefundedAmount;
        @AuraEnabled public Integer Quantity;
        @AuraEnabled public Integer AlreadyRefundedQty;
        
        // NEW for modal
        @AuraEnabled public String IlmaAccountId;
        @AuraEnabled public String IlmaAccountName;
        @AuraEnabled public Boolean IsRenewalProduct;
        
        public OrderItemWrapper(OrderItemSummary i) {
            Id = String.valueOf(i.Id);
            ProductName = (i.Product2 != null) ? i.Product2.Name : i.Name;
            TotalAmtWithTax = i.TotalAmtWithTax;
            RefundedAmount = i.Refunded_Amount__c;
            Quantity = (i.Quantity == null) ? 0 : Integer.valueOf(i.Quantity);
            AlreadyRefundedQty = (i.Refund_Quantity__c == null) ? 0 : Integer.valueOf(i.Refund_Quantity__c);
            // IlmaAccountId/Name + IsRenewalProduct are set in getOrderItems after extra queries
        }
    }
    
    @AuraEnabled
    public static String refundSelectedItems(
        Id orderSummaryId,
    String refundReason,
    List<Object> itemRefundsRaw
    ) {
        try {
            String stamp = System.now().format('yyyy-MM-dd HH:mm:ss');
            
            // Parse incoming items
            List<ItemRefundWrapper> itemRefunds = new List<ItemRefundWrapper>();
            if (itemRefundsRaw != null) {
                for (Object o : itemRefundsRaw) {
                    itemRefunds.add(
                        (ItemRefundWrapper) JSON.deserialize(JSON.serialize(o), ItemRefundWrapper.class)
                        );
                }
            }
            
            // Order Summary (include totals for later)
            OrderSummary os = [
                SELECT Id, Payment_Intent__c, Refund_Reason__c, Status,
                       Total_Refunded_Amount__c, Total_Amount_After_Refund__c
                FROM OrderSummary
                WHERE Id = :orderSummaryId
                LIMIT 1
            ];
            if (String.isBlank(os.Payment_Intent__c)) {
                throw new AuraHandledException('No Stripe PaymentIntent ID found on this Order Summary.');
            }
            
            // Collect item ids we’re refunding
            Set<Id> itemIds = new Set<Id>();
            for (ItemRefundWrapper ir : itemRefunds) {
                if (!String.isBlank(ir.itemId)) {
                    try { itemIds.add((Id) ir.itemId); } catch (Exception ignore) {}
                }
            }
            
            // Lines we will touch
            Map<Id, OrderItemSummary> rows = new Map<Id, OrderItemSummary>([
                SELECT Id, Refunded_Amount__c, Refund_Reason__c, Refund_Quantity__c,
                       TotalAmtWithTax, Quantity,
                       Product2Id, Product2.Name, Product2.Membership__c, Product2.Renewal_Product__c, Product2.Product_Group__c,
                       Individual_Membership_Assignment__c
                FROM OrderItemSummary
                WHERE Id IN :itemIds
                  AND OrderSummaryId = :orderSummaryId
            ]);
            
            Decimal totalRefundAmount = 0;
            List<OrderItemSummary> updates = new List<OrderItemSummary>();
            List<Account_Membership__c> membershipsToCancel = new List<Account_Membership__c>();
            List<Practice_Level_Membership_Assignment__c> plmasToCancel = new List<Practice_Level_Membership_Assignment__c>();
            List<Account> accsToUpdate = new List<Account>();
            
            for (ItemRefundWrapper ir : itemRefunds) {
                if (String.isBlank(ir.itemId)) continue;
                Id oisId;
                try { oisId = (Id) ir.itemId; } catch (Exception e) { continue; }
                if (!rows.containsKey(oisId)) continue;
                
                OrderItemSummary ois = rows.get(oisId);
                
                // Skip $0/negative and already fully-refunded lines
                if (ois.TotalAmtWithTax == null || ois.TotalAmtWithTax <= 0) continue;
                
                Decimal alreadyRefundedAmt = (ois.Refunded_Amount__c == null) ? 0 : ois.Refunded_Amount__c;
                Integer alreadyRefundedQty = (ois.Refund_Quantity__c == null) ? 0 : Integer.valueOf(ois.Refund_Quantity__c);
                Integer qtyOrdered        = (ois.Quantity == null) ? 0 : Integer.valueOf(ois.Quantity);
                
                Decimal monetaryRemaining = ois.TotalAmtWithTax - alreadyRefundedAmt;
                if (monetaryRemaining <= 0) continue;
                
                Decimal unitPrice = (qtyOrdered > 0) ? (ois.TotalAmtWithTax / qtyOrdered) : 0;
                Decimal refundThisItem = 0;
                
                String membershipId = (ois.Product2 == null) ? null : (String) ois.Product2.Membership__c;
                
                // Quantity refunds (take precedence)
                if (ir.qtyToRefund != null && ir.qtyToRefund > 0) {
                    Integer requestedQty = ir.qtyToRefund;
                    Integer qtyLeft = Math.max(0, qtyOrdered - alreadyRefundedQty);
                    if (requestedQty > qtyLeft) requestedQty = qtyLeft;
                    
                    Decimal requestedRefund = requestedQty * unitPrice;
                    Decimal allowedRefund = Math.min(requestedRefund, monetaryRemaining);
                    
                    if (allowedRefund > 0) {
                        Integer newQty = alreadyRefundedQty + requestedQty;
                        ois.Refund_Quantity__c = Decimal.valueOf(Math.min(qtyOrdered, newQty));
                        ois.Refunded_Amount__c = Math.min(ois.TotalAmtWithTax, alreadyRefundedAmt + allowedRefund);
                        refundThisItem += allowedRefund;
                        
                        String lineReason = (ois.Refund_Reason__c == null ? '' : ois.Refund_Reason__c + '\n') +
                            '[' + stamp + '] ' + refundReason;
                        ois.Refund_Reason__c = lineReason;
                        
                        // If this line is now fully refunded (amount AND qty)
                        if (ois.Refunded_Amount__c >= ois.TotalAmtWithTax &&
                        Integer.valueOf(ois.Refund_Quantity__c) >= qtyOrdered) {
                            
                            if (ois.Product2 != null && ois.Product2.Renewal_Product__c && ois.Product2.Product_Group__c != 'Practice Level Membership') {
                                // Renewal product → use ILMA lookup on the line
                                if (ois.Individual_Membership_Assignment__c == null) {
                                    throw new AuraHandledException('Renewal product line missing Individual Membership Assignment.');
                                }
                                Account_Membership__c ilma = [
                                    SELECT Id, Account_Id__c
                                    FROM Account_Membership__c
                                    WHERE Id = :ois.Individual_Membership_Assignment__c
                                    LIMIT 1
                                ];
                                ilma.Status__c = 'Voided';
                                membershipsToCancel.add(ilma);
                                if (ilma.Account_Id__c != null) accsToUpdate.add(new Account(Id = ilma.Account_Id__c));
                                
                            } else if (membershipId != null) {
                                // Normal product → cancel ILMAs/PLMAs by Membership__c
                                List<Account_Membership__c> ilmas = [
                                    SELECT Id, Status__c, Account_Id__c, Account_Assignment_Date__c
                                    FROM Account_Membership__c
                                    WHERE Order_Summary__c = :orderSummaryId
                                      AND Membership__c     = :membershipId
                                      AND Status__c        != 'Voided'
                                    ORDER BY Account_Id__c NULLS FIRST, Account_Assignment_Date__c DESC
                                ];
                                for (Account_Membership__c ilma2 : ilmas) {
                                    ilma2.Status__c = 'Voided';
                                    if (ilma2.Account_Id__c != null) accsToUpdate.add(new Account(Id = ilma2.Account_Id__c));
                                }
                                membershipsToCancel.addAll(ilmas);
                                
                                List<Practice_Level_Membership_Assignment__c> plmas = [
                                    SELECT Id, Status__c
                                    FROM Practice_Level_Membership_Assignment__c
                                    WHERE Order__c      = :orderSummaryId
                                      AND Membership__c = :membershipId
                                      AND Status__c    != 'Voided'
                                ];
                                for (Practice_Level_Membership_Assignment__c pl : plmas) pl.Status__c = 'Voided';
                                plmasToCancel.addAll(plmas);
                            }
                        }
                    }
                    
                    // Partial refunds (only if qty refund not used)
                } else if (ir.partialAmount != null && ir.partialAmount > 0) {
                    Decimal allowedPartial = Math.min(ir.partialAmount, monetaryRemaining);
                    if (allowedPartial > 0) {
                        ois.Refunded_Amount__c = Math.min(ois.TotalAmtWithTax, alreadyRefundedAmt + allowedPartial);
                        refundThisItem += allowedPartial;
                        
                        String lineReason = (ois.Refund_Reason__c == null ? '' : ois.Refund_Reason__c + '\n') +
                            '[' + stamp + '] ' + refundReason;
                        ois.Refund_Reason__c = lineReason;
                    }
                }
                
                if (refundThisItem > 0) {
                    totalRefundAmount += refundThisItem;
                    updates.add(ois);
                }
            }
            
            if (totalRefundAmount <= 0) {
                throw new AuraHandledException('No refund amount to process.');
            }
            
            // Stripe refund
            Integer cents = (totalRefundAmount.setScale(2) * 100).intValue();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.stripe.com/v1/refunds');
            req.setHeader('Authorization', 'Bearer ' + Label.Stripe_Secret_Key);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            String body = 'payment_intent=' + EncodingUtil.urlEncode(os.Payment_Intent__c, 'UTF-8')
                + '&amount=' + String.valueOf(cents)
                + '&reason=requested_by_customer';
            req.setBody(body);
            
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                throw new AuraHandledException('Stripe refund failed: ' + res.getBody());
            }
            
            // --- Persist line and membership changes BEFORE deciding status ---
            if (!updates.isEmpty()) update updates;
            if (!membershipsToCancel.isEmpty()) update membershipsToCancel;
            if (!plmasToCancel.isEmpty()) update plmasToCancel;
            if (!accsToUpdate.isEmpty()) {
                for (Account acc : accsToUpdate) {
                    B2BBuyerGroupAssignemntController.handleBuyerGroupsForAccount(acc);
                }
            }
            
            // Re-query order to get fresh rollups
            os = [
                SELECT Id, Refund_Reason__c, Status,
                       Total_Refunded_Amount__c, Total_Amount_After_Refund__c
                FROM OrderSummary
                WHERE Id = :orderSummaryId
                LIMIT 1
            ];
            
            // Decide status from order-level totals
            Boolean anyRefunded   = (os.Total_Refunded_Amount__c != null && os.Total_Refunded_Amount__c > 0);
            Boolean fullyRefunded = (os.Total_Amount_After_Refund__c != null && os.Total_Amount_After_Refund__c == 0);
            
            if (fullyRefunded) {
                os.Status = 'Refunded';
            } else if (anyRefunded) {
                os.Status = 'Partially Refunded';
            }
            
            // Append order-level reason and save
            String orderReason = (os.Refund_Reason__c == null ? '' : os.Refund_Reason__c + '\n')
                + '[' + stamp + '] ' + refundReason + ' ($' + String.valueOf(totalRefundAmount.setScale(2)) + ')';
            os.Refund_Reason__c = orderReason;
            update os;
            
            return res.getBody();
            
        } catch (Exception e) {
            // Always write a rich log (use Automated Process user trace flag to capture)
            System.debug(LoggingLevel.ERROR,
            'Refund failed: type=' + e.getTypeName() +
                ' line=' + e.getLineNumber() +
                ' msg=' + e.getMessage() +
                '\nstack=\n' + e.getStackTraceString()
                );
            
            // In tests (including change-set validations), surface the original error
            if (Test.isRunningTest()) {
                throw e;  // lets the deployment UI show the exact Query/DML/Null pointer message
            }
            
            // In runtime (Experience Cloud), keep a clean, user-safe message
            throw new AuraHandledException('Refund failed. Please contact support with timestamp ' +
                String.valueOf(DateTime.now().getTime()) + '.');
        }
    }
    
    // Enriches modal data with ILMA Account Name/Id + renewal flag
    @AuraEnabled(cacheable=true)
    public static List<OrderItemWrapper> getOrderItems(Id orderSummaryId) {
        List<OrderItemSummary> items = [
            SELECT Id, Name, TotalAmtWithTax, Refunded_Amount__c, Quantity, Refund_Quantity__c,
                   Product2.Name, Product2.Renewal_Product__c,
                   Individual_Membership_Assignment__c
            FROM OrderItemSummary
            WHERE OrderSummaryId = :orderSummaryId
        ];
        
        // Collect ILMAs from lines
        Set<Id> ilmaIds = new Set<Id>();
        for (OrderItemSummary i : items) {
            if (i.Individual_Membership_Assignment__c != null) {
                ilmaIds.add(i.Individual_Membership_Assignment__c);
            }
        }
        
        // ILMA -> Account
        Map<Id, Account_Membership__c> ilmaById = ilmaIds.isEmpty()
            ? new Map<Id, Account_Membership__c>()
            : new Map<Id, Account_Membership__c>([
                SELECT Id, Account_Id__c
                FROM Account_Membership__c
                WHERE Id IN :ilmaIds
            ]);
        
        // Account Ids -> Name
        Set<Id> accIds = new Set<Id>();
        for (Account_Membership__c am : ilmaById.values()) {
            if (am.Account_Id__c != null) accIds.add(am.Account_Id__c);
        }
        Map<Id, Account> accById = accIds.isEmpty()
            ? new Map<Id, Account>()
            : new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN :accIds]);
        
        // Build wrappers with extras
        List<OrderItemWrapper> out = new List<OrderItemWrapper>();
        for (OrderItemSummary i : items) {
            OrderItemWrapper w = new OrderItemWrapper(i);
            w.IsRenewalProduct = (i.Product2 != null && i.Product2.Renewal_Product__c);
            
            if (i.Individual_Membership_Assignment__c != null) {
                Account_Membership__c ilma = ilmaById.get(i.Individual_Membership_Assignment__c);
                if (ilma != null && ilma.Account_Id__c != null) {
                    w.IlmaAccountId = String.valueOf(ilma.Account_Id__c);
                    Account a = accById.get(ilma.Account_Id__c);
                    if (a != null) w.IlmaAccountName = a.Name;
                }
            }
            out.add(w);
        }
        return out;
    }
}