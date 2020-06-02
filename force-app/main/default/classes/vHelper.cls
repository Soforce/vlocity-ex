public with sharing class vHelper {
    /*
     * @description utiliy method to read the attribute value from JSONAttribute field
     */
    public static Map<String, Object> getJSONAttributeValues(String jsonAttribute) {
        vlocity_cmt.JSONAttributeSupport jsonSupport = new vlocity_cmt.JSONAttributeSupport();
        // Read the old speed
        Map<String, object> inputMap = new Map<String, object>{
            'UseDisplayTextForValues' => false,
            'JSONString' => jsonAttribute
        }; 
        Map<String, object> outputMap = new Map<String, object>(); 
        Map<String, object> optionsMap = new Map<String, object>();

        jsonSupport.invokeMethod('getAttributeValuesFromJSON', inputMap, outputMap, optionsMap); 
        Map<String, Object> attrVals = (Map<String, Object>)outputMap.get('attributeCodeToValue');
        return attrVals;
        // return attrVals.get(attribCode);
    }    

    /*
     * @description utiliy method to read the attribute value from JSONAttribute field
     */
    public static Object getJSONAttributeValue(String jsonAttribute, String attribCode) {
        return getJSONAttributeValues(jsonAttribute).get(attribCode);
    }     

    public static String setJSONAttribute(String runtimeJSON, String originalJSON, String code, Object val) {
        Map<String, Object> attrVals = new Map<String, Object> {
            code => val
        };
        return setJSONAttributes(runtimeJSON, originalJSON, attrVals);
    }
    
    public static String setJSONAttributes(String runtimeJSON, String originalJSON, Map<String, Object> attrVals) {
        List<vlocity_cmt.JSONAttributeSupport.JSONAttributeActionRequest> actionRequestsList = new List<vlocity_cmt.JSONAttributeSupport.JSONAttributeActionRequest>();
        for (String attrCode : attrVals.keySet()) {
            Object attrVal = attrVals.get(attrCode);

            actionRequestsList.add(new vlocity_cmt.JSONAttributeSupport.JSONAttributeActionRequest(
                attrCode, 
                vlocity_cmt.JSONAttributeSupport.ActionType.ASSIGN, 
                attrVal)
            );
        }

        vlocity_cmt.JSONAttributeSupport jsonSupport = new vlocity_cmt.JSONAttributeSupport();
        Map<String, Object> myInputMap = new Map<String, Object> {
            'objectSO' => null,
            'runTimeAttributesJSON' => runtimeJSON,
            'originalAttributesJSON' => originalJSON,
            'JSONAttributeActionRequestList' => actionRequestsList
        };
        Map<String, Object> myOutputMap = new Map<String, Object>();
        Map<String, Object> myOptionsMap = new Map<String, Object>();

        jsonSupport.invokeMethod('applyAttributeActions', myInputMap, myOutputMap, myOptionsMap);
        String modifiedJSON = (String)myOutputMap.get('modifiedJSON');

        return modifiedJSON;
    }       
}