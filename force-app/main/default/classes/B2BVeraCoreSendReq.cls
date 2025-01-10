public without sharing class B2BVeraCoreSendReq {

    @future(callout = true)
    public static void sendOrderReq(List<Id> orderItemSummaryIds){

        String endpoint = 'callout:VeraCore';
        // String endpoint = 'https://fulfillment.allpoinTsatl.com/pmomsdev/wstest.aspx'; 
        // String username = 'ffp_salesforce'; //named cred
        // String password = 'dut5guz*yav4xgk3PVY';

        List<OrderItemSummary> ois = [SELECT Id, Quantity, UnitPrice, OrderSummaryId, Veracore_Callout_Response__c FROM OrderItemSummary WHERE Id IN :orderItemSummaryIds];
        List<OrderSummary> os;
        if(ois.size() > 0) {
            os = [SELECT Id, OwnerId, Veracore_Order_Id__c FROM OrderSummary WHERE Id =:ois[0].OrderSummaryId];
        }

        if(os.size() > 0) {
            String veraCore_OrderId = os[0].Veracore_Order_Id__c;

            List<OrderDeliveryGroupSummary> odgs= [SELECT Id, DeliverToStreet, DeliverToCity, DeliverToState, DeliverToPostalCode, DeliverToCountry FROM OrderDeliveryGroupSummary WHERE OrderSummaryId =:os[0].Id LIMIT 1];
            String address1= odgs[0].DeliverToStreet;
            String address2='';
            String address3= '';
            String city= odgs[0].DeliverToCity;
            String state= odgs[0].DeliverToState;
            String postalCode= odgs[0].DeliverToPostalCode;
            String country= odgs[0].DeliverToCountry;

            List<User> user = [SELECT Id, FirstName, MiddleName, LastName, Suffix, Title, Phone, Fax, Email
                               FROM User 
                               WHERE Id =:os[0].OwnerId];
            String prefix= '';
            String firstName= user[0].FirstName;
            String middleInitial= user[0].MiddleName;
            String lastName= user[0].LastName;
            String suffix= user[0].Suffix;
            String title= user[0].Title;
            String phone= user[0].Phone;
            String fax= user[0].Fax;
            String email= user[0].Email;

            List<OrderItemSummary> responsesToUpdate = new List<OrderItemSummary>();

            for(OrderItemSummary item : ois) {
                Decimal quantity = item.Quantity;
                Decimal unitPrice = item.UnitPrice;
                HttpResponse response = B2BSOAPApiCall.makeSOAPCall(endpoint, prefix, firstName, middleInitial, lastName, suffix, title, address1, address2, address3, city, state, postalCode, country, phone, fax, email, veraCore_OrderId, quantity, unitPrice);
                System.debug('##B2BVeraCoreSendReq - Response: ' + response);

                item.Veracore_Callout_Response__c = 'Status=' + response.getStatus() + ', StatusCode=' + response.getStatusCode();
                responsesToUpdate.add(item);
            }

            if(!responsesToUpdate.isEmpty()){
                update responsesToUpdate;
            }
        }
    }
}