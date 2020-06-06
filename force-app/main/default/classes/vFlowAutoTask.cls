global class vFlowAutoTask implements vlocity_cmt.XOMOrchestrationInterfaces.IAutoTask {
    global void executeBatch(List<vlocity_cmt__OrchestrationItem__c> items) {
        vLogger.writeInfo('Enter XOMOrchestrationInterfaces.executeBatch');
        try {
            // Batch is not supported yet
            vlocity_cmt__OrchestrationItem__c item = items[0];
            item = [SELECT Id, vlocity_cmt__AutoTaskParameters__c, vlocity_cmt__FulfilmentRequestLineId__c, vlocity_cmt__OrchestrationPlanId__c FROM vlocity_cmt__OrchestrationItem__c WHERE Id=:item.Id];

            Map<String, Object> paraMap = (Map<String, Object>)JSON.deserializeUntyped(item.vlocity_cmt__AutoTaskParameters__c);
            String flowName = (String)paraMap.get('flowName');
            // RuntimeDependencyDefName is the additional parameter for the name of runtime dependency definition
            Map<String, Object> inputs = new Map<String, Object> {
                'itemId' => item.Id,
                'fulfillmentRequestLineId' => item.vlocity_cmt__FulfilmentRequestLineId__c,
                'planId' => item.vlocity_cmt__OrchestrationPlanId__c
            };
            inputs.putAll(paraMap);
            
            Flow.Interview myFlow = Flow.Interview.createInterview(flowName, inputs);

            myFlow.start();        
        } catch (Exception ex) {
            vLogger.write(ex);
            throw ex;
        } finally {
            vLogger.writeInfo('Exit XOMOrchestrationInterfaces.executeBatch');
        }
    }
}