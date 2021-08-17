/**
 * @description extension of the OOTB JSONAttributeSupport class
 *   - applyAttributeActions 
 *   - getAttributeValuesFromJSON
 *   - getAttributeValues 
 */
public with sharing class JSONAttributeSupportEx implements vlocity_cmt.VlocityOpenInterface {
    public class AttributeCategory {
        @AuraEnabled public Id id;
        @AuraEnabled public String code;
        @AuraEnabled public String name;
        @AuraEnabled public Integer displaySequence;

        public AttributeCategory(Map<String, Object> categoryV2) {
            id = (Id)categoryV2.get('Id');
            code = (String)categoryV2.get('Code__c');
            name = (String)categoryV2.get('Name');
            displaySequence = (Integer)categoryV2.get('displaySequence');
        }

        public AttributeCategory(String code) {
            this.code = code;
        }
    }

    public class AttributeSpecification {
        @AuraEnabled public String code;
        @AuraEnabled public String label;
        @AuraEnabled public Integer displaySequence;
        @AuraEnabled public String valueType;
        // @AuraEnabled public String dataType;
        // @AuraEnabled public String inputType;
        @AuraEnabled public Boolean multiselect;
        @AuraEnabled public Boolean required;
        @AuraEnabled public Boolean readonly;
        @AuraEnabled public Boolean disabled;
        @AuraEnabled public Boolean filterable;
        @AuraEnabled public Boolean hasRules;
        @AuraEnabled public Boolean hidden;
        @AuraEnabled public Boolean cloneable;
        @AuraEnabled public Boolean isNotTranslatable;
        @AuraEnabled public String categoryCode;
        @AuraEnabled public String categoryName;

        @AuraEnabled public List<AttributeSpecValue> values;
        @AuraEnabled public Object defaultValue;

        public AttributeSpecification(Map<String, Object> attrMapV1) {
            // System.debug(JSON.serialize(attrMapV1));

            code = (String)attrMapV1.get('attributeuniquecode__c');
            // dataType = (String)attrMapV1.get('valuedatatype__c'); // TODO...
            // inputType = (String)attrMapV1.get('uidisplaytype__c');
            valueType = ((String)attrMapV1.get('valuedatatype__c')).toLowerCase();
            label = (String)attrMapV1.get('attributedisplayname__c');
            multiselect = (Boolean)attrMapV1.get('multiselect'); // TODO...
            required = (Boolean)attrMapV1.get('isrequired__c');
            readonly = (Boolean)attrMapV1.get('isreadonly__c');
            disabled = (Boolean)attrMapV1.get('disabled');  // TODO...
            filterable = (Boolean)attrMapV1.get('attributefilterable__c');
            hasRules = (Boolean)attrMapV1.get('hasrule__c');
            hidden = (Boolean)attrMapV1.get('ishidden__c');
            cloneable = (Boolean)attrMapV1.get('attributecloneable__c');
            isNotTranslatable = (Boolean)attrMapV1.get('isnottranslatable__c');
            displaySequence = Integer.valueOf(attrMapV1.get('attributedisplaysequence__c'));

            values = new List<AttributeSpecValue>();
            Map<String, Object> attributeRunTimeInfo = (Map<String, Object>)attrMapV1.get('attributeRunTimeInfo');
            defaultValue = attributeRunTimeInfo.get('default');
            if (attributeRunTimeInfo.containsKey('values')) {
                List<Object> valueObjs = (Object[])attributeRunTimeInfo.get('values');
                Object defValObj = attributeRunTimeInfo.get('default');
                for (Object valueObj : valueObjs) {
                    Map<String, Object> valMap = (Map<String, Object>)valueObj;
                    AttributeSpecValue val = new AttributeSpecValue();
                    val.value = valMap.get('value');
                    // val.label = (String)valMap.get('label');
                    val.displaySequence = Integer.valueOf(valMap.get('sequence'));
                    val.defaultSelected = false;
                    if (defValObj != null) {
                        if (defValObj instanceOf Object[]) {
                            for (Object defValObjItem : (Object[])defValObj) {
                                if (String.valueOf(((Map<String, Object>)defValObjItem).get('value')) == String.valueOf(valMap.get('value'))) {
                                    val.defaultSelected = true;
                                }
                            }
                            
                        }
                    }
                    values.add(val);
                }
                
            }
        }

        public AttributeSpecification(Map<String, Object> attrMapV2, Map<String, Object> attrChangeV2, Object defVal) {

            code = (String)attrMapV2.get('code');
            valueType = (String)attrMapV2.get('inputType');
            if (valueType == 'number') {
                valueType = (String)attrMapV2.get('dataType');
                if (valueType == 'percentage') valueType = 'percent';
            } else if (valueType == 'dropdown') {
                valueType = 'picklist';
            }

            // System.debug('attrMapV2: ' + JSON.serialize(attrMapV2));
            // System.debug('attrChangeV2: ' + JSON.serialize(attrChangeV2));

            if (attrChangeV2 != null) {
                attrMapV2.putAll(attrChangeV2); // Merge
            }

            label = (String)attrMapV2.get('label');
            multiselect = (Boolean)attrMapV2.get('multiselect');
            required = (Boolean)attrMapV2.get('required');
            readonly = (Boolean)attrMapV2.get('readonly');
            disabled = (Boolean)attrMapV2.get('disabled');
            filterable = (Boolean)attrMapV2.get('filterable');
            hasRules = (Boolean)attrMapV2.get('hasRules');
            hidden = (Boolean)attrMapV2.get('hidden');
            cloneable = (Boolean)attrMapV2.get('cloneable');
            isNotTranslatable = (Boolean)attrMapV2.get('isNotTranslatable');
            displaySequence = Integer.valueOf(attrMapV2.get('displaySequence'));

            values = new List<AttributeSpecValue>();
            defaultValue = defVal;
            List<Object> valueObjs = (Object[])attrMapV2.get('values');
            for (Object valueObj : valueObjs) {
                Map<String, Object> valMap = (Map<String, Object>)valueObj;
                if (valMap.containsKey('value')) {
                    AttributeSpecValue val = new AttributeSpecValue();
                    val.value = valMap.get('value');
                    val.label = (String)valMap.get('label');
                    val.displaySequence = Integer.valueOf(valMap.get('displaySequence'));
                    if (String.valueOf(val.value) == String.valueOf(defaultValue)) {
                        val.defaultSelected = true;
                    } else {
                        val.defaultSelected = false;
                    }
                    values.add(val);
                }
            }
        }
    }

    public class AttributeSpecValue {
        @AuraEnabled public Object value;
        @AuraEnabled public String label;
        @AuraEnabled public Integer displaySequence;
        @AuraEnabled public Boolean defaultSelected;
    }

    public class AttributeMetadata {
        @AuraEnabled public Map<String, AttributeCategory> categories;
        @AuraEnabled public Map<String, AttributeSpecification> attributes;
        
        public AttributeMetadata() {
            categories = new Map<String, AttributeCategory>();
            attributes = new Map<String, AttributeSpecification>();
        }
    }

    public class JSONAttribute {
        @AuraEnabled public AttributeMetadata metadata { get; set; }
        @AuraEnabled public Map<String, Object> values { get; set; }
    }

    public static Map<String, Object> getAttributeValuesFromJSON(Id xLIId) {
        SObject xLI = getLineItem(xLIId);

        return getAttributeValuesFromJSON(xLI);
    }

    public static Map<String, Object> getAttributeValuesFromJSON(SObject xLI) {
        vlocity_cmt.JSONAttributeSupport jsonSupport = new vlocity_cmt.JSONAttributeSupport();
        // Read the old speed
        Map<String, object> inputMap;
        Map<String, object> outputMap = new Map<String, object>(); 
        Map<String, object> optionsMap = new Map<String, object>();

        Boolean v2Attribute = isAttributeV2(xLI.getSObjectType());
        if (v2Attribute) {
            String values = (String)xLI.get('vlocity_cmt__AttributeSelectedValues__c');
            if (values == null) return new Map<String, Object>();
            else return (Map<String, Object>)JSON.deserializeUntyped(values);

        } else {
            Map<String, Object> values = new Map<String, Object>();

            Map<String, Object> jsonAttribute = (Map<String, Object>)JSON.deserializeUntyped((String)xLI.get('vlocity_cmt__JSONAttribute__c'));
            for (Object catObj : jsonAttribute.values()) {
                for (Object attrObj : (List<Object>)catObj) {
                    Map<String, Object> attrib = (Map<String, Object>)attrObj;
                    Map<String, Object> attributeRunTimeInfo = (Map<String, Object>)attrib.get('attributeRunTimeInfo');
                    String code = (String)attrib.get('attributeuniquecode__c');
                    if ((String)attributeRunTimeInfo.get('dataType') == 'Picklist') {
                        Map<String, Object> selectedItem = (Map<String, Object>)attributeRunTimeInfo.get('selectedItem');
                        if (selectedItem != null) {
                            values.put(code, selectedItem.get('value'));
                        }
                    } else {
                        values.put(code, attributeRunTimeInfo.get('value'));
                    }
                }
            }

            System.debug('values: ' + JSON.serialize(values));
            return values;
            // inputMap = new Map<String, object>{
            //     'UseDisplayTextForValues' => false,
            //     'JSONString' => xLI.get('vlocity_cmt__JSONAttribute__c')
            // }; 
            // System.debug(JSON.serialize(inputMap));
            // jsonSupport.invokeMethod('getAttributeValuesFromJSON', inputMap, outputMap, optionsMap); 
            // System.debug(JSON.serialize(outputMap));
            // return (Map<String, Object>)outputMap.get('attributeCodeToValue');
        }


        // return attrVals;
    }

    public static String setAttributeValuesByJSON(Id xLIId, Map<String, Object> attrVals) {
        SObject xLI = getLineItem(xLIId);

        return setAttributeValuesByJSON(xLI, attrVals);
    }

    public static String setAttributeValuesByJSON(SObject xLI, Map<String, Object> attrVals) {
        JSONAttributeSupportEx jsEx = new JSONAttributeSupportEx();
        Boolean v2Attribute = isAttributeV2(xLI.getSObjectType());

        String productRefName;
        if (xLI.getSObjectType() == vlocity_cmt__InventoryItem__c.SObjectType) productRefName = 'vlocity_cmt__ProductId__r';
        else if (xLI.getSObjectType() == vlocity_cmt__FulfilmentRequestLine__c.SObjectType) productRefName = 'vlocity_cmt__Product2Id__r';
        else productRefName = 'Product2';
        Product2 p = (Product2)xLI.getSObject(productRefName);
        if (v2Attribute) {
            return jsEx.setJSONAttributesV2((String)xLI.get('vlocity_cmt__AttributeSelectedValues__c'), (String)xLI.get('vlocity_cmt__AttributeMetadataChanges__c'), p.vlocity_cmt__AttributeMetadata__c, attrVals);
        } else {
            return jsEx.setJSONAttributesV1((String)xLI.get('vlocity_cmt__JSONAttribute__c'), p.vlocity_cmt__JSONAttribute__c, attrVals);
        }
    }

    @AuraEnabled(cacheable=true)
    public static JSONAttribute getJSONAttribute(Id recordId) {
        JSONAttribute jsonAttrib = new JSONAttribute();

        JSONAttributeSupportEx helper = new JSONAttributeSupportEx();
        SObject xLI = getLineItem(recordId);
        jsonAttrib.metadata = helper.getAttributeMetadata(xLI);
        jsonAttrib.values = getAttributeValuesFromJSON(xLI);

        System.debug(JSON.serialize(jsonAttrib));

        return jsonAttrib;
    }

    @AuraEnabled
    public static Map<String, Object> getAttributeValues(Id recordId) {
        SObject xLI = getLineItem(recordId);
        return getAttributeValuesFromJSON(xLI);
    }

    @AuraEnabled
    public static void setAttributeValues(Id recordId, Map<String, Object> values) {
        System.debug(recordId);
        System.debug(JSON.serialize(values));
        SObject xLI = getLineItem(recordId);

        String modifiedJSON = setAttributeValuesByJSON(xLI, values);

        Boolean v2Attribute = isAttributeV2(xLI.getSObjectType());
        if (v2Attribute) {
            xLI.put('vlocity_cmt__AttributeSelectedValues__c', modifiedJSON);
        } else {
            xLI.put('vlocity_cmt__JSONAttribute__c', modifiedJSON);
        }
        update xLI;
    }    

    public Boolean InvokeMethod(String methodName, Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {
        return true;
    }
    
    private static Boolean isAttributeV2(SObjectType objectType) {
        Boolean v2Attribute = vlocity_cmt.VlocityFeatureService.isV2AttributeModelEnabled();
        if (v2Attribute && (objectType == vlocity_cmt__InventoryItem__c.SObjectType || objectType == vlocity_cmt__FulfilmentRequestLine__c.SObjectType)) {
            v2Attribute = false;
        }

        return v2Attribute;
    }

    private static SObject getLineItem(Id xLIId) {
        SObjectType objectType = xLIId.getSobjectType();
        DescribeSObjectResult objectDesc = objectType.getDescribe();

        
        String query, productRefName;
        if (objectType == vlocity_cmt__InventoryItem__c.SObjectType) productRefName = 'vlocity_cmt__ProductId__r';
        else if (objectType == vlocity_cmt__FulfilmentRequestLine__c.SObjectType) productRefName = 'vlocity_cmt__Product2Id__r';
        else productRefName = 'Product2';

        if (isAttributeV2(objectType)) {
            query = String.format('SELECT Id, {0}.vlocity_cmt__JSONAttribute__c, {0}.vlocity_cmt__AttributeMetadata__c, {0}.vlocity_cmt__AttributeDefaultValues__c, vlocity_cmt__JSONAttribute__c, vlocity_cmt__AttributeMetadataChanges__c, vlocity_cmt__AttributeSelectedValues__c FROM {1} WHERE Id=:xLIId', new List<String> {
                productRefName,
                objectDesc.getName()
            });
        } else {
            query = String.format('SELECT Id, {0}.vlocity_cmt__JSONAttribute__c, vlocity_cmt__JSONAttribute__c FROM {1} WHERE Id=:xLIId', new List<String> {
                productRefName,
                objectDesc.getName()
            });
        }
        System.debug('query: ' + query);
        SObject xLI = Database.query(query);

        return xLI;
    } 

    public AttributeMetadata getAttributeMetadata(Id xLIId) {
        SObject xLI = getLineItem(xLIId);

        return getAttributeMetadata(xLI);
    }

    public AttributeMetadata getAttributeMetadata(SObject xLI) {
        Boolean v2Attribute = isAttributeV2(xLI.getSObjectType()); // vlocity_cmt.VlocityFeatureService.isV2AttributeModelEnabled();

        if (v2Attribute) {
            String productRefName;
            if (xLI.getSObjectType() == vlocity_cmt__InventoryItem__c.SObjectType) productRefName = 'vlocity_cmt__ProductId__r';
            else if (xLI.getSObjectType() == vlocity_cmt__FulfilmentRequestLine__c.SObjectType) productRefName = 'vlocity_cmt__Product2Id__r';
            else productRefName = 'Product2';

            Product2 p2 = (Product2)xLI.getSObject(productRefName);
            return getAttributeMetadataV2(p2.vlocity_cmt__AttributeMetadata__c, (String)xLI.get('vlocity_cmt__AttributeMetadataChanges__c'), p2.vlocity_cmt__AttributeDefaultValues__c);
        } else {
            return getAttributeMetadataV1((String)xLI.get('vlocity_cmt__JSONAttribute__c'));
        }
    }

    public AttributeMetadata getAttributeMetadataV1(String jsonAttribute) {
        System.debug(jsonAttribute);
        
        AttributeMetadata mdAttribute = new AttributeMetadata();
        Map<String, Object> categories = (Map<String, Object>)JSON.deserializeUntyped(jsonAttribute);
        for (String categoryCode : categories.keySet()) {
            AttributeCategory category = new AttributeCategory(categoryCode);

            Object[] attrList = (Object[])categories.get(categoryCode);
            for (Object attr : attrList) {
                Map<String, Object> attrMapV1 = (Map<String, Object>)attr;
                if (String.isEmpty(category.name)) {
                    category.name = (String)attrMapV1.get('categoryname__c');
                }

                AttributeSpecification attrSpec = new AttributeSpecification(attrMapV1);
                attrSpec.categoryCode = categoryCode;
                attrSpec.categoryName = category.name;
                mdAttribute.attributes.put(attrSpec.code, attrSpec);
            }


            mdAttribute.categories.put(category.code, category);
        }
        return mdAttribute;
    }

    public AttributeMetadata getAttributeMetadataV2(String jsonAttributeMetadata, String jsonAttributeMetadataChanges, String jsonAttributeDefaultValues) {
        AttributeMetadata mdAttribute = new AttributeMetadata();
        List<Object> categories = (Object[])((Map<String, Object>)JSON.deserializeUntyped(jsonAttributeMetadata)).get('records');
        Map<String, Object> attrChanges = new Map<String, Object>();
        if (String.isNotBlank(jsonAttributeMetadataChanges)) {
            attrChanges = (Map<String, Object>)JSON.deserializeUntyped(jsonAttributeMetadataChanges);
        }

        Map<String, Object> attrDefVals = new Map<String, Object>();
        if (String.isNotBlank(jsonAttributeDefaultValues)) {
            attrDefVals = (Map<String, Object>)JSON.deserializeUntyped(jsonAttributeDefaultValues);
        }

        for (Object category : categories) {
            AttributeCategory attrCategory = new AttributeCategory((Map<String, Object>)category);
            Map<String, Object> productAttributes = (Map<String, Object>)((Map<String, Object>)category).get('productAttributes');
            List<Object> records = (Object[])productAttributes.get('records');
            for (Object record : records){
                Map<String, Object> attrMapV2 = (Map<String, Object>)record;
                String attrCode = (String)attrMapV2.get('code');
                Map<String, Object> attrChangeV2 = (Map<String, Object>)attrChanges.get(attrCode);
                Object attrDefVal = attrDefVals.get(attrCode);
                
                // System.debug('attributeCode: ' + attrCode);
                // System.debug(json.serialize(productAttributes));
                // System.debug(json.serialize(attrChanges));
                // System.debug(json.serialize(jsonAttributeDefaultValues));

                AttributeSpecification attrSpec = new AttributeSpecification(attrMapV2, attrChangeV2, attrDefVal);
                attrSpec.categoryCode = attrCategory.code;
                attrSpec.categoryName = attrCategory.name;
                mdAttribute.attributes.put(attrSpec.code, attrSpec);
            }
            mdAttribute.categories.put(attrCategory.code, attrCategory);
        }

        return mdAttribute;
    }

    public String setJSONAttributesV1(String runtimeJSON, String originalJSON, Map<String, Object> attrVals) {
        System.debug('attrVals: ' + JSON.serialize(attrVals));
        // Map<String, Object> values = new Map<String, Object>();

        Map<String, Object> jsonAttribute = (Map<String, Object>)JSON.deserializeUntyped(runtimeJSON);
        for (Object catObj : jsonAttribute.values()) {
            for (Object attrObj : (List<Object>)catObj) {
                Map<String, Object> attrib = (Map<String, Object>)attrObj;
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
                        // if (selectedItem != null) {
                        //     values.put(code, selectedItem.get('value'));
                        // }
                    } else {
                        attributeRunTimeInfo.put('value', val);
                    }
                }


            }
        }

        // List<vlocity_cmt.JSONAttributeSupport.JSONAttributeActionRequest> actionRequestsList = new List<vlocity_cmt.JSONAttributeSupport.JSONAttributeActionRequest>();
        // for (String attrCode : attrVals.keySet()) {
        //     Object attrVal = attrVals.get(attrCode);

        //     actionRequestsList.add(new vlocity_cmt.JSONAttributeSupport.JSONAttributeActionRequest(
        //         attrCode, 
        //         vlocity_cmt.JSONAttributeSupport.ActionType.ASSIGN, 
        //         attrVal)
        //     );
        // }

        // vlocity_cmt.JSONAttributeSupport jsonSupport = new vlocity_cmt.JSONAttributeSupport();
        // Map<String, Object> myInputMap = new Map<String, Object> {
        //     'objectSO' => null,
        //     'runTimeAttributesJSON' => runtimeJSON,
        //     'originalAttributesJSON' => originalJSON,
        //     'JSONAttributeActionRequestList' => actionRequestsList
        // };
        // Map<String, Object> myOutputMap = new Map<String, Object>();
        // Map<String, Object> myOptionsMap = new Map<String, Object>();

        // jsonSupport.invokeMethod('applyAttributeActions', myInputMap, myOutputMap, myOptionsMap);
        // String modifiedJSON = (String)myOutputMap.get('modifiedJSON');
        String modifiedJSON = JSON.serialize(jsonAttribute);
        System.debug('modifiedJSON: ' + (modifiedJSON));

        return modifiedJSON;
    }  

    public String setJSONAttributesV2(String runtimeValueJSON, String runtimeMetadataJSON, String originalAttributesJSON, Map<String, Object> attrVals) {
        Map<String, Object> values = new Map<String, Object>();
        if (runtimeValueJSON != null) {
            values = (Map<String, Object>)JSON.deserializeUntyped(runtimeValueJSON);
        }
        for (String code : attrVals.keySet()) {
            Object val = attrVals.get(code);
            if (val == null || String.valueOf(val) == '') values.remove(code);
            else values.put(code, val);
        }
        // values.putAll(attrVals);

        return JSON.serialize(values);
    }  
}