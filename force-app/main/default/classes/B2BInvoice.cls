public class B2BInvoice {

	@AuraEnabled
    public String type {get;set;} 
	@AuraEnabled
    public Integer pending_webhooks {get;set;} 
	@AuraEnabled
	public Boolean livemode {get;set;} 
	@AuraEnabled
	public B2BInvoiceData data {get;set;} 
	@AuraEnabled
	public DateTime createdDate {get;set;} 
	@AuraEnabled
	public String api_version {get;set;} 
	@AuraEnabled
	public String object_Z {get;set;} // in json: object
	@AuraEnabled
	public String stripeEventId {get;set;} 

    public B2BInvoice(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'type') {
						type = parser.getText();
					} else if (text == 'pending_webhooks') {
						pending_webhooks = parser.getIntegerValue();
					} else if (text == 'livemode') {
						livemode = parser.getBooleanValue();
					} else if (text == 'data') {
						data = new B2BInvoiceData(parser);
					} else if (text == 'created') {
						createdDate = convertUnixTimestamp(parser.getIntegerValue());

					} else if (text == 'api_version') {
						api_version = parser.getText();
					} 
					else if (text == 'object') {
						object_Z = parser.getText();
					} else if (text == 'id') {
						stripeEventId = parser.getText();
					} else {
						System.debug(LoggingLevel.WARN, 'B2BInvoice consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}

	public static B2BInvoice parseInvoice(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new B2BInvoice(parser);
	}

    public static void consumeObject(System.JSONParser parser) {
		Integer depth = 0;
		do {
			System.JSONToken curr = parser.getCurrentToken();
			if (curr == System.JSONToken.START_OBJECT || 
				curr == System.JSONToken.START_ARRAY) {
				depth++;
			} else if (curr == System.JSONToken.END_OBJECT ||
				curr == System.JSONToken.END_ARRAY) {
				depth--;
			}
		} while (depth > 0 && parser.nextToken() != null);
	}

	
	public DateTime convertUnixTimestamp(Integer timestampInSeconds) {
		DateTime convertedDate = DateTime.newInstance(1970, 1, 1, 0, 0, 0).addSeconds(timestampInSeconds);
		TimeZone tz = TimeZone.getTimeZone('America/Los_Angeles');
		DateTime convertedDate_tz = convertedDate.addSeconds(tz.getOffset(convertedDate)/1000);
		
		return convertedDate_tz;
	}
}