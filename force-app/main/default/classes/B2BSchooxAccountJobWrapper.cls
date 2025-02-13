public class B2BSchooxAccountJobWrapper {
    
    @AuraEnabled @InvocableVariable(label='Account Memberships')
    public List<Account_Membership__c> accountMemberships;

    @AuraEnabled @InvocableVariable(label='OrderSummary AccountId')
    public String orderSummary_AccountId;

    @AuraEnabled @InvocableVariable(label='Permanent Membership Job Id')
    public List<Integer> permanentMembershipJobIds;
}