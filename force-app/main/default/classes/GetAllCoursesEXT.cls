/**
 * @ Author: Gary Guthrie
 * @ Create Time: 2022-09-06 22:37:10
 * @ Modified by: Gary Guthrie
 * @ Modified time: 2022-11-08 20:18:07
 * @ Description: Test class is GetAllCoursesEXT_Test
 */

public with sharing class GetAllCoursesEXT {
    private ApexPages.StandardSetController stdSetController;

    public GetAllCoursesEXT(ApexPages.StandardSetController ctrl) {
        this.stdSetController = ctrl;
    }

    public pageReference getBack() {
        List<SX_Courses__c> coursesToUpdate = SchooxAPI.getAllCourse(null);
        for (SX_Courses__c rec : coursesToUpdate) {
            rec.SX_Course_Active__c = true;
        }

        upsert coursesToUpdate SX_Course_ID__c;
        System.debug('coursesToUpdate: ' + coursesToUpdate.size());
        return this.stdSetController.cancel();
    }
}