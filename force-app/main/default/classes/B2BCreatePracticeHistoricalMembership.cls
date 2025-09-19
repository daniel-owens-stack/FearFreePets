/**
* @File Name : B2BCreatePracticeHistoricalMembership.cls
* @Description : Create PLMS Records from Historical PLMA Records
* Test class :B2BCreatePLMATest
* @Author : Meenakshi Jain@Stack Intelligence
* @Created : June 2025
*/
public class B2BCreatePracticeHistoricalMembership implements Database.Batchable<sObject>, Database.Stateful {
    //variable
    String query;
    //constructor
    public B2BCreatePracticeHistoricalMembership() { }
    public B2BCreatePracticeHistoricalMembership(String query){
        this.query = query;
    }
    
    //start of batch
    public List<Historical_PLMA__c> start(Database.BatchableContext BC) {
        List<Historical_PLMA__c> historicalList = new List<Historical_PLMA__c>();

        historicalList = String.isNotBlank(query) ? 
            Database.query(query) 
            :[SELECT Id,Cert_Date__c,Cert_Status__c,Admin_Id__c,PLMA_Status__c,
              End_Date__c,Group_ID__c,Membership_Type__c,Start_Date__c,Status__c
              FROM Historical_PLMA__c
              WHERE Data_Status__c = 'Pending'];
                  return historicalList;
    }
    
    //execute of batch
    public void execute(Database.BatchableContext bc, List<Historical_PLMA__c> scope) {
        processRecords(scope);
    }
    //finish of batch
    public void finish(Database.BatchableContext bc) {
        System.debug('Finish method called');
    }
    
    //Process Records
    public static void processRecords( List<Historical_PLMA__c> scope){
        try{
            System.debug('Execute method - Scope size: ' + scope.size());
            Set<String> groupIdSet = new Set<String>();
            Map<String,B2B_Custom_Exception__c> b2bCustomExceptionList = new Map<String,B2B_Custom_Exception__c>();
            
            for(Historical_PLMA__c historicalPlma : scope){
                if(String.isNotBlank(historicalPlma.Group_ID__c)){
                    groupIdSet.add(historicalPlma.Group_ID__c);
                }else{
                    
                    b2bCustomExceptionList.put(historicalPlma.Id,
                                               B2BHandleCustomException.logExceptionWithoutInsert(
                                                   new B2BCreateHistoricalMembershipsBatch.HistoricalMembershipException('Group Id is Blank'),
                                                   'Historical Memberships PLMA',
                                                   'PLMA Membership Creation'
                                               ));
                }
                
                if(String.isNotBlank(historicalPlma.Admin_Id__c)){
                    groupIdSet.add(historicalPlma.Admin_Id__c);
                }else{
                    
                    b2bCustomExceptionList.put(historicalPlma.Id,
                                               B2BHandleCustomException.logExceptionWithoutInsert(
                                                   new B2BCreateHistoricalMembershipsBatch.HistoricalMembershipException('Admin Id is Blank'),
                                                   'Historical Memberships PLMA',
                                                   'PLMA Membership Creation'
                                               ));
                }
            }
            
            
            if(!groupIdSet.isEmpty()){
                Map<String,Id> groupVsAccountIdMap = new Map<String,Id>();
                List<Account> accountList = [SELECT Id,Original_System_ID__c 
                                             FROM account WHERE Original_System_ID__c IN: groupIdSet];
                for(Account account : accountList){
                    groupVsAccountIdMap.put(account.Original_System_ID__c,account.Id);
                }
                List<Practice_Level_Membership_Assignment__c> practiceMembershipList = new List<Practice_Level_Membership_Assignment__c>();
                
                Map<String,String> historicalMetadata = getHistoricalMetadata();
                for(Historical_PLMA__c historicalPlma : scope){
                    String message = '';
                    if(!groupVsAccountIdMap.containsKey(historicalPlma.Group_ID__c))
                        message = 'No Account Exist for the Group Id - '+historicalPlma.Group_ID__c;
                    else if(!groupVsAccountIdMap.containsKey(historicalPlma.Admin_Id__c))
                        message = 'No Account Exist for the Admin Id - '+historicalPlma.Admin_Id__c;                        
                    else if(!historicalMetadata.containsKey(historicalPlma.Membership_Type__c))
                        message = 'Membership does not Exist for associated Membership type on Historical PLMA';
                    
                    if(String.isNotBlank(message)){
                        b2bCustomExceptionList.put(historicalPlma.Id,
                                                   B2BHandleCustomException.logExceptionWithoutInsert(
                                                       new B2BCreateHistoricalMembershipsBatch.HistoricalMembershipException(message),
                                                       'Historical Memberships PLMA',
                                                       'PLMA Membership Creation'
                                                   ));
                    }else{
                        practiceMembershipList.add(
                            new Practice_Level_Membership_Assignment__c(
                                Business_Account__c = groupVsAccountIdMap.get(historicalPlma.Group_ID__c),
                                Status__c = historicalPlma.PLMA_Status__c,
                                Historical_Start_Date__c = historicalPlma.Start_Date__c,
                                Start_Date__c = historicalPlma.End_Date__c != null ?
                                historicalPlma.End_Date__c.addYears(-1) : null,
                                Certification_Date__c  =historicalPlma.Cert_Date__c,
                                Certified__c = historicalPlma.Cert_Status__c,
                                Membership__c = historicalMetadata.get(historicalPlma.Membership_Type__c),
                                Purchaser__c = groupVsAccountIdMap.get(historicalPlma.Admin_Id__c),
                                Historical_PLMA__c = historicalPlma.Id,
                                Need_Historical_Review__c = true,
                                Welcome_Kit_Status__c = 'Unavailable'
                            ));
                    }
                }
                if(!practiceMembershipList.isEmpty()){
                    List<Database.SaveResult> saveResultList = Database.insert(practiceMembershipList,false);
                    Integer i = 0;
                    for(Database.SaveResult sr : saveResultList){
                        if (!sr.isSuccess()) {
                            for(Database.Error err : sr.getErrors()) {
                                System.debug('The following error has occurred.');                    
                                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                b2bCustomExceptionList.put(practiceMembershipList[i].Historical_PLMA__c,
                                                           B2BHandleCustomException.logExceptionWithoutInsert(
                                                               new B2BCreateHistoricalMembershipsBatch.HistoricalMembershipException(err.getStatusCode() + ': ' + err.getMessage()),
                                                               'Historical Memberships PLMA',
                                                               'PLMA Membership Creation'
                                                           ));
                            }
                        }
                        i++;
                        
                    }
                    
                }
                
            }
            if(!b2bCustomExceptionList.isEmpty()){
                insert b2bCustomExceptionList.values();
            }
            for(Historical_PLMA__c historicalPlma : scope){
                
                if(b2bCustomExceptionList.containsKey(historicalPlma.Id)){
                    historicalPlma.B2B_Custom_Exception__c = b2bCustomExceptionList.get(historicalPlma.Id).Id;
                }
                historicalPlma.Data_Status__c = b2bCustomExceptionList.containsKey(historicalPlma.Id) ?
                    'Unsuccessful' : 'Successful';
            }
            update scope;
        }catch (Exception e) {
            System.debug('Batch-level exception: ' + e.getMessage());
            B2BHandleCustomException.LogException(e, 'Historical PLMA Memberships', 'PLMA Membership Creation - Batch Level Failure');
        }
    }
    
    //get historical metadata
    public static Map<String,String> getHistoricalMetadata(){
        Map<String,Historical_Membership_PLMA__mdt> historicalMap = Historical_Membership_PLMA__mdt.getAll();
        Map<String,String> responseMap = new Map<String,String>();
        for(Historical_Membership_PLMA__mdt historical : historicalMap.values()){
            responseMap.put(historical.Label,historical.Membership_Id__c);
        }
        return responseMap;
    }
    
    
    
}