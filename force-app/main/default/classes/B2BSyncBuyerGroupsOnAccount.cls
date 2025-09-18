/**
 * @description       : 
 * @author            : Poojitha Anthati
 * @group             : 
 * @last modified on  : 09-18-2025
 * @last modified by  : Poojitha Anthati
**/
public class B2BSyncBuyerGroupsOnAccount {
    @InvocableMethod(label='B2B Sync BuyerGroups On Account' description='Sync buyergroup assignments on Account.')
    public static void handleBuyerGroupsSync(List<Account> accounts) {

        Account account;
        if(accounts != null || !accounts.isEmpty()) {
            account = accounts[0];
        }

        if(account != null) {
            B2BBuyerGroupAssignemntController.handleBuyerGroupsSync(account);
        }
    }
}