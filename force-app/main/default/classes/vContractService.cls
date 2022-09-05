global with sharing class vContractService implements vlocity_cmt.VlocityOpenInterface {
    public class vContractServiceException extends Exception {}

    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        vLogger.writeInfo('Enter vContractService.' + methodName);
        try {
            if (methodName == 'CreateContractLineItems') {
                return refreshContractLineItems(inputMap, outputMap, options);
            } else if (methodName == 'UpdateContractLineItems') {
                return refreshContractLineItems(inputMap, outputMap, options);
            } else if (methodName == 'AmendContractLineItems') {
                return amendContractLineItems(inputMap, outputMap, options);
            } else if (methodName == 'ActivateContractLineItems') {
                return activateContractLineItems(inputMap, outputMap, options);
            }
            return true;
        }
        catch (Exception ex) {
            vLogger.write(ex);
            return false;
        } finally {
            vLogger.writeInfo('Exit vContractService.' + methodName);
        }
    }


    /**
     * @description refresh contract line items from cart items
     */
    Boolean refreshContractLineItems(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Id cartId = (Id)inputMap.get('CartId');     // Cart (Quote/Order/Opportunity) Id
        Id contractId = (Id)inputMap.get('ContractId'); // Contract Id

        // cartLineItem -> ContractLineItem
        Map<String, String> fMappers = vHelper.getFieldMappers(getCartItemObjectName(cartId), 'vlocity_cmt__ContractLineItem__c');
        
        List<SObject> cartItems = retrieveCartItems(cartId, fMappers.keySet());
        Map<String, vlocity_cmt__ContractLineItem__c> contractItems = retrieveContractLineItems(contractId, null);

        List<SObject> insertItems = new List<SObject>();
        List<SObject> updateItems = new List<SObject>();
        // List<SObject> deleteItems = new List<SObject>();

        for (SObject cartItem : cartItems) {
            String assetRefId = (String)cartItem.get('vlocity_cmt__AssetReferenceId__c');
            vlocity_cmt__ContractLineItem__c contractItem = contractItems.remove(assetRefId);
            if (contractItem != null) {
                updateItems.add(contractItem);
            } else {
                contractItem = new vlocity_cmt__ContractLineItem__c(
                    vlocity_cmt__ContractId__c = contractId
                );
                insertItems.add(contractItem);
            }

            vHelper.copySObjectFieldValues(cartItem, contractItem, fMappers);
        }
        

        insert insertItems;
        update updateItems;
        delete contractItems.values();

        return true;
    }

    // Boolean updateContractLineItems(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {

    //     return true;
    // }

    Boolean amendContractLineItems(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Id cartId = (Id)inputMap.get('CartId');
        Id contractId = (Id)inputMap.get('ContractId'); // Contract Id
        Id[] itemIds = (Id[])inputMap.get('ItemIds');   // Id Arrays of Contract Line Item to amend


        // ContractLineItem -> cartLineItem
        Map<String, String> fMappers = vHelper.getFieldMappers('vlocity_cmt__ContractLineItem__c', getCartItemObjectName(cartId));
        
        List<vlocity_cmt__ContractLineItem__c> contractItems = retrieveContractLineItems(contractId, itemIds, fMappers.keySet());


        String query = 'SELECT Id, vlocity_cmt__LineNumber__c, vlocity_cmt__AssetReferenceId__c FROM ' + getCartItemObjectName(cartId) + ' WHERE ' + getCartItemParentFieldName(cartId) + '=:cartId';
        Map<String, SObject> cartItems = new Map<String, SObject>();
        for (SObject cartItem : Database.query(query)) {
            cartItems.put((String)cartItem.get('vlocity_cmt__AssetReferenceId__c'), cartItem);
        }

        Integer lastLN = 0;
        List<String> childLNPrefixes = new List<String>();
        for (Integer i=contractItems.size() - 1; i>=0; i--) {
            vlocity_cmt__ContractLineItem__c contractItem = contractItems[i];
            Integer ln = Integer.valueOf(contractItem.vlocity_cmt__LineNumber__c);
            if (ln > lastLN) lastLN = ln;

            if (contractItem.vlocity_cmt__LineNumber__c.length() > 4) {
                throw new vContractServiceException('The selected contract line item with LineNumber ' + contractItem.vlocity_cmt__LineNumber__c + ' is not a root item and can not be amended.');
            }
            if (cartItems.containsKey(contractItem.vlocity_cmt__AssetReferenceId__c)) {
                contractItems.remove(i); // Remove the contract item because it's added to the cart for amending already
            } else {
                childLNPrefixes.add(contractItem.vlocity_cmt__LineNumber__c + '.%');
            }
        }

        if (contractItems.size() > 0) {
            // Retrieve child contract line items of the root contract line items
            contractItems.addAll(retrieveChildContractLineItems(contractId, childLNPrefixes, fMappers.keySet()));

            List<SObject> insertItems = new List<SObject>();

            String cartItemRootLN;
            for (Integer i=0; i < contractItems.size(); i++) {
                vlocity_cmt__ContractLineItem__c contractItem = contractItems[i];
                if (contractItem.vlocity_cmt__LineNumber__c.length() == 4) {
                    lastLN += 1;   // increase lastLN of cart item
                    cartItemRootLN = String.valueOf(lastLN).leftPad(4, '0');
                }

                SObject cartItem = newCartItem(cartId);
                vHelper.copySObjectFieldValues(contractItem, cartItem, fMappers);

                // Bump up the LineNumber__c for the new create cart item
                cartItem.put('vlocity_cmt__Action__c', 'Existing'); // Flag for MACD
                cartItem.put('vlocity_cmt__LineNumber__c', cartItemRootLN + contractItem.vlocity_cmt__LineNumber__c.subString(4));

                insertItems.add(cartItem);
            }

            insert insertItems;
        }

        
        return true;
    }

    Boolean activateContractLineItems(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {

        return true;
    }

    String getCartItemObjectName(Id cartId) {
        if (cartId.getSobjectType() == Opportunity.SObjectType) {
            return 'OpportunityLineItem';
        } else if (cartId.getSobjectType() == Quote.SObjectType) {
            return 'QuoteLineItem';
        } else if (cartId.getSobjectType() == Order.SObjectType) {
            return 'OrderItem';
        } else {
            throw new vContractServiceException('Invalid cart Id: ' + cartId);
        }
    }

    String getCartItemParentFieldName(Id cartId) {
        if (cartId.getSobjectType() == Opportunity.SObjectType) {
            return 'OpportunityId';
        } else if (cartId.getSobjectType() == Quote.SObjectType) {
            return 'QuoteId';
        } else if (cartId.getSobjectType() == Order.SObjectType) {
            return 'OrderId';
        } else {
            throw new vContractServiceException('Invalid cart Id: ' + cartId);
        }        
    }

    SObject newCartItem(Id cartId) {
        if (cartId.getSobjectType() == Opportunity.SObjectType) {
            return new OpportunityLineItem(OpportunityId=cartId);
        } else if (cartId.getSobjectType() == Quote.SObjectType) {
            return new QuoteLineItem(QuoteId=cartId);
        } else if (cartId.getSobjectType() == Order.SObjectType) {
            return new OrderItem(OrderId=cartId);
        } else {
            throw new vContractServiceException('Invalid cart Id: ' + cartId);
        }            
    }

    List<SObject> retrieveCartItems(Id cartId, Set<String> fields) {
        Set<String> reqiredFields = new Set<String> {
            'vlocity_cmt__AssetReferenceId__c'.toLowerCase(),
            'vlocity_cmt__LineNumber__c'.toLowerCase()
        };
        reqiredFields.addAll(fields);

        String query = 'SELECT ' + String.join(new List<String>(reqiredFields), ',') + ' FROM ' + getCartItemObjectName(cartId) + ' WHERE ' + getCartItemParentFieldName(cartId) + '=:cartId';
        return Database.query(query);
    }

    Map<String, vlocity_cmt__ContractLineItem__c> retrieveContractLineItems(Id contractId, List<String> assetReferenceIds) {
        String query = 'SELECT Id, vlocity_cmt__AssetReferenceId__c, vlocity_cmt__LineNumber__c FROM vlocity_cmt__ContractLineItem__c WHERE vlocity_cmt__ContractId__c=:contractId';
        if (assetReferenceIds != null) query += ' vlocity_cmt__AssetReferenceId__c=:assetReferenceIds';

        Map<String, vlocity_cmt__ContractLineItem__c> itemMap = new Map<String, vlocity_cmt__ContractLineItem__c>();
        for (vlocity_cmt__ContractLineItem__c item : Database.query(query)) {
            itemMap.put(item.vlocity_cmt__AssetReferenceId__c, item);
        }

        return itemMap;
    }

    List<vlocity_cmt__ContractLineItem__c> retrieveContractLineItems(Id contractId, List<Id> itemIds, Set<String> fields) {
        Set<String> reqiredFields = new Set<String> {
            'vlocity_cmt__AssetReferenceId__c'.toLowerCase(),
            'vlocity_cmt__LineNumber__c'.toLowerCase()
        };
        reqiredFields.addAll(fields);
        String query = 'SELECT ' + String.join(new List<String>(reqiredFields), ',') + ' FROM vlocity_cmt__ContractLineItem__c WHERE vlocity_cmt__ContractId__c=:contractId AND Id=:itemIds';
        return Database.query(query);
    }

    List<vlocity_cmt__ContractLineItem__c> retrieveChildContractLineItems(Id contractId, List<String> lineNumberPrefixes, Set<String> fields) {
        Set<String> reqiredFields = new Set<String> {
            'vlocity_cmt__AssetReferenceId__c'.toLowerCase(),
            'vlocity_cmt__LineNumber__c'.toLowerCase()
        };
        reqiredFields.addAll(fields);
        String query = 'SELECT ' + String.join(new List<String>(reqiredFields), ',') + ' FROM vlocity_cmt__ContractLineItem__c WHERE vlocity_cmt__ContractId__c=:contractId AND vlocity_cmt__LineNumber__c LIKE :lineNumberPrefixes';
        return Database.query(query);
    }
}