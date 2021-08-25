@isTest
private with sharing class vCpqAppHandlerHookImplTest {
    @isTest
    private static void testAll() {
        vCpqAppHandlerHookImpl impl = new vCpqAppHandlerHookImpl();
        String payload = '{"methodName":"postCartsItems","items":[{"itemId":"01u5e000001918uAAA","attributesToUpdate":{"ATTRIBUTE-016":"Silver"}}],"cartId":"8015e000000p7muAAA","price":true,"validate":true,"includeAttachment":false,"pagesize":10,"lastRecordId":null,"hierarchy":-1,"query":"Apple iPhone Xs"}';

        Map<String, Object> input = (Map<String, Object>)JSON.deserializeUntyped(payload);
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        impl.invokeMethod('postCartsItems.PreInvoke', input, output, options);

        input = new Map<String, Object>();
        impl.invokeMethod('postCartsItems.PreInvoke', input, output, options);
    }
}
