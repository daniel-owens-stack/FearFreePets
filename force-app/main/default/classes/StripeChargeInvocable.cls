public without sharing class StripeChargeInvocable {
    public class Request {
        @InvocableVariable(label='Stripe payment method Id' required=true)
        public String paymentMethod;
        @InvocableVariable(label='Amount' required=true)
        public Decimal amount;
        @InvocableVariable(label='Stripe customer Id' required=true)
        public String customerId;
    }

    public class Result {
        @InvocableVariable(label='Status')
        public String status;
        //@InvocableVariable(label='Status code')
        //public String statusCode;
        @InvocableVariable(label='Stripe transaction id')
        public String transactionId;
        @InvocableVariable(label='Is success?')
        public Boolean isSuccess;
        @InvocableVariable(label='Error message')
        public String errorMessage;
    }

    @InvocableMethod(callout=true label='Stripe Charge')
    public static List<Result> charge(List<Request> requests) {
        Request req = requests[0];
        List<Result> results = new List<Result>();
        Result res = new Result();
        try {
            B2BStripeWrapper.PaymentIntent payment = B2BStripeService.createPaymentIntent(req.customerId, req.paymentMethod, Integer.valueOf(req.amount*100));
            res.status = payment.status;
            res.isSuccess = true;
            res.transactionId = payment.Id;
            results.add(res);
        } catch (Exception e) {
            res.isSuccess = false;
            res.errorMessage = e.getMessage();
            results.add(res);
        }
        return results;
    }
}