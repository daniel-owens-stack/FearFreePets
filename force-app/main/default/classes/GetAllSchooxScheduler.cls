/**
 * @ Author: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Create Time: 2022-10-11 15:36:07
 * @ Modified by: Ridowan Ahmed (ridowan.dev@gmail.com)
 * @ Modified time: 2024-09-03 18:42:06
 * @ Description: GetAllSchooxScheduler_Test
 * new GetAllSchooxScheduler().execute(null);
 * System.schedule('Schoox Jobs, Units, Courses Sync', '0 0 06,18 ? * MON-FRI', new GetAllSchooxScheduler());
 */

public without sharing class GetAllSchooxScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        getJobs();
        getUnits();
        getCourse();
    }

    @Future(Callout=true)
    private static void getJobs() {
        List<SX_Job__c> sxJobList = SchooxAPI.getAllJob();

        upsert sxJobList SX_Job_ID__c;
        System.debug('sxJobList: ' + sxJobList.size());
    }

    @Future(Callout=true)
    private static void getUnits(){
        Map<String, List<SObject>> objectListByName = SchooxAPI.getAllUnits();
        List<SX_Above_Unit__c> aboveList = SchooxAPI.getAllAboveUnits();
        List<SX_Unit__c> unitList = objectListByName.get('Unit');
        upsert unitList SX_ID__c;
        System.debug('unitList: ' + unitList.size());

        List<SX_Above_Unit__c> aboveUnitList = objectListByName.get('Above Unit');
        Set<String> aboveUnitNames = new Set<String>();
        for (SX_Above_Unit__c rec : aboveUnitList) {
            aboveUnitNames.add(rec.Name);
        }
        for (SX_Above_Unit__c rec : aboveList) {
            if(!aboveUnitNames.contains(rec.Name)){
                aboveUnitList.add(rec);
            }
        }
        upsert aboveUnitList SX_ID__c;
        System.debug('aboveUnitList: ' + aboveUnitList.size());

        List<SX_Role__c> roleList = objectListByName.get('Role');
        upsert roleList Unit_Above_Unit__c;
        System.debug('roleList: ' + roleList.size());
    }

    @Future(Callout=true)
    private static void getCourse(){
        List<SX_Courses__c> coursesToUpdate = new List<SX_Courses__c>();

        List<SX_Courses__c> activeCourses = SchooxAPI.getAllCourse('active');
        for (SX_Courses__c course : activeCourses) {
            course.SX_Course_Active__c = true;
            course.Status__c = 'Active';
        }
        coursesToUpdate.addAll(activeCourses);

        List<SX_Courses__c> deletedCourses = SchooxAPI.getAllCourse('deleted');
        for (SX_Courses__c course : deletedCourses) {
            course.SX_Course_Active__c = false;
            course.Status__c = 'Deleted';
        }
        coursesToUpdate.addAll(deletedCourses);

        List<SX_Courses__c> archivedCourses = SchooxAPI.getAllCourse('archived');
        for (SX_Courses__c course : archivedCourses) {
            course.SX_Course_Active__c = false;
            course.Status__c = 'Archived';
        }
        coursesToUpdate.addAll(archivedCourses);

        if (!Test.isRunningTest()) {
            upsert coursesToUpdate SX_Course_ID__c;
        }        
        System.debug('coursesToUpdate: ' + coursesToUpdate.size());
    }
}