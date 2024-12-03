public class B2BGetProductPriceInvokable {
    public class Input {
        @InvocableVariable(required=true)
        public String accountId;
        
        @InvocableVariable(required=true)
        public String productId;
    }
    
    public class Output {
        @InvocableVariable
        public Decimal productPrice;
    }
    
    @InvocableMethod(label='Get Product Price' description='Fetches product price by Account Id and Product Id')
    public static List<Output> getProductPriceByAccount(List<Input> inputs) {
        List<Output> results = new List<Output>();
        
        for (Input input : inputs) {
            Output output = new Output();
            try {
                output.productPrice = B2BUtils.getProductPriceByAccountId(input.accountId, input.productId);
            } catch (Exception e) {
                output.productPrice = null;
                System.debug('Error fetching product price: ' + e.getMessage());
            }
            results.add(output);
        }
        
        return results;
    }
}