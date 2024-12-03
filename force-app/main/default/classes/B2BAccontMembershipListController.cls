public without sharing class B2BAccontMembershipListController {

    @AuraEnabled
    public static List<List<AccountMembershipWrapper>> getAccountMemberships(String accountId) {
        List<Account_Membership__c> accMemList = [SELECT Id, Name, Membership__c, Membership__r.Name, Account_Id__r.Name, Parent_Id__c, Account_Id__c, Account_Assignment_Date__c, Start_Date__c, Expiration_Date__c 
                                                  FROM Account_Membership__c 
                                                  WHERE Parent_Id__c =:accountId
                                                  ORDER BY Membership__c,  Account_Id__r.Name NULLS FIRST
                                                 ];
                                                  
        List<AccountMembershipWrapper> wrapperList = new List<AccountMembershipWrapper>();

        for(Account_Membership__c am : accMemList) {
            wrapperList.add(new AccountMembershipWrapper(am.Account_Id__r.Name, am.Membership__r.Name, am.Parent_Id__c, am.Membership__c, am.Account_Id__c, am.Id, am.Account_Assignment_Date__c, am.Start_Date__c, am.Expiration_Date__c));
        }
        System.debug('Wrapper List : ' + wrapperList);

        Map<String, Map<String, List<AccountMembershipWrapper>>> groupedMap = new Map<String, Map<String, List<AccountMembershipWrapper>>>();
    
        // Grouping by parentId and membershipId
        for (AccountMembershipWrapper wrapper : wrapperList) {
            if (!groupedMap.containsKey(wrapper.parentId)) {
                groupedMap.put(wrapper.parentId, new Map<String, List<AccountMembershipWrapper>>());
            }

             if(!groupedMap.get(wrapper.parentId).containsKey(wrapper.membershipId)){
                groupedMap.get(wrapper.parentId).put(wrapper.membershipId, new List<AccountMembershipWrapper>());
            }
            groupedMap.get(wrapper.parentId).get(wrapper.membershipId).add(wrapper);
        }
        System.debug('Grouped Map : ' + groupedMap);

        // Constructing the result list
        List<List<AccountMembershipWrapper>> resultList = new List<List<AccountMembershipWrapper>>();
        for (String parentId : groupedMap.keySet()) {
            List<AccountMembershipWrapper> innerList = new List<AccountMembershipWrapper>();
            System.debug('MembershipId List : ' + groupedMap.get(parentId).keySet());
            for (String membershipId : groupedMap.get(parentId).keySet()) {
                System.debug('membershipId : ' + membershipId);
                for(AccountMembershipWrapper membership : groupedMap.get(parentId).get(membershipId)) {
                    System.debug('Membership record : ' + membership);
                    if(membership.accountName == null) {
                        membership.accountName = 'Unassigned';
                    }
                    innerList.add(membership);
                }
            }
            resultList.add(innerList);
        }

        System.debug('resultList : '+ resultList);
        return resultList;
    }

    public class AccountMembershipWrapper {
        @AuraEnabled
        public String accountName { get; set; }

         @AuraEnabled
        public String membershipName { get; set; }
        // @AuraEnabled
        // public Date startDate { get; set; }

        // @AuraEnabled
        // public Date endDate { get; set; }

        // @AuraEnabled
        // public Decimal percentComplete { get; set; }

        public Id parentId { get; set; }
        public Id membershipId { get; set; }
        public Id accId { get; set; }

        @AuraEnabled
        public String accountLink { get; set; }

        @AuraEnabled
        public Id Id { get; set; }

        @AuraEnabled
        public Date accountAssignmentDate { get; set; }
        @AuraEnabled
        public Date purchaseDate { get; set; }
        @AuraEnabled
        public Date expirationDate{ get; set; }


        public AccountMembershipWrapper(String accountName, String membershipName, Id parentId, Id membershipId, Id accId, Id Id, Date accountAssignmentDate, Date purchaseDate, Date expirationDate) {
            this.accountName = accountName;
            this.membershipName = membershipName;
            this.parentId = parentId;
            this.membershipId = membershipId;
            this.accId = accId;
            this.accountLink = '/' + Id;
            this.Id = Id;
            this.accountAssignmentDate = accountAssignmentDate;
            this.purchaseDate = purchaseDate;
            this.expirationDate = expirationDate;
        }
    }
}