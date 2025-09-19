/**
 * @description       : 
 * @testing           : 
 * @author            : FSM
 * @last modified on  : 09-20-2024 - FSM
 * @last modified by  : FSM
**/
public without sharing class NumberReportViewController 
{
    @AuraEnabled(cacheable=true)
    public static Map<String,Integer> getMembershipCounts(String userId)
    {
        Map<String,Integer> membershipDataMap = new Map<String,Integer>();
        Map<String, String> whereQueryMap = new Map<String,String>();

        Map<String, Membership_Component_Configuration__mdt> memConfigRecords = Membership_Component_Configuration__mdt.getAll();
        for(String label: memConfigRecords.keySet())
        {
            System.debug(label +' --> '+memConfigRecords.get(label).Query__c );
            String query = memConfigRecords.get(label).Query__c;
            List<String> queryList = query.split('(?i)where');
            String whereClause = buildDynamicWhereClause(userId,queryList[1].trim());
            if(whereClause != null)
            {
                whereQueryMap.put(memConfigRecords.get(label).MasterLabel, queryList[0] + ' WHERE ' + whereClause);
            }
            else 
            {
                whereQueryMap.put(memConfigRecords.get(label).MasterLabel, null);
            }
        }

        System.debug('whereQueryMap = ' + whereQueryMap);

        for(String label: whereQueryMap.keySet())
        {
            if(whereQueryMap.get(label) != null)
            {
                Integer recordCount = Database.countQuery(whereQueryMap.get(label));
                memberShipDataMap.put(label, recordCount);
            }
            else 
            {
                membershipDataMap.put(label, 0);
            }
        }

        return membershipDataMap;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,Integer> getMembershipCount(String userId, String metaDataApiName)
    {
        Map<String,Integer> membershipDataMap = new Map<String,Integer>();
        Map<String, String> whereQueryMap = new Map<String,String>();

        Membership_Component_Configuration__mdt configMetadata = Membership_Component_Configuration__mdt.getInstance(metaDataApiName);

        System.debug(configMetadata.label + ' --> ' + configMetadata.Query__c );
        String query = configMetadata.Query__c;
        List<String> queryList = query.split('(?i)where');
        String whereClause = buildDynamicWhereClause(userId,queryList[1].trim());
        if(whereClause != null)
        {
            whereQueryMap.put(configMetadata.MasterLabel, queryList[0] + ' WHERE ' + whereClause);
        }
        else 
        {
            whereQueryMap.put(configMetadata.MasterLabel, null);
        }
        

        System.debug('whereQueryMap = ' + whereQueryMap);

        for(String label: whereQueryMap.keySet())
        {
            if(whereQueryMap.get(label) != null)
            {
                Integer recordCount = Database.countQuery(whereQueryMap.get(label));
                memberShipDataMap.put(label, recordCount);
            }
            else 
            {
                membershipDataMap.put(label, 0);
            }
        }

        return membershipDataMap;
    }

    public static String buildDynamicWhereClause(String recordId, String whereClause)
    {
        String newWhereClause = whereClause;
        Id recId = recordId;

        List<String> fieldListRaw = new List<String>();
        List<String> fieldListClean = new List<String>();

        SObjectType objType = recId.getSObjectType();
        System.debug('objType = ' + objType);

        whereClause = whereClause.replaceAll(objType + '\\.', '');
        System.debug('whereClause = ' + whereClause);

        Pattern p = Pattern.compile('\\(!.+?\\)');
        Matcher m = p.matcher(whereClause);
        while(m.find()) 
        {
            System.debug(m.group(0));
            fieldListRaw.add(m.group(0));
        }
        System.debug('fieldListRaw = ' + fieldListRaw);

        String query = 'SELECT ';

        if(fieldListRaw.size() > 0)
        {
            for (Integer i = 0; i < fieldListRaw.size(); i++) 
            {
                String s1 = fieldListRaw[i].replaceAll('\\(!', '');
                String s2 = s1.replaceAll('\\)', '');
                
                if(i == fieldListRaw.size() - 1)
                {
                    query = query + s2 + ' ';
                }
                else 
                {
                    query = query + s2 + ', ';    
                }
                
                fieldListClean.add(s2);
            }
        }
        else 
        {
            query = query + 'Id ';
        }
        System.debug('fieldListClean = ' + fieldListClean);

        query = query + 'FROM ' + objType + ' WHERE Id = :recId';
        System.debug('query = ' + query);
        List<SObject> records = Database.query(query);

        SObjectType r = ((SObject)(Type.forName('Schema.' + objType).newInstance())).getSObjectType();
        DescribeSObjectResult d = r.getDescribe();
        Map<String,String> fieldMap = new Map<String,String>();
        for(String str :fieldListClean)
        {
            if(str.contains('.'))
            {
                List<String> strList = new List<String>();
                strList = str.split('\\.');
                System.debug('strList = ' + strList);
                String objectStr = strList[0];
                SObjectType relationObjType = ((SObject)(Type.forName('Schema.' + objectStr).newInstance())).getSObjectType();
                DescribeSObjectResult relationDescribe = relationObjType.getDescribe();
                System.debug(relationDescribe.fields
                            .getMap()
                            .get(strList[1])
                            .getDescribe()
                            .getType());
                fieldMap.put(strList[1], String.valueOf(relationDescribe.fields.getMap().get(strList[1]).getDescribe().getType()));   
            }
            else
            {
                System.debug(d.fields
                            .getMap()
                            .get(str)
                            .getDescribe()
                            .getType());
                fieldMap.put(str, String.valueOf(d.fields.getMap().get(str).getDescribe().getType()));       
            }
        
        }


        Integer index = 0;
        Pattern p2 = Pattern.compile('\\(!.+?\\)');
        Matcher m2 = p2.matcher(whereClause);
        while(m2.find()) 
        {
            String matchStr = m2.group(0);
            String fieldType = fieldMap.get(fieldListClean[index]);
            System.debug('fieldType = ' + fieldType);
            System.debug('matchStr = ' + matchStr);
            Object fieldVal = getValue(records[0], fieldListClean[index]);
            if(fieldVal != null)
            {
                if(fieldType != 'DOUBLE' || fieldType != 'BOOLEAN')
                {
                    newWhereClause = whereClause.replace(matchStr, String.valueOf('\'' +  getValue(records[0], fieldListClean[index]) ) + '\'');
                    System.debug('newWhereClause = ' + newWhereClause);
                }
                else
                {
                    newWhereClause = whereClause.replace(matchStr, String.valueOf(getValue(records[0], fieldListClean[index]) ));
                    System.debug('newWhereClause = ' + newWhereClause);
                }
            }
            else 
            {
                newWhereClause = null;
            }
            index++;
            
        }
        System.debug('newWhereClause = ' + newWhereClause);

        return newWhereClause;
    }

    public static Object getValue(SObject record, String field)
    {
        Object returnVal;

        if(field.contains('.'))
        {
            List<String> strList = new List<String>();
            strList = field.split('\\.');
            System.debug('strList = ' + strList);
            String objectStr = strList[0];
            System.debug('objectStr = ' + objectStr);
            System.debug('strList[1] = ' + strList[1]);
            System.debug('record = ' + record);
            System.debug('record.getSObject(objectStr) = ' + record.getSObject(objectStr));
            if( record.getSObject(objectStr) != null)
            {
                System.debug('val = ' + record.getSObject(objectStr).get(strList[1]));
                returnVal = record.getSObject(objectStr).get(strList[1]);
            }
            else 
            {
                returnVal = null;
            }
        }
        else 
        {
            returnVal = record.get(field);
        }

        return returnVal;
    }
}