global with sharing class vTMFDRHelper implements vlocity_cmt.VlocityOpenInterface {
    public class vTMFDRHelperException extends Exception {}

    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options){
        if (methodName == 'ToProductOrderItem') {
            // System.debug('input: ' + JSON.serialize(input));
            ProductOrderItemHelper helper = new ProductOrderItemHelper();
            return helper.invokeMethod('toStructure', input, output, options);
        }
        
        return true;
    }

    global virtual class ProductOrderItemHelper extends vDRHelper.JSLTHelper {
        public override Boolean skipProcessJsonResult() { return false; }

        public override Object processJsonNode(String parentJpath, Object jsonObject) {
            if (parentJpath.endsWith('productCharacteristic')) {
                return processCharacteristicJsonNode((Map<String, Object>)jsonObject);
            } else if (parentJpath.endsWith('productOrderItemRelationship')) {
                return processItemRelationshipJsonNode((List<Object>)jsonObject);
            }

            return jsonObject;
        }

        /**
         * @description process Characteristic JSON node
         */
        Object[] processCharacteristicJsonNode(Map<String, Object> mapJsonNode) {
            List<Object> charsJsonNode = new List<Object>();
            for (String charName : mapJsonNode.keySet()) {
                charsJsonNode.add(new Map<String, Object> {
                    'name' => charName,
                    'value' => mapJsonNode.get(charName)
                });
            }

            return charsJsonNode;       
        }

        
        /**
         * @description process ItemRelationship JSON Node
         */
        Object processItemRelationshipJsonNode(List<Object> relationshipNodes) {
            for (Object relNode : relationshipNodes) {
                Map<String, Object> relationshipNode = (Map<String, Object>)relNode;
                String roleName = (String)relationshipNode.get('@arrayKey');
                relationshipNode.put('relationshipType', roleName);
            }

            return relationshipNodes;
        }
    }
}