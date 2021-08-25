global with sharing class vCpqAppHandlerHookImpl implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        vLogger.writeInfo('Enter vCpqAppHandlerHookImpl.' + methodName);
        try {
            if (methodName == 'postCartsItems.PreInvoke') {
                vCpqService.addProductsWithCfg(inputMap);
            }
            return true;
        }
        catch (Exception ex) {
            vLogger.write(ex);
            return false;
        } finally {
            vLogger.writeInfo('Exit vCpqAppHandlerHookImpl.' + methodName);
        }
    }
}