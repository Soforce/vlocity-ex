@isTest
private class vFlowAutoTaskTest {
    @isTest
    private static void test_executeBatch() {
        vlocity_cmt__OrchestrationPlan__c plan = new vlocity_cmt__OrchestrationPlan__c();
        insert plan;
        
        vlocity_cmt__OrchestrationItem__c item = new vlocity_cmt__OrchestrationItem__c(
            vlocity_cmt__OrchestrationPlanId__c = plan.Id,
            vlocity_cmt__AutoTaskParameters__c = JSON.serialize(new Map<String, String> {
                'flowName' => 'Build_OM_Runtime_Dependencies'
            })
        );
        insert item;

        Test.startTest();
        vFlowAutoTask flowTask = new vFlowAutoTask();
        flowTask.executeBatch(new List<vlocity_cmt__OrchestrationItem__c> { item });

        // Should throw ex
        try {
            flowTask.executeBatch(new List<vlocity_cmt__OrchestrationItem__c>());
        } catch (Exception ex) {
            
        }
        Test.stopTest();

    }
}
