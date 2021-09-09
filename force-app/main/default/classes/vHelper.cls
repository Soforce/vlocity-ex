public with sharing class vHelper {
    /**
     * @description helper method to check if the V2 JSON Attribute for the given xLI ObjectType
     */
    public static Boolean isV2Attribute(SObjectType itemObjectType) {
        
        Boolean v2Attribute = vlocity_cmt.VlocityFeatureService.isV2AttributeModelEnabled();
        // Notice - the InventoryItem & FulfilmentRequestLine__c objects does not support v2 yet
        if (itemObjectType != null) {
            v2Attribute = v2Attribute && itemObjectType != vlocity_cmt__InventoryItem__c.SObjectType && itemObjectType != vlocity_cmt__FulfilmentRequestLine__c.SObjectType;
        }
        if (Test.isRunningTest()) 
            return vHelperTest.isV2AttributeMock(itemObjectType);
        else 
            return v2Attribute;
    }
    
    // /**
    //  * @description helper method to check if the V2 JSON Attribute for the given xLI record
    //  */
    // public static Boolean isV2Attribute(Id itemId) {
    //     return isV2Attribute(itemId.getSobjectType());
    // }

    /*
     * @description utiliy method to read the attribute values which supports both v1 and v2
     *  JSONAttribute__c for v1 and AttributeSelectedValues__c for v2
     */
    public static Map<String, Object> getJSONAttributeValues(String jsonAttribute) {
        Map<String, Object> attribVals = new Map<String, Object>();
        if (String.isEmpty(jsonAttribute)) return attribVals;

        // JSON.deserializeUntyped uses less CPU time than the JSONParser 
        Map<String, Object> attributeObj = (Map<String, Object>)JSON.deserializeUntyped(jsonAttribute);
        for (String keyName : attributeObj.keySet()) {
            Object valueObj = attributeObj.get(keyName);
            if (valueObj instanceOf List<Object>) {
                // v1
                for (Object attrObj : (List<Object>)valueObj) {
                    Map<String, Object> attrib = (Map<String, Object>)attrObj;
                    Map<String, Object> attributeRunTimeInfo = (Map<String, Object>)attrib.get('attributeRunTimeInfo');
                    String code = (String)attrib.get('attributeuniquecode__c');
                    if ((String)attributeRunTimeInfo.get('dataType') == 'Picklist') {
                        Map<String, Object> selectedItem = (Map<String, Object>)attributeRunTimeInfo.get('selectedItem');
                        if (selectedItem != null) {
                            attribVals.put(code, selectedItem.get('value'));
                        }
                    } else {
                        attribVals.put(code, attributeRunTimeInfo.get('value'));
                    }
                }                
            } else {
                // v2
                attribVals = attributeObj;
                break;
            }
        }


        return attribVals;
    }    

    /*
     * @description utiliy method to read the attribute values which supports both v1 and v2
     *  JSONAttribute__c for v1 and AttributeSelectedValues__c for v2
     */
    public static Object getJSONAttributeValue(String jsonAttribute, String attribCode) {
        return getJSONAttributeValues(jsonAttribute).get(attribCode);
    }     

    /*
     * @description utiliy method to set the JSON attribute values which supports both v1 and v2
     *  JSONAttribute__c for v1 and AttributeSelectedValues__c for v2
     */
    public static String setJSONAttribute(String runtimeJSON, String code, Object val) {
        Map<String, Object> attrVals = new Map<String, Object> {
            code => val
        };
        return setJSONAttributes(runtimeJSON, attrVals);
    }
    /*
     * @description utiliy method to set the JSON attribute values which supports both v1 and v2
     *  JSONAttribute__c for v1 and AttributeSelectedValues__c for v2
     */    
    public static String setJSONAttributes(String jsonAttribute, Map<String, Object> attrVals) {
        String modifiedJSON;

        Map<String, Object> attributeJsonObj = (Map<String, Object>)JSON.deserializeUntyped(jsonAttribute);
        for (String keyName : attributeJsonObj.keySet()) {
            Object valueObj = attributeJsonObj.get(keyName);
            if (valueObj instanceOf List<Object>) {
                // v1
                for (Object itemObj : (List<Object>)valueObj) {
                    Map<String, Object> attrib = (Map<String, Object>)itemObj;
                    String code = (String)attrib.get('attributeuniquecode__c');
                    if (attrVals.containsKey(code)) {
                        Map<String, Object> attributeRunTimeInfo = (Map<String, Object>)attrib.get('attributeRunTimeInfo');
                        Object val = attrVals.get(code);
                        
                        if ((String)attributeRunTimeInfo.get('dataType') == 'Picklist') {
                            List<Object> values = (List<Object>)attributeRunTimeInfo.get('values');
                            for (Object valObj : values) {
                                Object value = ((Map<String, Object>)valObj).get('value');
                                if (value == val) {
                                    attributeRunTimeInfo.put('selectedItem', valObj);
                                }
                            }
                        } else {
                            attributeRunTimeInfo.put('value', val);
                        }
                    }
                }                
            } else {
                // v2
                attributeJsonObj.putAll(attrVals);
                return JSON.serialize(attributeJsonObj, true);
            }
        }
        // v1
        return JSON.serialize(attributeJsonObj);
    }     
    

    // public static SObject executeFieldMapper(Id sourceObjId, Id targetObjId) {
    //     SObjectType objType = sourceObjId.getSObjectType();
    //     Map<String, SObjectField> fldMap = objType.getDescribe().fields.getMap();
    //     List<String> fnames = new List<String>(fldMap.keySet());
    //     String query = 'SELECT ' + String.join(fnames, ',') + ' FROM ' + objType.getDescribe().getName() + ' WHERE Id=:sourceObjId';
    //     // Map<Id, SObject> resultMap = new Map<Id, SObject>(Database.query(query));

    //     SObject sourceObj = Database.query(query);
    //     SObject targetObj = targetObjId.getSObjectType().newSObject();

    //     return executeFieldMapper(sourceObj, targetObj);
    // }

    /**
     * 
     */
    public static SObject executeFieldMapper(SObject sourceObj, SObject targetObj) {
        String sourceObjType = sourceObj.getSObjectType().getDescribe().getName();
        String targetObjType = targetObj.getSObjectType().getDescribe().getName();

        Map<String, Object> sourceFieldVals = sourceObj.getPopulatedFieldsAsMap();
        Map<String, Object> targetFieldVals = targetObj.getPopulatedFieldsAsMap();
        
        String query = 'SELECT vlocity_cmt__SourceFieldName__c, vlocity_cmt__DestinationFieldName__c FROM vlocity_cmt__CustomFieldMap__c WHERE vlocity_cmt__SourceSObjectType__c=:sourceObjType and vlocity_cmt__DestinationSObjectType__c=:targetObjType';
        vlocity_cmt__CustomFieldMap__c[] fieldMaps = Database.query(query);
        for (vlocity_cmt__CustomFieldMap__c fieldMap : fieldMaps) {
            if (sourceFieldVals.get(fieldMap.vlocity_cmt__SourceFieldName__c) != targetFieldVals.get(fieldMap.vlocity_cmt__DestinationFieldName__c))
                targetObj.put(fieldMap.vlocity_cmt__DestinationFieldName__c, sourceFieldVals.get(fieldMap.vlocity_cmt__SourceFieldName__c));
        }

        return targetObj; 
    }
}