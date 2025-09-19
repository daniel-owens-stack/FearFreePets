global class UpdateTicketStatusBatch implements Database.Batchable<SObject>, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all tickets with status "New" and specified subject or criteria
        return Database.getQueryLocator([
            SELECT Id, Subject, Status, ContactEmail 
            FROM Case 
            WHERE Status = 'New' 
            AND (Subject LIKE '%OOO%' OR Subject LIKE '%Out of Office%' OR Subject LIKE '%Vacation%' 
                OR Subject LIKE '%Automatic Response%' OR Subject LIKE '%Automatic Reply%' 
                OR Subject LIKE '%Auto Reply%' OR Subject = 'Notification of payment received' 
                OR Subject = '[Fear Free Pets] New User Registration' OR ContactEmail = 'otify@ringcentral.com'
)
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Case> scope) {
        List<Case> casesToUpdate = new List<Case>();

        // Update the status of each Case to "Closed (Spam)"
        for (Case c : scope) {
            c.Status = 'Closed (Spam)';
            casesToUpdate.add(c);
        }

        // Update the Cases in bulk
        update casesToUpdate;
    }

    global void finish(Database.BatchableContext bc) {
        // You can add any post-processing logic here
    }
}