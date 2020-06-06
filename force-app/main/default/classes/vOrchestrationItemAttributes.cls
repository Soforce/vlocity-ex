/**
 * @description
 */
public class vOrchestrationItemAttributes {
    @AuraEnabled
    public Id item_id;
    
    @AuraEnabled
    public Id order_id;

    @AuraEnabled
    public Id account_id;

    @AuraEnabled
    public vOrchestrationOrderItemAttributes order_item;

    public vOrchestrationItemAttributes() {
    }

    public class Result {
        @InvocableVariable(label='Item' description='A single OrchestrationItemAttributes record is returned from the given ItemId')
        public vOrchestrationItemAttributes item;
        public Result(vOrchestrationItemAttributes item) {
            this.item = item;
        }
        
        @InvocableVariable(label='Items' description='OrchestrationItemAttributes records are returned from the given ItemIds')
        public List<vOrchestrationItemAttributes> items;
        public Result(vOrchestrationItemAttributes[] items) {
            this.items = items;
        }

    }  
   
    public class Request {
        @InvocableVariable(label='ItemId' description='Retrieve single OrchestrationItemAttributes for single orchestration item')
        public Id orchestrationItemId;
        @InvocableVariable(label='ItemIds' description='Retrieve a list of OrchestrationItemAttributes for orchestration items')
        public List<Id> orchestrationItemIds;
        
        public Request() {}

        public Request(Id orchestrationItemId) {
            this.orchestrationItemId = orchestrationItemId;
        }  
        
        public Request(List<Id> orchestrationItemIds) {
            this.orchestrationItemIds = orchestrationItemIds;
        }  
    }

}