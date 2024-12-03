public class B2BInvoiceMetadata {

	@AuraEnabled
    public String salesforce_order_id {get;set;}

	public B2BInvoiceMetadata(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'salesforce_order_id') {
						salesforce_order_id = parser.getText();
					} else {
						System.debug(LoggingLevel.WARN, 'B2BInvoiceMetadata consuming unrecognized property: '+text);
						B2BInvoice.consumeObject(parser);
					}
				}
			}
		}
	}
}