global class UpdateUserUsernameBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all active users
        String query = 'SELECT Id, Email, Username FROM User WHERE IsActive = true';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<User> scope) {
        List<User> usersToUpdate = new List<User>();
        
        // Iterate through the users in the batch
        for (User u : scope) {
            if (u.Email != null && u.Email != u.Username) {
                u.Username = u.Email;
                usersToUpdate.add(u);
            }
        }
        
        // Update users if there are any changes
        if (!usersToUpdate.isEmpty()) {
            try {
                update usersToUpdate;
            } catch (Exception e) {
                System.debug('Error updating users: ' + e.getMessage());
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        // Optional: Add logic for post-processing, like sending an email notification
        System.debug('Batch job UpdateUserUsernameBatch completed.');
    }
}