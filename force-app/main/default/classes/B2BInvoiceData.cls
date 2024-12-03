public class B2BInvoiceData {
    @AuraEnabled
    public B2BInvoiceObject object_Invoice {get;set;} // in json: object

		public B2BInvoiceData(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'object') {
							object_Invoice = new B2BInvoiceObject(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'B2BInvoiceData consuming unrecognized property: '+text);
							B2BInvoice.consumeObject(parser);
						}
					}
				}
			}
		}
}