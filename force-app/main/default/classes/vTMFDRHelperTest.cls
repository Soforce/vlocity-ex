@isTest
private class vTMFDRHelperTest {
    @isTest
    private static void ToProductOrderItem_test() {
        String payload ='{"arguments":[{"product.productCharacteristic.SN":"123-4458-6721","product.productCharacteristic.TN":"778-889-1212","product.productSpecification.id":"b2f321931bb7e81438200fe3604bcb8b","product.productSpecification.name":"SIM","productOrderItemRelationship[hasParent].id":"a5D7j000000HJOHEA4"}]}';

        vTMFDRHelper helper = new vTMFDRHelper();
        Map<String, Object> input = (Map<String, Object>)JSON.deserializeUntyped(payload);
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        helper.invokeMethod('ToProductOrderItem', input, output, options);

        System.debug(JSON.serialize(output));
    }
}