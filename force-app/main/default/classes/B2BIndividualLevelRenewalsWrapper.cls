public class B2BIndividualLevelRenewalsWrapper {
    public class ParentAccount {
        public String account_id;
        public String name;
        public String billing_email;
        public Boolean billing_email_verified;
        public Address billing_address;
        public Address shipping_address;
        public String payment_terms;
   }

   public class IndividualLevelMembershipAssignment {
     public String id;
     public String parent_account;
     public string membership_id;
     public String renewal_product_id;
     public Decimal renewal_price;
     public Boolean invoice_exempt;
   }

   public class Order {
     public String id;
     public String order_delivery_group_id;
   }
}