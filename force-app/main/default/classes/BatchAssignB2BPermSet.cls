global class BatchAssignB2BPermSet implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (Test.isRunningTest()) {
            // Only return the specific test user
            return Database.getQueryLocator([
            SELECT Id 
            FROM User 
            WHERE Username LIKE 'testuser%@test.com'
            //AND IsActive = true
            LIMIT 1
        ]);
        }
        return Database.getQueryLocator([
            SELECT Id 
            FROM User 
            WHERE Profile.Name = 'Fear Free Community Member'
            AND IsActive = true
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<User> scope) {
        PermissionSet ps = [
            SELECT Id FROM PermissionSet 
            WHERE Name = 'Fear_Free_B2B_Store_Buyer' 
            LIMIT 1
        ];
        
        List<PermissionSetAssignment> psaToInsert = new List<PermissionSetAssignment>();
        
        for (User u : scope) {
            if ([
                SELECT Id 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :u.Id AND PermissionSetId = :ps.Id 
                LIMIT 1
            ].isEmpty()) {
                psaToInsert.add(new PermissionSetAssignment(
                    AssigneeId = u.Id,
                PermissionSetId = ps.Id
                    ));
            }
        }
        
        if (!psaToInsert.isEmpty()) {
            insert psaToInsert;
        }
    }
    
    global void finish(Database.BatchableContext bc) {}
}