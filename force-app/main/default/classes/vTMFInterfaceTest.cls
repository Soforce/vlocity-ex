@isTest
private class vTMFInterfaceTest {
    @isTest
    private static void SubmitProductOrder_test() {
        vTMFInterface.SubmitProductOrder submitPO = new vTMFInterface.SubmitProductOrder();
        submitPO.generatePayload(null, null); 
    }
}