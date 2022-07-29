global with sharing class vCpqDiscountService implements vlocity_cmt.VlocityOpenInterface, callable {
    global Boolean invokeMethod (String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        vLogger.writeInfo('Enter vCpqDiscountService.' + methodName);
        // System.debug('vCpqDiscountService.' + methodName);
        try {
            if (methodName == 'ApplyFilterBasedDiscount') {

            }

            return true;
        }
        catch (Exception ex) {
            vLogger.write(ex);
            return false;
        } finally {
            vLogger.writeInfo('Exit vCpqDiscountService.' + methodName);
        }
    }

    private void applyFilterBasedDiscount(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {

    }
}
