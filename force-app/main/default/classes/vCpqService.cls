/**
 * Service Class to extend the Salesforce Industries CPQ capabilities.
 * @author Soforce
 */
global with sharing class vCpqService implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        vLogger.writeInfo('Enter vCpqService.' + methodName);
        try {
            if (methodName == 'ProcessCartMessage') {
		        List<SObject> itemList = (List<SObject>)vlocity_cmt.PricingPlanService.getFromPricingContext('LineItemList');
                for (SObject xLI : itemList) {
                    setProductsWithCfg(xLI);
                }
            }
            // Following two methods are designed to keep MRC within MACD  
            else if (methodName == 'KeepNRCInMACDStart') {
                keepNRCForMACDProcess('Start');
            } else if (methodName == 'KeepNRCInMACDStop') {
                keepNRCForMACDProcess('Stop');
            }
            return true;
        }
        catch (Exception ex) {
            vLogger.write(ex);
            return false;
        } finally {
            vLogger.writeInfo('Exit vCpqService.' + methodName);
        }
    }

    public enum CartMessageType {
        AddProductsWithCfg
    }

    public abstract class CartMessage {
        public String messageId;
        public abstract CartMessageType getMessageType();
    }

    public class AddProductsWithCfgMessage extends CartMessage {
        Map<String, Object> attributeVals;
        Map<String, Object> fieldVals;
        public override CartMessageType getMessageType() { return CartMessageType.AddProductsWithCfg; }
        public AddProductsWithCfgMessage(String messageId, Map<String, Object> attributeVals, Map<String, Object> fieldVals) {
            this.messageId = messageId;
            this.attributeVals = attributeVals;
            this.fieldVals = fieldVals;
        }
    }

    static Map<CartMessageType, Map<String, CartMessage>> messages = new Map<CartMessageType, Map<String, CartMessage>>();
    static CartMessage addCartMessage(CartMessage message) {
        Map<String, CartMessage> typedMessages = messages.get(message.getMessageType());
        if (typedMessages == null) {
            typedMessages = new Map<String, CartMessage>();
            messages.put(message.getMessageType(), typedMessages);

            vLogger.writeVar('addCartMessage', message);
        }
        typedMessages.put(message.messageId, message);

        return message;
    }
    static CartMessage getCartMessage(CartMessageType messageType, String messageId) {
        Map<String, CartMessage> typedMessages = messages.get(messageType);
        if (typedMessages != null) {
            CartMessage message = typedMessages.remove(messageId);
            vLogger.writeVar('getCartMessage', message);
            return message;
        } else {
            return null;
        }
    }

    public static void addProductsWithCfg(Map<String, Object> inputMap) {
        vLogger.writeInfo('Enter vCpqService.addProductsWithCfg');
        try {

            Id cartId = (Id)inputMap.get('cartId');
            if (cartId.getSobjectType() == Schema.Quote.SObjectType || cartId.getSobjectType() == Schema.Order.SObjectType || cartId.getSobjectType() == Schema.Opportunity.SObjectType) {            
                for (Object item : (List<Object>)inputMap.get('items')) {
                    Map<String, Object> itemToAdd = (Map<String, Object>)item;
                    Map<String, Object> attributesToUpdateV2 = (Map<String, Object>)itemToAdd.get('attributesToUpdate2');
                    if (attributesToUpdateV2 != null) {
                        // AddWithConfiguration V2 is used.
                        Map<String, Object> fieldsToUpdateV2 = (Map<String, Object>)itemToAdd.get('fieldsToUpdate2');
                        String[] itemIds = ((String)itemToAdd.get('itemId')).split(',');
                        for (String itemId : itemIds) {
                            Map<String, Object> attributesToUpdate = (Map<String, Object>)attributesToUpdateV2.get(itemId);
                            Map<String, Object> fieldsToUpdate = fieldsToUpdateV2 == null ? null : (Map<String, Object>)fieldsToUpdateV2.get(itemId);
                            if (attributesToUpdate != null || fieldsToUpdate != null) {
                                AddProductsWithCfgMessage message = new AddProductsWithCfgMessage(itemId.trim(), attributesToUpdate, fieldsToUpdate);
                                addCartMessage(message);
                            }
                        }
                    } else {
                        Map<String, Object> attributesToUpdate = (Map<String, Object>)itemToAdd.get('attributesToUpdate');     
                        if (attributesToUpdate != null && attributesToUpdate.size() > 0) {
                            // String[] itemIds = ((String)itemToAdd.get('itemId')).split(',');
                            // for (String itemId : itemIds) {
                            AddProductsWithCfgMessage message = new AddProductsWithCfgMessage((String)itemToAdd.get('itemId'), attributesToUpdate, null);
                            addCartMessage(message);
                            // }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            throw ex;
        } finally {
            vLogger.writeInfo('Exit vCpqService.addProductsWithCfg');
        }
    }

    public static void setProductsWithCfg(SObject xLI) {
        vLogger.writeInfo('Enter vCpqService.setProductsWithCfg');
        try {
            String pbeId = (String)xLI.get('PricebookEntryId');
            AddProductsWithCfgMessage message = (AddProductsWithCfgMessage)getCartMessage(CartMessageType.AddProductsWithCfg, pbeId);
            if (message != null) {
                if (message.attributeVals != null) {
                    String attributeFieldName;
                    if (vHelper.isV2Attribute(xLI.getSObjectType())) {
                        // v2
                        attributeFieldName = 'vlocity_cmt__AttributeSelectedValues__c'; 
                    } else {
                        // v1
                        attributeFieldName = 'vlocity_cmt__JSONAttribute__c'; 
                    }
                    
                    String jsonAttribute = (String)xLI.get(attributeFieldName);
                    
                    String modifiedJsonAttribute = vHelper.setJSONAttributes(jsonAttribute, message.attributeVals);
                    
                    vLogger.writeVar('modifiedJsonAttribute', modifiedJsonAttribute);
                    xLI.put(attributeFieldName, modifiedJsonAttribute);
                }
                if (message.fieldVals != null) {
                    for (String fieldName : message.fieldVals.keySet()) {
                        xLI.put(fieldName, message.fieldVals.get(fieldName));
                    }
                }
            }
        } catch (Exception ex) {
            throw ex;
        } finally {
            vLogger.writeInfo('Exit vCpqService.setProductsWithCfg');
        }
    }

    /**
     * The method is used to skip the logic to zero out NRC within the MACD process. It's used within PricingPlan
     */
    static Map<Id, String> originalActions = new Map<Id, String>(); 
    Boolean keepNRCForMACDProcess(String command) {
        vLogger.writeInfo('keepNRCForMACDProcess - ' + command);
        List<SObject> itemList = (List<SObject>)vlocity_cmt.PricingPlanService.getFromPricingContext('LineItemList');
        if (command == 'Start') {
            for (SObject xLI : itemList) {
                String action = (String)xLI.get('vlocity_cmt__Action__c');
                if (action == 'Existing' || action == 'Change') {
                    originalActions.put(xLI.Id, action);
                    xLI.put('vlocity_cmt__Action__c', 'Add'); // Put as "Add" to skip the logic of zeroing out the NRC
                }
            }

            System.debug(JSON.serialize(originalActions));
        } else if (command == 'Stop') {
            for (SObject xLI : itemList) {
                if (originalActions.containsKey(xLI.Id)) {
                    // Needs to restore the original Action
                    xLI.put('vlocity_cmt__Action__c', originalActions.get(xLI.Id));
                }
            }
        }

        return true;
    }
}