public class B2BInvoiceLineObject {

    @AuraEnabled
    public String unit_amount_decimal {get;set;}
    @AuraEnabled 
    public Decimal unit_amount {get;set;} 
    @AuraEnabled
    public String test_clock {get;set;}  
    @AuraEnabled
    public String subscription {get;set;} 
    @AuraEnabled
    public Integer quantity {get;set;} 
    @AuraEnabled
    public Boolean proration {get;set;} 
    @AuraEnabled
    public String plan {get;set;}  
    @AuraEnabled
    public Boolean livemode {get;set;} 
    @AuraEnabled
    public String stripeInvoiceId {get;set;} 
    @AuraEnabled
    public Boolean discountable {get;set;} 
    @AuraEnabled
    public String description {get;set;} 
    @AuraEnabled
    public Date date_Z {get;set;} // in json: date
    @AuraEnabled
    public String customer {get;set;} 
    @AuraEnabled
    public String currency_Z {get;set;} // in json: currency
    @AuraEnabled
    public Decimal amount {get;set;} 
    @AuraEnabled
    public String object_Z {get;set;} // in json: object
    @AuraEnabled
    public String stripeInvoiceLineId {get;set;} 

    public B2BInvoiceLineObject(JSONParser parser) {
        while (parser.nextToken() != System.JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                    if (text == 'unit_amount_decimal') {
                        unit_amount_decimal = parser.getText();
                    } else if (text == 'unit_amount') {
                        unit_amount = 0.01*parser.getDecimalValue();
                    } else if (text == 'test_clock') {
                        test_clock = parser.getText();
                    } else if (text == 'subscription') {
                        subscription = parser.getText();
                    } else if (text == 'quantity') {
                        quantity = parser.getIntegerValue();
                    } else if (text == 'proration') {
                        proration = parser.getBooleanValue();
                    } else if (text == 'plan') {
                        plan = parser.getText();
                    } else if (text == 'livemode') {
                        livemode = parser.getBooleanValue();
                    } else if (text == 'invoice') {
                        stripeInvoiceId = parser.getText();
                    } else if (text == 'discountable') {
                        discountable = parser.getBooleanValue();
                    } else if (text == 'description') {
                        description = parser.getText();
                    } else if (text == 'date') {
                        date_Z = convertUnixTimestamp(parser.getIntegerValue());
                    } else if (text == 'customer') {
                        customer = parser.getText();
                    } else if (text == 'currency') {
                        currency_Z = parser.getText();
                    } else if (text == 'amount') {
                        amount = 0.01*parser.getDecimalValue();
                    } else if (text == 'object') {
                        object_Z = parser.getText();
                    } else if (text == 'id') {
                        stripeInvoiceLineId = parser.getText();
                    } else {
                        System.debug(LoggingLevel.WARN, 'Object_Z consuming unrecognized property: '+text);
                        B2BInvoiceLine.consumeObject(parser);
                    }
                }
            }
        }
    }

    public Date convertUnixTimestamp(Integer timestampInSeconds) {
		
        DateTime convertedDateTime = DateTime.newInstance(1970, 1, 1, 0, 0, 0).addSeconds(timestampInSeconds);
		TimeZone tz = TimeZone.getTimeZone('America/Los_Angeles');
		DateTime convertedDate_tz = convertedDateTime.addSeconds(tz.getOffset(convertedDateTime)/1000);

        Date convertedDate = convertedDate_tz.date();
        return convertedDate;
	}
}