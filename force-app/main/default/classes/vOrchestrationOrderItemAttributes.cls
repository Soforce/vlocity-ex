/**
 * 
 */
public with sharing class vOrchestrationOrderItemAttributes {
    @AuraEnabled
    public Id order_item_id;
    
    @AuraEnabled
    public Id service_account_id;

    @AuraEnabled
    public String action;

    @AuraEnabled
    public Id product_id;

    @AuraEnabled
    public String product_code;

    @AuraEnabled
    public String product_name;

    @AuraEnabled
    public List<vNameValuePair> described_by;

    @AuraEnabled
    public List<vOrchestrationOrderItemAttributes> order_items;


    public vOrchestrationOrderItemAttributes() {
        described_by = new List<vNameValuePair>();
        order_items = new List<vOrchestrationOrderItemAttributes>();
    }
}