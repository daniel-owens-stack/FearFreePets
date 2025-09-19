public with sharing class B2BProvisioningWorkerGroup implements Queueable {

    private List<Id> accountIds;

    public B2BProvisioningWorkerGroup(List<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public void execute(QueueableContext context) {
        Id buyerGroupId = [SELECT Id FROM BuyerGroup WHERE Name = 'Standard Buyer Group' LIMIT 1].Id;

        List<Account> accs = [SELECT Id, Name FROM Account WHERE Id IN :accountIds];
        List<BuyerAccount> buyerAccounts = new List<BuyerAccount>();
        List<BuyerGroupMember> bgmList = new List<BuyerGroupMember>();

        for (Account acc : accs) {
            buyerAccounts.add(new BuyerAccount(
                BuyerId = acc.Id,
                Name = acc.Name,
                BuyerStatus = 'Active'
            ));
            bgmList.add(new BuyerGroupMember(
                BuyerGroupId = buyerGroupId,
                BuyerId = acc.Id
            ));
        }

        if (!bgmList.isEmpty()) insert bgmList;
    }
}