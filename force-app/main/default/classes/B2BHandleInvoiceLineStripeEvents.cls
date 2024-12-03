global class B2BHandleInvoiceLineStripeEvents {

    @InvocableMethod(label='Deserialize To B2B InvoiceLine')
    public static List<Results> deserializeInvoiceLine(List<String> requestBodies) {
        List<Results> resultsList = new List<Results>();
        
        for(String requestBody : requestBodies) {
            Results results = new Results();

            B2BInvoiceLine iL = B2BInvoiceLine.parseInvoiceLine(requestBody);
            results.invoiceLine = iL;

            resultsList.add(results);
        }
        
        return resultsList;
    }

    global class Results {

        @InvocableVariable
        global B2BInvoiceLine invoiceLine;
    }
}