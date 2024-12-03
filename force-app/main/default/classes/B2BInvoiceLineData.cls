public class B2BInvoiceLineData {

    @AuraEnabled
    public B2BInvoiceLineObject object_InvoiceLine {get;set;} // in json: object

    public B2BInvoiceLineData(JSONParser parser) {
        while (parser.nextToken() != System.JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                    if (text == 'object') {
                        object_InvoiceLine = new B2BInvoiceLineObject(parser);
                    } else {
                        System.debug(LoggingLevel.WARN, 'Data consuming unrecognized property: '+text);
                        B2BInvoiceLine.consumeObject(parser);
                    }
                }
            }
        }
    }
}