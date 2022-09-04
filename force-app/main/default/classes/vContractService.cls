global with sharing class vContractService implements vlocity_cmt.VlocityOpenInterface {
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
     * 
     */
    public vlocity_cmt__CustomFieldMap__c[] getFieldMappers(String sourceObjType, String destinationObjType) {
        vlocity_cmt__CustomFieldMap__c[] mappers = new List<vlocity_cmt__CustomFieldMap__c>();
        for (vlocity_cmt__CustomFieldMap__c mapper : vlocity_cmt__CustomFieldMap__c.getAll().values()) {
            if (mapper.vlocity_cmt__DestinationSObjectType__c == destinationObjType && mapper.vlocity_cmt__SourceSObjectType__c == sourceObjType) {
                mappers.add(mapper);
            }
        }

        return mappers;
    }
    /**
     * @description refresh contract line items from cart items
     */
    Boolean refreshContractLineItems(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Id cartId = (Id)inputMap.get('CartId');     // Cart (Quote/Order/Opportunity) Id
        Id contractId = (Id)inputMap.get('ContractId'); // Contract Id

        vlocity_cmt__CustomFieldMap__c[] mappers = getFieldMappers('QuoteLineItem', 'vlocity_cmt__ContractLineItem__c');

        return true;
    }

    Boolean updateContractLineItems(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {

        return true;
    }

    Boolean amendContractLineItems(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Id cartId = (Id)inputMap.get('CartId');
        Id contractId = (Id)inputMap.get('ContractId'); // Contract Id
        Id[] itemIds = (Id[])inputMap.get('ItemIds');   // Arrays of Contract Line Item Ids

        return true;
    }

    Boolean activateContractLineItems(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {

        return true;
    }
}