public without sharing class B2BVeraCoreSendReq {

    @future(callout = true)
    public static void sendOrderReq(List<Id> orderItemSummaryIds){

        // String endpoint = 'https://fulfillment.allpointsatl.com/pmomsws/oms.asmx'; 
        // String username = 'ffp_salesforce';
        // String password = 'dut5guz*yav4xgk3PVY';

        List<OrderItemSummary> ois = [
            SELECT Id, Quantity, UnitPrice, OrderSummaryId, Product2.StockKeepingUnit, Product2.International_Product_SKU__c 
            FROM OrderItemSummary 
            WHERE Id IN :orderItemSummaryIds];
        
        List<OrderSummary> os;
        if(ois.size() > 0) {
            os = [SELECT Id, OwnerId, Veracore_Order_Id__c, Veracore_Callout_Response__c, OrderNumber, PoNumber FROM OrderSummary WHERE Id =:ois[0].OrderSummaryId];
        }

        if(os.size() > 0) {
            List<OrderDeliveryGroupSummary> odgs= [
                SELECT Id, DeliverToStreet, DeliverToCity, DeliverToState, DeliverToPostalCode, DeliverToCountry, DeliverToCountryCode 
                FROM OrderDeliveryGroupSummary 
                WHERE OrderSummaryId =:os[0].Id 
                LIMIT 1];

            List<User> user = [SELECT Id, FirstName, LastName, Phone, Email
                               FROM User 
                               WHERE Id =:os[0].OwnerId];

            Header header = new Header();
            header.veracoreOrderId = os[0].Veracore_Order_Id__c;
            header.orderSummaryNumber = os[0].OrderNumber;
            header.poNumber = os[0].PoNumber;

            OrderedBy orderedBy = new OrderedBy();
            orderedBy.firstName = user[0].FirstName;
            orderedBy.lastName = user[0].LastName;
            orderedBy.street = odgs[0].DeliverToStreet;
            orderedBy.city = odgs[0].DeliverToCity;
            orderedBy.state = odgs[0].DeliverToState;
            orderedBy.postalCode = odgs[0].DeliverToPostalCode;
            orderedBy.country = odgs[0].DeliverToCountry;
            orderedBy.countryCode = odgs[0].DeliverToCountryCode;
            orderedBy.phone = user[0].Phone;
            orderedBy.email = System.Label.B2B_Veracore_Order_Email;

            List<Offers> offers = new List<Offers>();

            for(OrderItemSummary item : ois) {
                Offers offer = new Offers();
                offer.offerId_SKU = item.Product2.StockKeepingUnit;
                offer.offerId_SKU_INTL = item.Product2.International_Product_SKU__c;
                offer.quantity = Integer.valueOf(item.Quantity);
                offer.unitPrice = item.UnitPrice;

                offers.add(offer);
            }

            HttpResponse response = B2BSOAPApiCall.sendRequestToVeraCore(header, orderedBy, offers);

            //Update response on Order Summary record
            os[0].Veracore_Callout_Response__c = 'Status=' + response.getStatus() + 
                                                 ', StatusCode=' + response.getStatusCode() + 
                                                 ', Body=' + response.getBody();
            
            update os[0];
        }
    }

    public class Header {
        public String veracoreOrderId;
        public String orderSummaryNumber;
        public String poNumber;
    }

    public class OrderedBy {
        public String firstName;
        public String lastName;
        public String street;
        public String city;
        public String state;
        public String postalCode;
        public String country;
        public String countryCode;
        public String phone;
        public String email;
    }

    public class Offers {
        public String offerId_SKU;
        public String offerId_SKU_INTL;
        public Integer quantity;
        public Decimal unitPrice;
    }
}