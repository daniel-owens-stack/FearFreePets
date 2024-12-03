global class B2BHandleInvoiceStripeEvents {

    @InvocableMethod(label='Deserialize To B2B Invoice')
    public static List<Results> deserializeInvoice(List<String> requestBodies) {
        List<Results> resultsList = new List<Results>();
        
        for(String requestBody : requestBodies) {
            Results results = new Results();

            B2BInvoice i = B2BInvoice.parseInvoice(requestBody);
            results.invoice = i;

            resultsList.add(results);
        }
        
        return resultsList;
    }

    global class Results {

        @InvocableVariable
        global B2BInvoice invoice;
    }
}