public class B2BPracticeLevelRenewalsWrapper {
    public class BusinessAccount {
        public String account_id;
        public String name;
        public String billing_email;
        public Boolean billing_email_verified;
        public Address billing_address;
        public Address shipping_address;
        public String payment_terms;
   }

   public class PracticeLevelMembershipAssignment {
     public String id;
     public String business_account;
     public string membership_id;
     public Decimal renewal_dvm_count;
     public String renewal_product_id;
     public Decimal renewal_price;
   }

   public class Order {
     public String id;
     public String order_delivery_group_id;
   }
}