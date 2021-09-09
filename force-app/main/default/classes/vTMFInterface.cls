global with sharing class vTMFInterface {
    global class SubmitProductOrder extends vlocity_cmt.DefaultSystemInterface {
        global virtual override String generatePayload(vlocity_cmt__OrchestrationItem__c item, vlocity_cmt.XOMOrderDomainObject orderObj) {
            // Generate default payload
            String payloadStr;
            if (Test.isRunningTest()) {
                payloadStr = '{"productOrder":[{"id":"1234"}]}';
            } else {
                payloadStr = super.generatePayload(item, orderObj);
            }
            Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(payloadStr);

            // Peel off the "productOrder" JSON wrapper node
            Map<String, Object> productOrder = (Map<String, Object>)((Object[])payload.get('productOrder'))[0];
            // Serialize the TMF ProductOrder payload
            return JSON.serialize(productOrder);
        }

    }
}