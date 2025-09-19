/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-10-22 23:00:03
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:41:30
 * @ Description: test class is GetAllJobsEXT_Test
 */

public with sharing class GetAllJobsEXT {
    private ApexPages.StandardSetController stdSetController;

    public GetAllJobsEXT(ApexPages.StandardSetController ctrl) {
        this.stdSetController = ctrl;
    }

    public pageReference getBack() {
        List<SX_Job__c> sxJobList = SchooxAPI.getAllJob();

        upsert sxJobList SX_Job_ID__c;
        System.debug('sxJobList: ' + sxJobList.size());
        return this.stdSetController.cancel();
    }
}