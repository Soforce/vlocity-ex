/**
 * @description extension of the OOTB JSONAttributeSupport class
 *   - applyAttributeActions 
 *   - getJSONAttributeValues
 *   - getAttributeValues 
 */
public with sharing class vJsonAttributeViewerController {
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
                    // val.label = val.value; // v1 does not have a label?
                    val.label = (String)valMap.get('displayText');
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

    
    public static String getProduct2ReferenceName(SObjectType objectType) {
        if (objectType == vlocity_cmt__InventoryItem__c.SObjectType) return 'vlocity_cmt__ProductId__r';
        else if (objectType == vlocity_cmt__FulfilmentRequestLine__c.SObjectType) return 'vlocity_cmt__Product2Id__r';
        else return 'Product2';
    }

    public static Map<String, Object> getJSONAttributeValues(Id xLIId) {
        SObject xLI = getLineItem(xLIId);

        return getJSONAttributeValues(xLI);
    }

    public static Map<String, Object> getJSONAttributeValues(SObject xLI) {
        String jsonAttribute;
        if (vHelper.isV2Attribute(xLI.getSObjectType())) {
            jsonAttribute = (String)xLI.get('vlocity_cmt__AttributeSelectedValues__c');
        } else {
            // v1
            jsonAttribute = (String)xLI.get('vlocity_cmt__JSONAttribute__c');
        }

        return vHelper.getJSONAttributeValues(jsonAttribute);
    }

    public static String setJSONAttributeValues(SObject xLI, Map<String, Object> attrVals) {
        String jsonAttribute;
        if (vHelper.isV2Attribute(xLI.getSObjectType())) {
            jsonAttribute = (String)xLI.get('vlocity_cmt__AttributeSelectedValues__c');
        } else {
            // v1
            jsonAttribute = (String)xLI.get('vlocity_cmt__JSONAttribute__c');
        }

        return vHelper.setJSONAttributes(jsonAttribute, attrVals);
    }


    @AuraEnabled(cacheable=true)
    public static JSONAttribute getJSONAttribute(Id recordId) {
        JSONAttribute jsonAttrib = new JSONAttribute();

        SObject xLI = getLineItem(recordId);
        jsonAttrib.metadata = getAttributeMetadata(xLI);
        jsonAttrib.values = getJSONAttributeValues(xLI);

        // System.debug(JSON.serialize(jsonAttrib));

        return jsonAttrib;
    }

    @AuraEnabled
    public static Map<String, Object> getAttributeValues(Id recordId) {
        SObject xLI = getLineItem(recordId);
        return getJSONAttributeValues(xLI);
    }

    @AuraEnabled
    public static void setAttributeValues(Id recordId, Map<String, Object> values) {
        // System.debug(recordId);
        // System.debug(JSON.serialize(values));
        SObject xLI = getLineItem(recordId);

        String modifiedJSON = setJSONAttributeValues(xLI, values);

        if (vHelper.isV2Attribute(xLI.getSObjectType())) {
            xLI.put('vlocity_cmt__AttributeSelectedValues__c', modifiedJSON);
        } else {
            xLI.put('vlocity_cmt__JSONAttribute__c', modifiedJSON);
        }

        if (!Test.isRunningTest())
            update xLI;
    }    

    private static SObject getLineItem(Id xLIId) {
        SObjectType objectType = xLIId.getSobjectType();
        DescribeSObjectResult objectDesc = objectType.getDescribe();

        
        String productRefName = getProduct2ReferenceName(objectType);
        String query;
        if (vHelper.isV2Attribute(objectType)) {
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
        // System.debug('query: ' + query);
        SObject xLI;
        if (Test.isRunningTest()) {
            xLI = vJsonAttributeViewerControllerTest.getLineItemMock(xLIId);
        } else {
            xLI = Database.query(query);
        }

        // System.debug(xLI);

        return xLI;
    } 


    public static AttributeMetadata getAttributeMetadata(SObject xLI) {
        // System.debug(xLI.Id);
        if (vHelper.isV2Attribute(xLI.getSObjectType())) {
            String productRefName = getProduct2ReferenceName(xLI.getSObjectType());
            Product2 p2 = (Product2)xLI.getSObject(productRefName);
            return getAttributeMetadataV2(p2.vlocity_cmt__AttributeMetadata__c, (String)xLI.get('vlocity_cmt__AttributeMetadataChanges__c'), p2.vlocity_cmt__AttributeDefaultValues__c);
        } else {
            return getAttributeMetadataV1((String)xLI.get('vlocity_cmt__JSONAttribute__c'));
        }
    }

    public static AttributeMetadata getAttributeMetadataV1(String jsonAttribute) {
        // System.debug(jsonAttribute);
        
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

    public static AttributeMetadata getAttributeMetadataV2(String jsonAttributeMetadata, String jsonAttributeMetadataChanges, String jsonAttributeDefaultValues) {
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
}