@isTest
private with sharing class vCpqServiceTest {
    @isTest
    private static void testAddWithCfg_v1() {
        String payload = '{"methodName":"postCartsItems","items":[{"itemId":"01u5e000001918uAAA","attributesToUpdate":{"ATTRIBUTE-016":"Silver"}}],"cartId":"8015e000000p7muAAA","price":true,"validate":true,"includeAttachment":false,"pagesize":10,"lastRecordId":null,"hierarchy":-1,"query":"Apple iPhone Xs"}';
        Map<String, Object> input = (Map<String, Object>)JSON.deserializeUntyped(payload);

        vCpqService.addProductsWithCfg(input);

        OrderItem oLI = new OrderItem(
            PriceBookEntryId = '01u5e000001918uAAA',
            vlocity_cmt__AttributeSelectedValues__c = '{}',
            vlocity_cmt__JSONAttribute__c = '{}'
        );
        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', new List<SObject> { oLI });
        vCpqService service = new vCpqService();
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        service.invokeMethod('ProcessCartMessage', inputMap, outputMap, options);

    }

    @isTest
    private static void testAddWithCfg_v2() {
        String payload = '{"methodName":"postCartsItems","items":[{"itemId":"01u5e000001918uAAA","attributesToUpdate2":{"01u5e000001918uAAA":{"ATTRIBUTE-016":"Silver"}},"fieldsToUpdate2":{"01u5e000001918uAAA":{"Quantity":2}}}],"cartId":"8015e000000p7muAAA","price":true,"validate":true,"includeAttachment":false,"pagesize":10,"lastRecordId":null,"hierarchy":-1,"query":"Apple iPhone Xs"}';
        Map<String, Object> input = (Map<String, Object>)JSON.deserializeUntyped(payload);

        vCpqService.addProductsWithCfg(input);

        OrderItem oLI = new OrderItem(
            PriceBookEntryId = '01u5e000001918uAAA',
            vlocity_cmt__AttributeSelectedValues__c = '{}',
            vlocity_cmt__JSONAttribute__c = '{}'
        );
        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', new List<SObject> { oLI });
        vCpqService service = new vCpqService();
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        service.invokeMethod('ProcessCartMessage', inputMap, outputMap, options);

    }
    @isTest
    private static void testKeepNRC() {
        List<SObject> itemList = new List<SObject> {
            new OrderItem(
                vlocity_cmt__Action__c = 'Existing'
            )
        };
        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemList);
        vCpqService service = new vCpqService();
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        service.invokeMethod('KeepNRCInMACDStart', inputMap, outputMap, options);
        service.invokeMethod('KeepNRCInMACDStop', inputMap, outputMap, options);
    }
}
