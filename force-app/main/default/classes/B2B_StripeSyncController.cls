public with sharing class B2B_StripeSyncController {
    @AuraEnabled
    public static Map<String,Object> updateStripeCustomer(Map<String,Object> mapParams){
        try {
            mapParams = B2B_StripeSyncHelper.updateStripeCustomer(mapParams);
        } catch (Exception e) {
            mapParams = mapParams == null ? new Map<String,Object>() : mapParams;
            mapParams.put('isSuccess',false);
            mapParams.put('message', e.getMessage());
        }
        return mapParams;
    }
}