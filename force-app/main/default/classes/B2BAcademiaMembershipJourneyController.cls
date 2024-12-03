public without sharing class B2BAcademiaMembershipJourneyController {
    @AuraEnabled
    public static string uploadFile( String fileName, String base64Content) {
        try{
            base64Content = EncodingUtil.urlDecode(base64Content, 'UTF-8');

            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = '/' + fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Content);
            cv.IsMajorVersion = true;
            insert cv;

            ContentVersion cvafterinsert = [SELECT Id,ContentDocumentId,Title FROM ContentVersion WHERE Id =: cv.Id];

            ContentDocument cd = [SELECT Id,Title,LatestPublishedVersionId FROM ContentDocument WHERE Id =: cvafterinsert.ContentDocumentId];

            Id contentDocumentId = cd.Id;
            List<ContentDistribution> cds = [SELECT DistributionPublicUrl,Name,ContentDocumentId FROM ContentDistribution WHERE ContentDocumentId =:contentDocumentId];
            
            String accountId;
            if(Test.isRunningTest()) {
                accountId = B2BTestDataFactory.createAccount();
            }
            else {
                accountId = B2BUtils.getUserAccountID();
            }
            
            if (!cds.isEmpty()){
                Account userAccount = [SELECT Id, Academia_File_Content_Document_Id__c, Academia_Membership_File_Link__c FROM Account WHERE Id =: accountId];   
                userAccount.Academia_Membership_File_Link__c = cds[0].DistributionPublicUrl;
                userAccount.Academia_File_Content_Document_Id__c = cd.Id;
                update userAccount;
            } else {
                ContentDistribution newCd = new ContentDistribution(
                    Name = cd.Title,
                    ContentVersionId = cd.LatestPublishedVersionId,
                    PreferencesAllowViewInBrowser = true
                );
                insert newCd;
                ContentDistribution[] newCdList = [SELECT DistributionPublicUrl FROM ContentDistribution WHERE ContentDocumentId = :contentDocumentId];
                
                if (!newCdList.isEmpty()) {
                    Account userAccount = [SELECT Id, Academia_File_Content_Document_Id__c, Academia_Membership_File_Link__c FROM Account WHERE Id =: accountId];   
                    userAccount.Academia_Membership_File_Link__c = newCdList[0].DistributionPublicUrl;
                    userAccount.Academia_File_Content_Document_Id__c = cd.Id;
                    update userAccount;
                }
            }
            return cd.Title;
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BAcademiaMembershipJourneyController', 'uploadFile');
        }
        return null;
    }

    @AuraEnabled
    public static void updateAccount(String graduationYear, String schoolUniversity, String JobTitle) {
        try {
            String accountId = B2BUtils.getUserAccountID();
            List<Account> account = [SELECT Id, Graduation_Year__c, School_University__c, Academia_Job_Title__c
                                    FROM Account 
                                    WHERE Id =: accountId];   
            
            if(account.size() > 0) {
                account[0].Graduation_Year__c = graduationYear;
                account[0].School_University__c = schoolUniversity;
                account[0].Academia_Job_Title__c = JobTitle;

                update account[0];
            }
        }
        catch(Exception e) {
            B2BHandleCustomException.LogException(e, 'B2BAcademiaMembershipJourneyController', 'updateAccount');
        }
    }
}