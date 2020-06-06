public with sharing class vOrchestrationItemAttributesGetter {
    @InvocableMethod(label='Read Orchestration Item Attributes' category='Vlocity Extension')
    public static List<vOrchestrationItemAttributes.Result> readOrchestrationItemData(List<vOrchestrationItemAttributes.Request> requests) {
        if (String.isNotEmpty(requests[0].orchestrationItemId)) {
            return new List<vOrchestrationItemAttributes.Result> {
                new vOrchestrationItemAttributes.Result(readOrchestrationItemData(requests[0].orchestrationItemId))
            };
        } else {
            return new List<vOrchestrationItemAttributes.Result> {
                new vOrchestrationItemAttributes.Result(readOrchestrationItemDataList(requests[0].orchestrationItemIds))
            };
        }

    }

    static vOrchestrationItemAttributes readOrchestrationItemData(Id orchestrationItemId) {
        return readOrchestrationItemDataList(new List<Id> {orchestrationItemId})[0];
    }
    
    static List<vOrchestrationItemAttributes> readOrchestrationItemDataList(List<Id> orchestrationItemIds) {
        vLogger.writeInfo('Enter vOrchestrationItemAttributesGetter.readOrchestrationItemDataList');
        vLogger.writeVar('orchestrationItemIds', orchestrationItemIds);
        try {
            vOrchestrationItemAttributes[] itemAttribsList = new List<vOrchestrationItemAttributes>();
            
            vlocity_cmt__OrchestrationItem__c[] items = [SELECT Id, vlocity_cmt__OrderItemId__r.OrderId, vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__FulfilmentRequestId__c FROM vlocity_cmt__OrchestrationItem__c WHERE Id=:orchestrationItemIds];
            for (vlocity_cmt__OrchestrationItem__c item : items) {
        
                vOrchestrationItemAttributes itemAttribs = new vOrchestrationItemAttributes();
                itemAttribsList.add(itemAttribs);
                
                itemAttribs.item_id = item.Id;
        
        
                Id orderId = null;
                Id accountId;
                SObject[] itemSObjs;
                if (item.vlocity_cmt__OrderItemId__r.OrderId != null) {
                    orderId = item.vlocity_cmt__OrderItemId__r.OrderId;
                    OrderItem[] oLIs = [
                        SELECT Id, 
                                Order.AccountId, 
                                vlocity_cmt__JSONAttribute__c, 
                                vlocity_cmt__ServiceAccountId__c, 
                                vlocity_cmt__Action__c, 
                                vlocity_cmt__LineNumber__c, 
                                vlocity_cmt__Product2Id__c,
                                vlocity_cmt__Product2Id__r.Name,
                                vlocity_cmt__Product2Id__r.ProductCode
                        FROM OrderItem
                        WHERE OrderId = :orderId
                        ORDER BY vlocity_cmt__LineNumber__c
                    ];
                    accountId = oLIs[0].Order.AccountId;
        
                    OrderItem myOLI = (new Map<Id, OrderItem>(oLIs)).get(item.vlocity_cmt__OrderItemId__r.Id);
                    String myRootLineNumber = myOLI.vlocity_cmt__LineNumber__c.subString(0, 4);
                    itemSObjs = new List<SObject>();
                    for (OrderItem oLI : oLIs) {
                        if (oLI.vlocity_cmt__LineNumber__c.startsWith(myRootLineNumber)) {
                            itemSObjs.add(oLI);
                        }
                    }
                } else if (item.vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__FulfilmentRequestId__c != null) {
                    orderId = item.vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__FulfilmentRequestId__c;
                    itemSObjs = [
                        SELECT Id, 
                                vlocity_cmt__FulfilmentRequestID__r.vlocity_cmt__AccountId__c, 
                                vlocity_cmt__JSONAttribute__c, 
                                vlocity_cmt__ServiceAccountId__c,
                                vlocity_cmt__Action__c, 
                                vlocity_cmt__LineNumber__c, 
                                vlocity_cmt__Product2Id__c,
                                vlocity_cmt__Product2Id__r.Name,
                                vlocity_cmt__Product2Id__r.ProductCode
                        FROM vlocity_cmt__FulfilmentRequestLine__c
                        WHERE vlocity_cmt__FulfilmentRequestID__c = :orderId
                        ORDER BY vlocity_cmt__LineNumber__c
                    ];
                    accountId = ((vlocity_cmt__FulfilmentRequestLine__c)itemSObjs[0]).vlocity_cmt__FulfilmentRequestID__r.vlocity_cmt__AccountId__c;
        
                    vlocity_cmt__FulfilmentRequestLine__c myFRL = (new Map<Id, vlocity_cmt__FulfilmentRequestLine__c>((vlocity_cmt__FulfilmentRequestLine__c[])itemSObjs)).get(item.vlocity_cmt__FulfilmentRequestLineId__r.Id);
                }
        
                itemAttribs.account_id = accountId;
                itemAttribs.order_id = orderId;
                
        
        
                Map<String, List<vOrchestrationOrderItemAttributes>> lnChildItemsMap = new Map<String, List<vOrchestrationOrderItemAttributes>>(); // The order_items collection where the current item is put
        
                Set<String> attributeCodes = new Set<String>();
                for (SObject itemSObj : itemSObjs) {
                    vOrchestrationOrderItemAttributes orderItem = new vOrchestrationOrderItemAttributes();
        
                    String lineNumber = (String)itemSObj.get('vlocity_cmt__LineNumber__c');
                    if (itemSObj.getSObjectType() == vlocity_cmt__FulfilmentRequestLine__c.SObjectType) {
                        lineNumber = lineNumber.substringAfter('.');
                    }
        
                    String parentLineNumber = lineNumber.length() == 4 ? '' : lineNumber.subString(0, lineNumber.length() - 5);
                    if (parentLineNumber != '') {
                        List<vOrchestrationOrderItemAttributes> orderItems = lnChildItemsMap.get(parentLineNumber);
                        orderItems.add(orderItem);
                    } else {
                        itemAttribs.order_item = orderItem;
                    }
        
                    orderItem.action = (String)itemSObj.get('vlocity_cmt__Action__c');
                    orderItem.order_item_id = itemSObj.Id;
                    orderItem.service_account_id = (Id)itemSObj.get('vlocity_cmt__ServiceAccountId__c');
                    orderItem.product_id = (Id)itemSObj.get('vlocity_cmt__Product2Id__c');
                    orderItem.product_name = (String)itemSObj.getSObject('vlocity_cmt__Product2Id__r').get('Name');
                    orderItem.product_code = (String)itemSObj.getSObject('vlocity_cmt__Product2Id__r').get('ProductCode');
        
                    // Parse JSON attribute for described_by node
                    if (itemSObj.get('vlocity_cmt__JSONAttribute__c') != null) {
                        vlocity_cmt.JSONAttributeSupport jsonSupport = new vlocity_cmt.JSONAttributeSupport();
                        Map<String, object> inputMap = new Map<String, object>{
                            'UseDisplayTextForValues' => false,
                            'JSONString' => (String)itemSObj.get('vlocity_cmt__JSONAttribute__c')
                        }; 
                        Map<String, object> outputMap = new Map<String, object>(); 
                        Map<String, object> optionsMap = new Map<String, object>();
                
                        jsonSupport.invokeMethod('getAttributeValuesFromJSON', inputMap, outputMap, optionsMap); 
                        Map<String, Object> attrValMap = (Map<String, Object>)outputMap.get('attributeCodeToValue');
                        Map<String, Object> attrNameMap = (Map<String, Object>)outputMap.get('attributeCodeToDisplayName');
                        
                        for (String attrCode : attrValMap.keySet()) {
                            orderItem.described_by.add(new vNameValuePair(attrCode, String.valueOf(attrValMap.get(attrCode))));
                        }
                    }
        
                    // Add to the LineNumber and order_items to the Map
                    lnChildItemsMap.put(lineNumber, orderItem.order_items);
                }
            }
            vLogger.writeVar('itemAttribsList', itemAttribsList);
            return itemAttribsList;
        } catch (Exception ex) {
            vLogger.write(ex);
            throw ex;
        } finally {
            vLogger.writeInfo('Exit vOrchestrationItemAttributesGetter.readOrchestrationItemDataList');
        }
    }

}
