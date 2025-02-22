@IsTest
public class B2BBatchClassMock implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id FROM Account]);
    }
    public void execute(Database.BatchableContext BC, List<sObject> scope) { }
    public void finish(Database.BatchableContext BC) { }
}