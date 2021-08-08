/**
 * @description extension of the OOTB JSONAttributeSupport class
 *   - applyAttributeActions 
 *   - getAttributeValuesFromJSON
 *   - getAttributeValues 
 */
public with sharing class JSONAttributeSupportEx implements vlocity_cmt.VlocityOpenInterface {
    public class AttributeCategory {
        public Id id;
        public String code;
        public String name;
        public Integer displaySequence;

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
        public String code;
        public String label;
        public Integer displaySequence;
        public String dataType;
        public String inputType;
        public Boolean multiselect;
        public Boolean required;
        public Boolean readonly;
        public Boolean disabled;
        public Boolean filterable;
        public Boolean hasRules;
        public Boolean hidden;
        public Boolean cloneable;
        public Boolean isNotTranslatable;

        public List<AttributeSpecValue> values;
        public Object defaultValue;

        public AttributeSpecification(Map<String, Object> attrMapV1) {
            System.debug(JSON.serialize(attrMapV1));

            code = (String)attrMapV1.get('attributeuniquecode__c');
            dataType = (String)attrMapV1.get('valuedatatype__c'); // TODO...
            inputType = (String)attrMapV1.get('uidisplaytype__c');
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
            dataType = (String)attrMapV2.get('dataType');
            inputType = (String)attrMapV2.get('inputType');
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
                    val.displaySequence = Integer.valueOf(valMap.get('displaySequence'));
                    if (String.valueOf(val.value) == String.valueOf(defaultValue)) {
                        val.defaultSelected = true;
                    } else {
                        val.defaultSelected = false;
                    }
                    // val.defaultSelected = (Boolean)valMap.get('defaultSelected');

                    values.add(val);
                }
            }
        }
    }

    public class AttributeSpecValue {
        public Object value;
        public Integer displaySequence;
        public Boolean defaultSelected;
    }

    public class AttributeMetadata {
        public Map<String, AttributeCategory> categories;
        public Map<String, AttributeSpecification> attributes;
        
        public AttributeMetadata() {
            categories = new Map<String, AttributeCategory>();
            attributes = new Map<String, AttributeSpecification>();
        }
    }


    public Boolean InvokeMethod(String methodName, Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {
        return true;
    }

    public AttributeMetadata getAttributeMetadata(Id xLIId) {
        SObjectType objectType = xLIId.getSobjectType();
        DescribeSObjectResult objectDesc = objectType.getDescribe();

        String query = 'SELECT Id, Product2.vlocity_cmt__JSONAttribute__c, Product2.vlocity_cmt__AttributeMetadata__c, Product2.vlocity_cmt__AttributeDefaultValues__c, vlocity_cmt__JSONAttribute__c, vlocity_cmt__AttributeMetadataChanges__c, vlocity_cmt__AttributeSelectedValues__c FROM ' + objectDesc.getName() + ' WHERE Id=:xLIId';
        System.debug('query: ' + query);
        SObject xLI = Database.query(query);
        
        return getAttributeMetadata(xLI);
    }

    public AttributeMetadata getAttributeMetadata(SObject xLI) {
        Boolean v2Attribute = vlocity_cmt.VlocityFeatureService.isV2AttributeModelEnabled();

        if (v2Attribute) {
            Product2 p2 = (Product2)xLI.getSObject('Product2');
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
                
                System.debug(json.serialize(productAttributes));
                System.debug(json.serialize(attrChanges));
                System.debug(json.serialize(jsonAttributeDefaultValues));

                AttributeSpecification attrSpec = new AttributeSpecification(attrMapV2, attrChangeV2, attrDefVal);
                mdAttribute.attributes.put(attrSpec.code, attrSpec);
            }
            mdAttribute.categories.put(attrCategory.code, attrCategory);
        }

        return mdAttribute;
    }
}