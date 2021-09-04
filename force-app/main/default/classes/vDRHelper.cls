global with sharing class vDRHelper implements vlocity_cmt.VlocityOpenInterface {
    public class vDRHelperException extends Exception {}

    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options){
        if (methodName == 'QueryAggregate') {
            return queryAggregate(input, output, options);
        } else if (methodName == 'QueryEx') {
            return queryEx(input, output, options);
        } else if (methodName == 'GetLineItemAttributes') {
            LineItemHelper helper = new LineItemHelper();
            return helper.invokeMethod('getAttributeValues', input, output, options);
        } else if (methodName == 'ToProductHierarchy') {
            LineItemHelper helper = new LineItemHelper();
            return helper.invokeMethod('ToHierarchy', input, output, options);
        } else if (methodName == 'ToStructureJson') {
            JSLTHelper helper = new JSLTHelper();
            return helper.invokeMethod('toStructure', input, output, options);
        }
            
        return true;
    }

    /**
     * 
     */
    public static Boolean queryAggregate(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        Object[] args = (List<Object>)input.get('arguments');
        String query = (String)args.remove(0);
        if (args.size() > 0) {
            query = String.format(query, args);
        } 

        AggregateResult[] aggregateResults = Database.query(query);
        if (aggregateResults.size() > 0) {
            output.put('result', aggregateResults);
            return true;
        } else {
            return false;
        }
    }

    /**
     * 
     */
    public static Boolean queryEx(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        List<Object> args = (List<Object>)input.get('arguments');
        String query = (String)args.remove(0);
        if (args.size() > 0) {
            query = String.format(query, args);
        } 

        List<SObject> results = Database.query(query);

        if (results.size() > 0) {
            output.put('result', results);
            return true;
        } else {
            return false;
        }
    }    

    global abstract class BaseHelper implements vlocity_cmt.VlocityOpenInterface {
        /**
         * 
         */
        private void traverseJson(String parentJpath, Object jsonObject) {
            if (parentJpath == null) parentJpath = '$';

            if (jsonObject instanceOf Map<String, Object>) {
                Map<String, Object> jsonMapObject = (Map<String, Object>)jsonObject;
                for (String nodeName : jsonMapObject.keySet()) {
                    String jPath = parentJpath + '.' + nodeName;
                    Object jValue = jsonMapObject.get(nodeName);
                    Object processedJValue = processJsonNode(jPath, jValue);
                    if (processedJValue != jValue) {
                        // Use new value to replace the old and stop traversing the node
                        jsonMapObject.put(nodeName, processedJValue);
                    } else {
                        traverseJson(jPath, jValue);
                    }
                }

            } else if (jsonObject instanceOf List<Object>) {
                List<Object> jsonArrayObject = (List<Object>)jsonObject;
                for (Integer i = 0; i < jsonArrayObject.size(); i++) {
                    String jPath = parentJpath + '[' + String.valueOf(i) + ']';
                    Object jValue = jsonArrayObject[i];

                    Object processedJValue = processJsonNode(jPath, jValue);

                    if (processedJValue != jValue) {
                        // Use new value to replace the old and stop traversing the node
                        jsonArrayObject[i] = processedJValue;
                    } else {
                        traverseJson(jPath, jValue);
                    }
                }
            } else {
                // Object processedJValue = processJsonNode(jsonObject, parentJpath, jsonObject);

                // System.debug(parentJpath + ':' + jsonObject);
            }
        }

        public virtual Boolean skipProcessJsonNode() {
            return true;
        }

        public virtual Object processJsonNode(String parentJpath, Object jsonObject) {
            return jsonObject;
        }

        global virtual Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options){
            Object result = invoke(methodName, input);

            if (!skipProcessJsonNode()) {
                traverseJson(null, result);
            }

            output.put('result', result);

            return true;
        }

        global abstract Object invoke(String methodName, Map<String, Object> input);
    }

    /**
     * 
     */
    global virtual class LineItemHelper extends BaseHelper {
        global override Object invoke(String methodName, Map<String, Object> input){
            try {
                if (methodName == 'getAttributeValues') {
                    List<Map<String, Object>> attributeValues = new List<Map<String, Object>>();

                    Boolean skipEmptyValue = false;
                    List<Object> args = (List<Object>)input.get('arguments');
                    if (!vHelper.isV2Attribute(null)) {
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
                                String attributeName = (String)attribObj.get('attributedisplayname__c');
                                Integer attributeDisplaySequence = String.isEmpty((String)attribObj.get('attributedisplaysequence__c')) ? null : Integer.valueOf(attribObj.get('attributedisplaysequence__c'));
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

                                Integer attributeDisplaySequence = attribDef.get('displaySequence') == null ? null : Integer.valueOf(attribDef.get('displaySequence'));
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

                    if (attributeValues.size() > 0) {
                        // output.put('result', attributeValues);
                        return attributeValues;
                    }
                } else if (methodName == 'ToHierarchy') {
                    List<Object> items = (List<Object>)input.get('arguments');

                    Map<String, Map<String, Object>> itemMap = new Map<String, Map<String, Object>>();
                    for (Object itemObj : items) {
                        Map<String, Object> item = (Map<String, Object>)itemObj;
                        String lineNumber = (String)item.get('vlocity_cmt__LineNumber__c');
                        itemMap.put(lineNumber, item);
                    }
                    List<Object> rootItems = new List<Object>();
                    for (Object itemObj : items) {
                        Map<String, Object> item = (Map<String, Object>)itemObj;
                        String lineNumber = (String)item.get('vlocity_cmt__LineNumber__c');
                        Integer idx = lineNumber.lastIndexOf('.');
                        if (idx == -1) {
                            rootItems.add(item);
                        } else {
                            String parentLN = lineNumber.substring(0, idx);
                            Map<String, Object> parentItem = itemMap.get(parentLN);
                            List<Object> childItems = (List<Object>)parentItem.get('items');
                            if (childItems == null) {
                                childItems = new List<Object>();
                                parentItem.put('items', childItems);
                            }
                            childItems.add(item);
                        }
                    }

                    return rootItems;
                    // output.put('result', rootItems);
                }
                return null;
            } catch (Exception ex) {
                vLogger.write(ex);
                return null;
            } finally {
                
            }
        }
    }

    /**
     * @description Convert JSON from flat to structure based on the attribute name.
     */
    global virtual class JSLTHelper extends BaseHelper {
        // public override Boolean skipProcessJsonNode() { return false; }
        /**
         * @description interface implementation
         */
        global override Object invoke(String methodName, Map<String, Object> input) {
            System.debug('Jyue');
            if (methodName == 'toStructure') {
                System.debug('Jyue1');
                List<Object> args = (List<Object>)input.get('arguments');
                List<Object> data = new List<Object>();

                Boolean isMap = true;   // default
                String nameField = 'name';  // default
                String valueField = 'value'; // default
                for (Integer i = 0; i < args.size(); i++) {
                    Object item = args[i];
                    if (item instanceOf String || item instanceOf Boolean) {
                        isMap = Boolean.valueOf(args[i]);
                        if (isMap) {
                            if (i+1 < args.size()) nameField = (String)args[i+1];
                            if (i+2 < args.size()) valueField = (String)args[i+2];
                        }
                        break;
                    } else {
                        data.add(item);
                    }
                }
                
                Object flatJson = data;
                if (isMap) flatJson = data[0];
                //
                Map<String, Object> structureJson = convertJsonStructure(flatJson, nameField, valueField);
                //
                // structureJson = onJsonConverted(structureJson);
                // traverseJson(null, structureJson);
                System.debug('Jyue2');

                return structureJson;
                // output.put('result', structureJson);
            }

            return null;
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