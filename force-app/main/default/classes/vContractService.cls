/**
 * Service class for vlocity Contract Management
 * @author soforce
 */
global with sharing class vContractService implements vlocity_cmt.VlocityOpenInterface {
    public class vContractServiceException extends Exception {}

    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        vLogger.writeInfo('Enter vContractService.' + methodName);
        vLogger.writeVar('inputMap', inputMap);
        try {
            if (methodName == 'RefreshContractLineItems') {
                return refreshContractLineItems(inputMap, outputMap, options);
            } else if (methodName == 'GenerateAmendingCartItems') {
                return generateAmendingCartItems(inputMap, outputMap, options);
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
     * Refresh contract line items from cart items
     */
    Boolean refreshContractLineItems(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Id cartId = (Id)inputMap.get('CartId');     // Cart (Quote/Order/Opportunity) Id
        Id contractId = (Id)inputMap.get('ContractId'); // Contract Id

        // cartLineItem -> ContractLineItem
        Map<String, String> fMappers = vHelper.getFieldMappers(getCartItemObjectName(cartId), 'vlocity_cmt__ContractLineItem__c');
        
        List<SObject> cartItems = retrieveCartItems(cartId, fMappers.keySet());
        Map<String, vlocity_cmt__ContractLineItem__c> contractItems = retrieveContractLineItems(contractId, null);

        vLogger.writeVar('cartItems', cartItems);
        vLogger.writeVar('contractItems', contractItems);

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
                    vlocity_cmt__ContractId__c = contractId, 
                    vlocity_cmt__LineStatus__c = 'Draft'
                );
                insertItems.add(contractItem);
            }

            vHelper.copySObjectFieldValues(cartItem, contractItem, fMappers);
        }
        
        vLogger.writeVar('insertItems', insertItems);
        vLogger.writeVar('updateItems', updateItems);
        vLogger.writeVar('contractItems(delete)', contractItems.values());

        insert insertItems;
        update updateItems;
        delete contractItems.values();

        return true;
    }

    /**
     * Generate line items for the cart to amend the given contract 
     */
    Boolean generateAmendingCartItems(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Id contractId = (Id)inputMap.get('ContractId');
        Id cartId = (Id)inputMap.get('CartId');


        Map<String, String> fMappers = vHelper.getFieldMappers('vlocity_cmt__ContractLineItem__c', getCartItemObjectName(cartId));
        vlocity_cmt__ContractLineItem__c[] cLIs = getAmendingContractLineItems(contractId, fMappers.keySet());

        vLogger.writeVar('AmendingCLIs', cLIs);

        //
        List<SObject> insertItems = new List<SObject>();
        Integer qLIRootLN = 0;
        Id currentId = null;
        Integer currentCLIRootLN = -1;
        for (vlocity_cmt__ContractLineItem__c cLI : cLIs) {
            Integer cLIRootLN = Integer.valueOf(cLI.vlocity_cmt__LineNumber__c.subString(0, 4));
            if (currentId != cLI.vlocity_cmt__ContractId__c) {
                currentId = cLI.vlocity_cmt__ContractId__c;
                currentCLIRootLN = Integer.valueOf(cLI.vlocity_cmt__LineNumber__c);
                qLIRootLN += 1;
            } else if (currentCLIRootLN != cLIRootLN) {
                currentCLIRootLN = Integer.valueOf(cLI.vlocity_cmt__LineNumber__c);
                qLIRootLN += 1;
            }

            String lineNumber = cLI.vlocity_cmt__LineNumber__c;
            if (qLIRootLN != cLIRootLN) {
                lineNumber = String.valueOf(qLIRootLN).leftPad(4, '0') + (lineNumber.length() == 4 ? '' : lineNumber.substring(4));
            }

            SObject cartItem = newCartItem(cartId);
            vHelper.copySObjectFieldValues(cLI, cartItem, fMappers);
            cartItem.put('vlocity_cmt__Action__c', 'Existing');
            cartItem.put('vlocity_cmt__LineNumber__c', lineNumber);

    
            insertItems.add(cartItem);
        }


        insert insertItems;
        vLogger.writeVar('insertItems', insertItems);

        return true;
    }

    /**
     * Activate contract line items on activating a master or amendment contract.
     */
    Boolean activateContractLineItems(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Id contractId = (Id)inputMap.get('ContractId'); // Contract Id

        List<vlocity_cmt__ContractLineItem__c> activateItems = new List<vlocity_cmt__ContractLineItem__c>();
        Contract myContract = [SELECT Id, vlocity_cmt__OriginalContractId__c, (SELECT Id, vlocity_cmt__AssetReferenceId__c, Action__c FROM vlocity_cmt__ContractLineItems__r) FROM Contract WHERE Id=:contractId];
        Set<String> assetRefIds = new Set<String>();
        for (vlocity_cmt__ContractLineItem__c cli : myContract.vlocity_cmt__ContractLineItems__r) {
            cli.vlocity_cmt__LineStatus__c = 'Active';
            if (cli.Action__c != 'Add')
                assetRefIds.add(cli.vlocity_cmt__AssetReferenceId__c);
        }
        activateItems.addAll(myContract.vlocity_cmt__ContractLineItems__r);

        if (myContract.vlocity_cmt__OriginalContractId__c != null) {
            Id masterId = myContract.vlocity_cmt__OriginalContractId__c;
            // Amendment contract, needs to update CLIs from the original contracts
            vlocity_cmt__ContractLineItem__c[] cLIs = [
                SELECT Id, vlocity_cmt__AssetReferenceId__c, vlocity_cmt__LineStatus__c FROM vlocity_cmt__ContractLineItem__c
                WHERE (vlocity_cmt__ContractId__c=:masterId OR vlocity_cmt__ContractId__r.vlocity_cmt__OriginalContractId__c=:masterId)  
                    AND vlocity_cmt__ContractId__c!=:contractId AND vlocity_cmt__ContractId__r.Status='Activated' 
                    AND vlocity_cmt__LineStatus__c='Active' AND Action__c!='Disconnected' AND vlocity_cmt__AssetReferenceId__c IN :assetRefIds];
            
            for (vlocity_cmt__ContractLineItem__c cLI : cLIs) {
                cLI.vlocity_cmt__LineStatus__c = 'Inactive';
                activateItems.add(cLI);
            }
        }
        update activateItems;
        
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

        String query = 'SELECT ' + String.join(new List<String>(reqiredFields), ',') + 
            ' FROM ' + getCartItemObjectName(cartId) + 
            ' WHERE ' + getCartItemParentFieldName(cartId) + '=:cartId' + // AND vlocity_cmt__Action__c != \'Existing\'' +
            ' ORDER BY vlocity_cmt__LineNumber__c';

        List<SObject> items4CLIs = new List<SObject>();
        List<SObject> bundleProducts = new List<SObject>();
        String currentRootLN = '';
        Boolean bundleHasChanged = false;
        for (SObject item : Database.query(query)) {
            String myRootLN = ((String)item.get('vlocity_cmt__LineNumber__c')).left(4);
            if (myRootLN != currentRootLN) {
                if (bundleHasChanged) items4CLIs.addAll(bundleProducts);
                // Reset
                currentRootLN = myRootLN;
                bundleHasChanged = false;
                bundleProducts.clear();
            }

            bundleProducts.add(item);
            if ((String)item.get('vlocity_cmt__Action__c') != 'Existing') {
                bundleHasChanged = true;
            }
        }

        if (bundleHasChanged) items4CLIs.addAll(bundleProducts);

        return items4CLIs;
    }


    
    List<vlocity_cmt__ContractLineItem__c> getAmendingContractLineItems(Id masterContractId, Set<String> fields) {
        Set<String> reqiredFields = new Set<String> {
            'vlocity_cmt__AssetReferenceId__c'.toLowerCase(),
            'vlocity_cmt__LineNumber__c'.toLowerCase(),
            'vlocity_cmt__ContractId__c'.toLowerCase()
            // 'vlocity_cmt__OriginalContractId__c'.toLowerCase()
        };
        reqiredFields.addAll(fields);
        String query = 'SELECT ' + String.join(new List<String>(reqiredFields), ',') + 
            ' FROM vlocity_cmt__ContractLineItem__c' +
            ' WHERE (vlocity_cmt__ContractId__c=:masterContractId OR vlocity_cmt__ContractId__r.vlocity_cmt__OriginalContractId__c=:masterContractId)' +
            ' AND vlocity_cmt__ContractId__r.Status=\'Activated\' AND vlocity_cmt__LineStatus__c=\'Active\' AND Action__c IN (\'Add\', \'Change\', \'Existing\')' +
            ' ORDER BY vlocity_cmt__ContractId__r.vlocity_cmt__OriginalContractId__c, vlocity_cmt__LineNumber__c';
        
        vLogger.writeVar('query', query);

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