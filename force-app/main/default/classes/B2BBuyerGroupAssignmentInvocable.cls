public class B2BBuyerGroupAssignmentInvocable {
    @InvocableMethod(label='B2B Buyer Group Assignment' description='Handles buyer group assignments when a Team Admin status is changed on Account.')
    public static void handleTeamAdminChange(List<Account> accounts) {

        Account account;
        if(accounts != null || !accounts.isEmpty()) {
            account = accounts[0];
        }

        if(account != null) {
            B2BBuyerGroupAssignemntController.handleBuyerGroupsForAccount(account);
        }
    }
}