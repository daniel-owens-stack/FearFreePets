/**
 * @ Author: Gary Guthrie
 * @ Create Time: 2022-10-29 17:55:26
 * @ Modified by: Gary Guthrie
 * @ Modified time: 2022-11-18 00:01:02
 * @ Description: Test class is GetAllUnitsEXT_Test
 */

public with sharing class GetAllUnitsEXT {
    private ApexPages.StandardSetController stdSetController;

    public GetAllUnitsEXT(ApexPages.StandardSetController ctrl) {
        this.stdSetController = ctrl;
    }

    public pageReference getBack() {
        Map<String, List<SObject>> objectListByName = SchooxAPI.getAllUnits();
        List<SX_Above_Unit__c> aboveList = SchooxAPI.getAllAboveUnits();
        List<SX_Unit__c> unitList = objectListByName.get('Unit');
        upsert unitList SX_ID__c;
        System.debug('unitList: ' + unitList.size());
        // System.debug(JSON.serializePretty(unitList));

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
        // System.debug(JSON.serializePretty(aboveUnitList));

        List<SX_Role__c> roleList = objectListByName.get('Role');
        upsert roleList Unit_Above_Unit__c;
        System.debug('roleList: ' + roleList.size());
        // System.debug(JSON.serializePretty(roleList));

        return this.stdSetController.cancel();
    }
}