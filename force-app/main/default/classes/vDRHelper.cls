global with sharing class vDRHelper implements vlocity_cmt.VlocityOpenInterface {
    public class vDRHelperException extends Exception {}

    global Boolean invokeMethod(String methodName, Map<String, Object> inputs, Map<String, Object> output, Map<String, Object> options){
        if (methodName == 'ExecuteAggregateQuery') {
            List<Object> args = (List<Object>)inputs.get('arguments');
            AggregateResult[] aggregateResults = executeAggregateQuery(args);

            // Return only if there's aggregated result
            if (aggregateResults.size() > 0) output.put('result', aggregateResults);
        } else if (methodName == 'GetJsonAttributes') {
            LineItemHelper helper = new LineItemHelper();
            return helper.invokeMethod('getAttributeValues', inputs, output, options);
        } else if (methodName == 'ConvertXLIToStructure') {
            LineItemHelper helper = new LineItemHelper();
            return helper.invokeMethod('ToStructure', inputs, output, options);
        }
            
        return true;
    }

    /**
     * 
     */
    public static AggregateResult[] executeAggregateQuery(Object[] args) {
        String query = (String)args.remove(0);
        if (args.size() > 0) {
            query = String.format(query, args);
        } 

        return Database.query(query);
    }

    /**
     * 
     */
    global virtual class LineItemHelper implements vlocity_cmt.VlocityOpenInterface {
        global Boolean invokeMethod(String methodName, Map<String, Object> inputs, Map<String, Object> output, Map<String, Object> options){
            try {
                if (methodName == 'getAttributeValues') {
                    List<Map<String, Object>> attributeValues = new List<Map<String, Object>>();

                    Boolean skipEmptyValue = false;
                    List<Object> args = (List<Object>)inputs.get('arguments');
                    if (!vlocity_cmt.VlocityFeatureService.isV2AttributeModelEnabled()) {
                        String jsonAttribute = (String)args[0];
                        if (args.size() > 1) skipEmptyValue = Boolean.valueOf(args[1]);

                        Map<String, Object> attributeObj = (Map<String, Object>)JSON.deserializeUntyped(jsonAttribute);
                        for (String cateName : attributeObj.keySet()) {
                            List<Object> categoryObj = (List<Object>)attributeObj.get(cateName);
                            // v1
                            for (Object itemObj : categoryObj) {
                                Map<String, Object> attribute = new Map<String, Object>();

                                Map<String, Object> attribObj = (Map<String, Object>)itemObj;
                                Map<String, Object> attributeRunTimeInfo = (Map<String, Object>)attribObj.get('attributeRunTimeInfo');
                                String attributeCode = (String)attribObj.get('attributeuniquecode__c');
                                String attributeName = (String)attribObj.get('');
                                Integer attributeDisplaySequence = (Integer)attribObj.get('');
                                Object attributeValue;
                                if ((String)attributeRunTimeInfo.get('dataType') == 'Picklist') {
                                    Map<String, Object> selectedItem = (Map<String, Object>)attributeRunTimeInfo.get('selectedItem');
                                    if (selectedItem != null) {
                                        attributeValue = selectedItem.get('value');
                                    }
                                } else {
                                    attributeValue = attributeRunTimeInfo.get('value');
                                }

                                if (!skipEmptyValue || (attributeValue != null && String.isNotEmpty(String.valueOf(attributeValue)))) {
                                    attributeValues.add(new Map<String, Object> {
                                        'code' => attributeCode,
                                        'name' => attributeName,
                                        'value' => attributeValue,
                                        'sequence' => attributeDisplaySequence
                                    });
                                }
                            } 
                        }                        
                    } else {
                        String jsonSelectedValues = (String)args[0];
                        String jsonAttributeMetadata = (String)args[1];
                        Map<String, Object> selectedValues = (Map<String, Object>)JSON.deserializeUntyped((String)args[0]);
                        Map<String, Object> metadata = (Map<String, Object>)JSON.deserializeUntyped((String)args[1]);
                        if (args.size() > 2) skipEmptyValue = Boolean.valueOf(args[2]);

                        Map<String, String> attribNames = new Map<String, String>();
                        for (Object categoryRecord : (Object[])metadata.get('records')) {
                            Map<String, Object> pdAttributes = (Map<String, Object>)((Map<String, Object>)categoryRecord).get('productAttributes');
                            for (Object attribRecord : (Object[])pdAttributes.get('records')) {
                                Map<String, Object> attribDef = (Map<String, Object>)attribRecord;
                                String attributeCode = (String)attribDef.get('code');
                                String attributeName = (String)attribDef.get('label');
                                Integer attributeDisplaySequence = Integer.valueOf(attribDef.get('displaySequence'));
                                Object attributeValue = selectedValues.get(attributeCode);

                                if (!skipEmptyValue || (attributeValue != null && String.isNotEmpty(String.valueOf(attributeValue)))) {
                                    attributeValues.add(new Map<String, Object> {
                                        'code' => attributeCode,
                                        'name' => attributeName,
                                        'value' => attributeValue,
                                        'sequence' => attributeDisplaySequence
                                    });
                                }
                            }
                        }
                    }
                    // Sort by DisplaySequence (OOTB is sorted by category and sequence already, no extra sorting here)
                    if (attributeValues.size() > 0) output.put('result', attributeValues);
                } else if (methodName == 'toStructure') {

                }
                return true;
            } catch (Exception ex) {
                vLogger.write(ex);
                return false;
            } finally {
                
            }
        }
    }

    /**
     * @description Convert JSON from flat to structure based on the attribute name.
     */
    global virtual class JSONT implements vlocity_cmt.VlocityOpenInterface {
        /**
         * @description interface implementation
         */
        global Boolean invokeMethod(String methodName, Map<String, Object> inputs, Map<String, Object> output, Map<String, Object> options){
            if (methodName == 'toStructure') {
                List<Object> arguments = (List<Object>)inputs.get('arguments');
                Object flatJson = arguments[0];
                Boolean isMap = (Boolean)arguments[1];
                String nameField;
                String valueField;
                if (!isMap) {
                    nameField = (String)arguments[2];
                    valueField = (String)arguments[3];
                }
                //
                Map<String, Object> structureJson = convertJsonStructure(flatJson, nameField, valueField);
                //
                structureJson = onJsonConverted(structureJson);

                output.put('result', structureJson);
            }

            return true;
        }

        /**
         * @description virtual method to be overriden by the child class for the given business logic
         */
        public virtual Map<String, Object> onJsonConverted(Map<String, Object> structureJson) {
            return structureJson;
        }

        /**
         * @description
         */
        public Map<String, Object> convertJsonStructure(Object flatJSON, String nameField, String valueField) {
            Map<String, Object> structureJSON = new Map<String, Object>();
            if (flatJSON instanceOf Map<String, Object>) {
                // Name & Value format
                for (String fullName : ((Map<String, Object>)flatJSON).keySet()) {
                    Object value = ((Map<String, Object>)flatJSON).get(fullName);
                    convertJsonStructure(fullName, value, structureJSON); 
                }
            } else if (flatJSON instanceOf List<Object>) {
                // JSON object format
                for (Object jsonObj : (List<Object>)flatJSON) {
                    String fullName = (String)((Map<String, Object>)jsonObj).get(nameField);
                    Object value = ((Map<String, Object>)jsonObj).get(valueField);
                    convertJsonStructure(fullName, value, structureJSON);
                }
            } else {
                throw new vDRHelperException('Invalid flatJSON object to convert.');
            }
    
            return structureJSON;
        }
    
        
        /**
         * @description
         */
        protected void convertJsonStructure(String fullName, Object value, Map<String, Object> structureJSON) {
            String[] names = fullName.split('\\.');
            if (names.size() == 1) {
                // No DOT notation in the fullName
                structureJSON.put(fullName, value);
            } else {
                Object parentJSON = structureJSON;
                for (Integer i = 0; i < names.size(); i++) {
                    String myName = names[i];
                    if (i == names.size() - 1) {
                        // Leaf node -> name & value 
                        ((Map<String, Object>)parentJSON).put(myName, value);
                    } else {
                        // Branch node -> JSON object
                        String[] myNames = myName.split('\\[');
                        if (myNames.size() == 1) {
                            // Map JSON node
                            Map<String, Object> myJsonMap = (Map<String, Object>)((Map<String, Object>)parentJSON).get(myName);
                            if (myJsonMap == null) {
                                myJsonMap = new Map<String, Object>();
                                ((Map<String, Object>)parentJSON).put(myName, myJsonMap);
                            }
                            parentJSON = myJsonMap;
                        } else if (myNames.size() == 2) {
                            String myArrayName = myNames[0];
                            String myArrayKey = myNames[1].substring(0, myNames[1].length() - 1);
                            Object[] myJsonArray = (Object[])((Map<String, Object>)parentJSON).get(myArrayName);
                            if (myJsonArray == null) {
                                myJsonArray = new List<Object>();
                                ((Map<String, Object>)parentJSON).put(myArrayName, myJsonArray);
                            }
                            Map<String, Object> myJsonMap;
                            for (Object myJsonItem : myJsonArray) {
                                if ((String)((Map<String, Object>)myJsonItem).get('@arrayKey') == myArrayKey) {
                                    myJsonMap = (Map<String, Object>)myJsonItem;
                                    break;
                                }
                            }
                            if (myJsonMap == null) {
                                myJsonMap = new Map<String, Object> {
                                    '@arrayKey' => myArrayKey
                                };
                                myJsonArray.add(myJsonMap);
                            }
                            parentJSON = myJsonMap;
                        } else {
                            throw new vDRHelperException();
                        }
                    }
                    
                }
            }
        }        
    }



}
