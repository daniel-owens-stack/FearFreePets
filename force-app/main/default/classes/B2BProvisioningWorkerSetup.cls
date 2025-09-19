public with sharing class B2BProvisioningWorkerSetup implements Queueable {

    private List<Id> accountIds;

    public B2BProvisioningWorkerSetup(List<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public void execute(QueueableContext context) {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Fear Free Community Member' LIMIT 1].Id;
        Id permSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Fear_Free_B2B_Store_Buyer' LIMIT 1].Id;

        List<Account> accs = [SELECT Id, Name, PersonEmail, PersonContactId FROM Account WHERE Id IN :accountIds];
        List<User> users = new List<User>();
        Map<Integer, Id> indexToAccountId = new Map<Integer, Id>();

        for (Integer i = 0; i < accs.size(); i++) {
            Account acc = accs[i];
            if (String.isBlank(acc.PersonEmail) || acc.PersonContactId == null) continue;

            User u = new User();
            u.Username = acc.PersonEmail.replace('@','.' + Datetime.now().getTime() + '@');
            u.Email = acc.PersonEmail;
            u.Alias = (acc.Name.length() >= 8 ? acc.Name.substring(0, 8) : acc.Name).rightPad(8, 'X');
            u.LastName = acc.Name;
            u.CommunityNickname = acc.Name.replaceAll('\\s+', '') + '.ff';
            u.ProfileId = profileId;
            u.EmailEncodingKey = 'UTF-8';
            u.LanguageLocaleKey = 'en_US';
            u.LocaleSidKey = 'en_US';
            u.TimeZoneSidKey = 'America/New_York';
            u.ContactId = acc.PersonContactId;
            u.IsActive = true;

            users.add(u);
            indexToAccountId.put(i, acc.Id);
        }

        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        List<Id> buyerAccountIds = new List<Id>();

        if (!users.isEmpty()) {
            Database.SaveResult[] results = Database.insert(users, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    psaList.add(new PermissionSetAssignment(
                        AssigneeId = results[i].getId(),
                        PermissionSetId = permSetId
                    ));
                    buyerAccountIds.add(indexToAccountId.get(i));
                }
            }
        }

        if (!psaList.isEmpty()) insert psaList;

        if (!buyerAccountIds.isEmpty()) {
            System.enqueueJob(new B2BProvisioningWorkerGroup(buyerAccountIds));
        }
    }
}