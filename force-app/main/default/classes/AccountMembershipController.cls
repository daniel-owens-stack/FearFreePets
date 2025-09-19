public without sharing class AccountMembershipController {
    @AuraEnabled
    public static Map<String, Object> checkMembershipStatus(
        Boolean checkAccountMembership,
    Boolean checkVetProMembership,
    Boolean checkPracticeMembership,
    Boolean checkPracticeMembershipGP,
    Boolean checkPracticeMembershipER,
    Boolean checkPracticeMembershipHC,
    Boolean checkGroomerMembership,
    Boolean checkSitterMembership,
    Boolean checkTrainerMembership,
    Boolean checkBoardingMembership,
    Boolean checkAcademiaMembership,
    Boolean certifiedStatus,
    Boolean isExpired,
    Boolean anyStatus,
    Boolean excludeGroomer,
    Boolean excludeSitter,
    Boolean excludeTrainer,
    Boolean excludeBoarding,
    Boolean excludeAcademia,
    Boolean excludeVetPro,
    Boolean excludePracticeMembership,
    Boolean excludePracticeMembershipGP,
    Boolean excludePracticeMembershipER,
    Boolean excludePracticeMembershipHC
    ) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            result.put('hasActiveAccountMembership', false);
            result.put('hasActivePracticeLevelMembership', false);
            result.put('hasActivePracticeLevelGPMembership', false);
            result.put('hasActivePracticeLevelERMembership', false);
            result.put('hasActivePracticeLevelHCMembership', false);
            result.put('hasActiveVetProLevelMembership', false);
            result.put('hasActiveGroomerLevelMembership', false);
            result.put('hasActiveSitterLevelMembership', false);
            result.put('hasActiveTrainerLevelMembership', false);
            result.put('hasActiveBoardingLevelMembership', false);
            result.put('hasActiveAcademiaLevelMembership', false);
            result.put('isAdmin', false);
            
            Id currentUserId = UserInfo.getUserId();
            User currentUser = [SELECT Profile.Name, AccountId, ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
            String profileName = currentUser.Profile?.Name;
            
            if (profileName == null) {
                result.put('error', 'User profile not found or inaccessible.');
                return result;
            }
            Boolean isAdmin = profileName == 'System Administrator';
            result.put('isAdmin', isAdmin);
            
            if (isAdmin) {
                for (String key : result.keySet()) {
                    if (key.startsWith('hasActive')) {
                        result.put(key, true);
                    }
                }
                return result;
            }
            
            Id accountId = currentUser.AccountId;
            if (accountId == null) {
                result.put('error', 'User is not associated with an Account.');
                return result;
            }
            
            List<Account_Membership__c> accountMemberships = (isExpired) ?
                [SELECT Id, Status__c, Membership__r.Name FROM Account_Membership__c WHERE Status__c = 'Complete' AND Account_Id__c = :accountId] :
                (certifiedStatus) ?
                [SELECT Id, Status__c, Membership__r.Name FROM Account_Membership__c WHERE Status__c = 'Active' AND Account_Id__c = :accountId AND Certified__c = true] :
                (anyStatus) ?
                [SELECT Id, Status__c, Membership__r.Name FROM Account_Membership__c WHERE Account_Id__c = :accountId] :
                [SELECT Id, Status__c, Membership__r.Name FROM Account_Membership__c WHERE Status__c = 'Active' AND Account_Id__c = :accountId];
            
            Boolean hasGPPLMA = false, hasERPLMA = false, hasHCPLMA = false;
            Account adminAccount = [SELECT Id, Admin_Account__c, Business__c FROM Account WHERE Id = :accountId LIMIT 1];
            if (adminAccount.Admin_Account__c == true && adminAccount.Business__c != null) {
                List<Practice_Level_Membership_Assignment__c> plmaList = [
                    SELECT Membership__r.Name FROM Practice_Level_Membership_Assignment__c
                    WHERE Business_Account__c = :adminAccount.Business__c AND Status__c = 'Active'
                ];
                for (Practice_Level_Membership_Assignment__c plma : plmaList) {
                    String name = plma.Membership__r.Name;
                    if (name.contains('General Practice Membership')) {hasGPPLMA = true;}
                    if (name.contains('ER/Urgent Care Membership')) {hasERPLMA = true;}
                    if (name.contains('House Call Membership')) {hasHCPLMA = true;}
                }
            }
            
            Boolean hasPracticeFromMembership = false;
            for (Account_Membership__c membership : accountMemberships) {
                String name = membership.Membership__r?.Name;
                if (checkAccountMembership && membership.Status__c == 'Active') {
                    result.put('hasActiveAccountMembership', true);
                }
                if (checkVetProMembership && !excludeVetPro && name == 'Veterinary Professional Membership') {
                    result.put('hasActiveVetProLevelMembership', true);
                }
                if (checkAcademiaMembership && !excludeAcademia && name == 'Academia Membership') {
                    result.put('hasActiveAcademiaLevelMembership', true);
                }
                if (checkGroomerMembership && !excludeGroomer && name == 'Groomer Membership') {
                    result.put('hasActiveGroomerLevelMembership', true);
                }
                if (checkSitterMembership && !excludeSitter && name == 'Pet Sitter Membership') {
                    result.put('hasActiveSitterLevelMembership', true);
                }
                if (checkBoardingMembership && !excludeBoarding && name == 'Boarding & Daycare Individual Membership') {
                    result.put('hasActiveBoardingLevelMembership', true);
                }
                if (checkTrainerMembership && !excludeTrainer && name == 'Trainer Membership') {
                    result.put('hasActiveTrainerLevelMembership', true);
                }
                if (name != null && name.contains('Veterinary Practice Certification')) {
                    hasPracticeFromMembership = true;
                }
                if (checkPracticeMembershipGP && !excludePracticeMembershipGP &&
                name.contains('Veterinary Practice Certification - General Practice')) {
                    result.put('hasActivePracticeLevelGPMembership', true);
                }
                
                if (checkPracticeMembershipER && !excludePracticeMembershipER &&
                name.contains('Veterinary Practice Certification - ER/Urgent Care')) {
                    result.put('hasActivePracticeLevelERMembership', true);
                }
                
                if (checkPracticeMembershipHC && !excludePracticeMembershipHC &&
                name.contains('Veterinary Practice Certification - House Call')) {
                    result.put('hasActivePracticeLevelHCMembership', true);
                }
            }
            
            if (checkPracticeMembership && !excludePracticeMembership && (hasPracticeFromMembership || hasERPLMA || hasGPPLMA || hasHCPLMA)) {
                result.put('hasActivePracticeLevelMembership', true);
            }
            if (checkPracticeMembershipGP && !excludePracticeMembershipGP && hasGPPLMA) {
                result.put('hasActivePracticeLevelGPMembership', true);
            }
            if (checkPracticeMembershipER && !excludePracticeMembershipER && hasERPLMA) {
                result.put('hasActivePracticeLevelERMembership', true);
            }
            if (checkPracticeMembershipHC && !excludePracticeMembershipHC && hasHCPLMA) {
                result.put('hasActivePracticeLevelHCMembership', true);
            }
        } catch (Exception e) {
            result.put('error', e.getMessage());
        }
        return result;
    }
}