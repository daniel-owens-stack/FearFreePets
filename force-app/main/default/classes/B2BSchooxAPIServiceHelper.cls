public class B2BSchooxAPIServiceHelper {
    public static account getAccountById(String accountId) {
        return [
                SELECT Id, SX_User_Id__pc
                FROM Account 
                WHERE Id =:accountId
            ];
    }

    public static List<Integer> combineIntegerLists(List<Integer> list1, List<Integer> list2) {
        Set<Integer> uniqueSet = new Set<Integer>();
        uniqueSet.addAll(list1);
        uniqueSet.addAll(list2);
        return new List<Integer>(uniqueSet);
    }
    
}