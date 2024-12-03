public class B2BInvoiceObject {

    public class Issuer {
		public String type {get;set;} 

		public Issuer(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'type') {
							type = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Issuer consuming unrecognized property: '+text);
							B2BInvoice.consumeObject(parser);
						}
					}
				}
			}
		}
	}
    
    @AuraEnabled
    public Date webhooks_delivered_at {get;set;}
    @AuraEnabled 
    public String transfer_data {get;set;}
    @AuraEnabled
    public Decimal total_excluding_tax {get;set;} 
    @AuraEnabled
    public Decimal total {get;set;} 
    @AuraEnabled
    public String test_clock {get;set;} 
    @AuraEnabled
    public Decimal tax {get;set;} 
    @AuraEnabled
    public Decimal subtotal_excluding_tax {get;set;} 
    @AuraEnabled
    public Decimal subtotal {get;set;} 
    @AuraEnabled
    public String subscription {get;set;} 
    @AuraEnabled
    public String status {get;set;} 
    @AuraEnabled
    public String statement_descriptor {get;set;} 
    @AuraEnabled
    public Integer starting_balance {get;set;} 
    @AuraEnabled
    public String shipping_details {get;set;} 
    @AuraEnabled
    public String shipping_cost {get;set;} 
    @AuraEnabled
    public String rendering_options {get;set;} 
    @AuraEnabled
    public String receipt_number {get;set;} 
    @AuraEnabled
    public String quote {get;set;} 
    @AuraEnabled
    public Integer pre_payment_credit_notes_amount {get;set;} 
    @AuraEnabled
    public Integer post_payment_credit_notes_amount {get;set;} 
    @AuraEnabled
    public Date period_start {get;set;} 
    @AuraEnabled
    public Date period_end {get;set;} 
    @AuraEnabled
    public String payment_intent {get;set;} 
    @AuraEnabled
    public Boolean paid_out_of_band {get;set;} 
    @AuraEnabled
    public Boolean paid {get;set;} 
    @AuraEnabled
    public String on_behalf_of {get;set;} 
    @AuraEnabled
    public String number_Z {get;set;} // in json: number
    @AuraEnabled
    public String next_payment_attempt {get;set;}
    @AuraEnabled
    public B2BInvoiceMetaData metadata {get;set;}
    @AuraEnabled
    public Boolean livemode {get;set;}
    @AuraEnabled
    public String latest_revision {get;set;} 
    @AuraEnabled
    public String last_finalization_error {get;set;} 
    @AuraEnabled
    public Issuer issuer {get;set;} 
    @AuraEnabled
    public String invoice_pdf {get;set;} 
    @AuraEnabled
    public String hosted_invoice_url {get;set;} 
    @AuraEnabled
    public String from_invoice {get;set;} 
    @AuraEnabled
    public String footer {get;set;} 
    @AuraEnabled
    public Decimal ending_balance {get;set;} 
    @AuraEnabled
    public Date effective_at {get;set;} 
    @AuraEnabled
    public Date due_date {get;set;}
    @AuraEnabled
    public Decimal discount {get;set;} 
    @AuraEnabled
    public String description{get;set;}
    @AuraEnabled
    public String default_source {get;set;} 
    @AuraEnabled
    public String default_payment_method {get;set;}
    @AuraEnabled
    public String customer_tax_exempt {get;set;} 
    @AuraEnabled
    public String customer_shipping {get;set;} 
    @AuraEnabled
    public String customer_phone {get;set;} 
    @AuraEnabled
    public String customer_name {get;set;} 
    @AuraEnabled
    public String customer_email {get;set;} 
    @AuraEnabled
    public String customer_address {get;set;} 
    @AuraEnabled
    public String customer {get;set;} 
    @AuraEnabled
    public String custom_fields {get;set;} 
    @AuraEnabled
    public String currency_Z {get;set;} // in json: currency
    @AuraEnabled
    public Date created {get;set;} 
    @AuraEnabled
    public String collection_method {get;set;} 
    @AuraEnabled
    public String charge {get;set;} 
    @AuraEnabled
    public String billing_reason {get;set;} 
    @AuraEnabled
    public Date automatically_finalizes_at {get;set;}
    @AuraEnabled
    public Boolean auto_advance {get;set;} 
    @AuraEnabled
    public Boolean attempted {get;set;} 
    @AuraEnabled
    public Integer attempt_count {get;set;} 
    @AuraEnabled
    public Decimal application_fee_amount {get;set;} 
    @AuraEnabled
    public String application {get;set;} 
    @AuraEnabled
    public Decimal amount_shipping {get;set;} 
    @AuraEnabled
    public Decimal amount_remaining {get;set;} 
    @AuraEnabled
    public Decimal amount_paid {get;set;} 
    @AuraEnabled
    public Decimal amount_due {get;set;} 
    @AuraEnabled
    public String account_tax_ids {get;set;} 
    @AuraEnabled
    public String account_name {get;set;} 
    @AuraEnabled
    public String account_country {get;set;} 
    @AuraEnabled
    public String object_Z {get;set;} // in json: object
    @AuraEnabled
    public String stripeInvoiceId {get;set;}

    public B2BInvoiceObject(JSONParser parser) {
        while (parser.nextToken() != System.JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                    if (text == 'webhooks_delivered_at') {
                        webhooks_delivered_at = convertUnixTimestamp(parser.getIntegerValue());
                    } else if (text == 'transfer_data') {
                        transfer_data = parser.getText();
                    } else if (text == 'total_excluding_tax') {
                        total_excluding_tax = 0.01*parser.getDecimalValue();
                    } else if (text == 'total') {
                        total = 0.01*parser.getDecimalValue();
                    } else if (text == 'test_clock') {
                        test_clock = parser.getText();
                    } else if (text == 'tax') {
                        tax = 0.01*parser.getDecimalValue();
                    } else if (text == 'subtotal_excluding_tax') {
                        subtotal_excluding_tax = 0.01*parser.getDecimalValue();
                    } else if (text == 'subtotal') {
                        subtotal = 0.01*parser.getDecimalValue();
                    } else if (text == 'subscription') {
                        subscription = parser.getText();
                    } else if (text == 'status') {
                        status = parser.getText();
                    } else if (text == 'statement_descriptor') {
                        statement_descriptor = parser.getText();
                    } else if (text == 'starting_balance') {
                        starting_balance = parser.getIntegerValue();
                    } else if (text == 'shipping_details') {
                        shipping_details = parser.getText();
                    } else if (text == 'shipping_cost') {
                        shipping_cost = parser.getText();
                    } else if (text == 'rendering_options') {
                        rendering_options = parser.getText();
                    } else if (text == 'receipt_number') {
                        receipt_number = parser.getText();
                    } else if (text == 'quote') {
                        quote = parser.getText();
                    } else if (text == 'pre_payment_credit_notes_amount') {
                        pre_payment_credit_notes_amount = parser.getIntegerValue();
                    } else if (text == 'post_payment_credit_notes_amount') {
                        post_payment_credit_notes_amount = parser.getIntegerValue();
                    } else if (text == 'period_start') {
                        period_start = convertUnixTimestamp(parser.getIntegerValue());
                    } else if (text == 'period_end') {
                        period_end = convertUnixTimestamp(parser.getIntegerValue());
                    } else if (text == 'payment_intent') {
                        payment_intent = parser.getText();
                    } else if (text == 'paid_out_of_band') {
                        paid_out_of_band = parser.getBooleanValue();
                    } else if (text == 'paid') {
                        paid = parser.getBooleanValue();
                    } else if (text == 'on_behalf_of') {
                        on_behalf_of = parser.getText();
                    } else if (text == 'number') {
                        number_Z = parser.getText();
                    } else if (text == 'next_payment_attempt') {
                        next_payment_attempt = parser.getText();
                    } else if (text == 'metadata') {
                        metadata = new B2BInvoiceMetaData(parser);
                    } else if (text == 'livemode') {
                        livemode = parser.getBooleanValue();
                    } else if (text == 'latest_revision') {
                        latest_revision = parser.getText();
                    } else if (text == 'last_finalization_error') {
                        last_finalization_error = parser.getText();
                    } else if (text == 'issuer') {
                        issuer = new Issuer(parser);
                    } else if (text == 'invoice_pdf') {
                        invoice_pdf = parser.getText();
                    } else if (text == 'hosted_invoice_url') {
                        hosted_invoice_url = parser.getText();
                    } else if (text == 'from_invoice') {
                        from_invoice = parser.getText();
                    } else if (text == 'footer') {
                        footer = parser.getText();
                    } else if (text == 'ending_balance') {
                        ending_balance = 0.01*parser.getDecimalValue();
                    } else if (text == 'effective_at') {
                        effective_at = convertUnixTimestamp(parser.getIntegerValue());
                    } else if (text == 'due_date') {
                        due_date = convertUnixTimestamp(parser.getIntegerValue());
                    } else if (text == 'discount') {
                        discount = 0.01*parser.getDecimalValue();
                    } else if (text == 'description') {
                        description = parser.getText();
                    } else if (text == 'default_source') {
                        default_source = parser.getText();
                    } else if (text == 'default_payment_method') {
                        default_payment_method = parser.getText();
                    } else if (text == 'customer_tax_exempt') {
                        customer_tax_exempt = parser.getText();
                    } else if (text == 'customer_shipping') {
                        customer_shipping = parser.getText();
                    } else if (text == 'customer_phone') {
                        customer_phone = parser.getText();
                    } else if (text == 'customer_name') {
                        customer_name = parser.getText();
                    } else if (text == 'customer_email') {
                        customer_email = parser.getText();
                    } else if (text == 'customer_address') {
                        customer_address = parser.getText();
                    } else if (text == 'customer') {
                        customer = parser.getText();
                    } else if (text == 'custom_fields') {
                        custom_fields = parser.getText();
                    } else if (text == 'currency') {
                        currency_Z = parser.getText();
                    } else if (text == 'created') {
                        created = convertUnixTimestamp(parser.getIntegerValue());
                    } else if (text == 'collection_method') {
                        collection_method = parser.getText();
                    } else if (text == 'charge') {
                        charge = parser.getText();
                    } else if (text == 'billing_reason') {
                        billing_reason = parser.getText();
                    } else if (text == 'automatically_finalizes_at') {
                        automatically_finalizes_at = convertUnixTimestamp(parser.getIntegerValue());
                    } else if (text == 'auto_advance') {
                        auto_advance = parser.getBooleanValue();
                    } else if (text == 'attempted') {
                        attempted = parser.getBooleanValue();
                    } else if (text == 'attempt_count') {
                        attempt_count = parser.getIntegerValue();
                    } else if (text == 'application_fee_amount') {
                        application_fee_amount = 0.01*parser.getDecimalValue();
                    } else if (text == 'application') {
                        application = parser.getText();
                    } else if (text == 'amount_shipping') {
                        amount_shipping = 0.01*parser.getDecimalValue();
                    } else if (text == 'amount_remaining') {
                        amount_remaining = 0.01*parser.getDecimalValue();
                    } else if (text == 'amount_paid') {
                        amount_paid = 0.01*parser.getDecimalValue();
                    } else if (text == 'amount_due') {
                        amount_due = 0.01*parser.getDecimalValue();
                    } else if (text == 'account_tax_ids') {
                        account_tax_ids =parser.getText();
                    } else if (text == 'account_name') {
                        account_name = parser.getText();
                    } else if (text == 'account_country') {
                        account_country = parser.getText();
                    } else if (text == 'object') {
                        object_Z = parser.getText();
                    } else if (text == 'id') {
                        stripeInvoiceId = parser.getText();
                    } else {
                        System.debug(LoggingLevel.WARN, 'B2BInvoiceObject consuming unrecognized property: '+text);
                        B2BInvoice.consumeObject(parser);
                    }
                }
            }
        }
    }

    public Date convertUnixTimestamp(Integer timestampInSeconds) {
        DateTime convertedDateTime = DateTime.newInstance(1970, 1, 1, 0, 0, 0).addSeconds(timestampInSeconds);
		TimeZone tz = TimeZone.getTimeZone('America/Los_Angeles');
		DateTime convertedDate_tz = convertedDateTime.addSeconds(tz.getOffset(convertedDateTime)/1000);

        Date convertedDate = convertedDateTime.date();
        return convertedDate;
	}
}