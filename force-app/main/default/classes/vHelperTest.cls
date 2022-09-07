@isTest
public class vHelperTest {
    public static String JSONAttributeStrV1 = '{"ACAT_ACC":[{"$$AttributeDefinitionStart$$":null,"objectid__c":"01t1I0000017hbSQAQ","attributeid__c":"a0K1I0000019ltpUAA","attributecategoryid__c":"a0J1I000000u9qlUAA","categorycode__c":"ACAT_ACC","categoryname__c":"Accessories","attributeuniquecode__c":"ATT_DT_AT","attributeconfigurable__c":true,"attributedisplaysequence__c":"1","attributefilterable__c":true,"attributecloneable__c":true,"isactive__c":true,"attributedisplayname__c":"Accessory Type","displaysequence__c":"50","categorydisplaysequence__c":50,"customconfiguitemplate__c":null,"formatmask__c":null,"hasrule__c":false,"isconfigurable__c":true,"ishidden__c":false,"valueinnumber__c":null,"objecttype__c":"Product2","querycode__c":null,"isreadonly__c":true,"isquerydriven__c":false,"querylabel__c":null,"id":"a0H1I000000o8ksUAA","isrequired__c":false,"rulemessage__c":null,"uidisplaytype__c":"Dropdown","value__c":"Audio","valuedatatype__c":"Picklist","valuedescription__c":null,"isnottranslatable__c":false,"attributegrouptype__c":null,"attributeRunTimeInfo":{"dataType":"Picklist","uiDisplayType":"Dropdown","default":[{"value":"Audio","id":30,"displayText":"Audio"}],"values":[{"value":"Chargers","id":10,"displayText":"Chargers"},{"value":"Cases","id":20,"displayText":"Cases"},{"value":"Audio","id":30,"displayText":"Audio"}],"selectedItem":{"value":"Audio","id":30,"displayText":"Audio"}},"$$AttributeDefinitionEnd$$":null},{"$$AttributeDefinitionStart$$":null,"objectid__c":"01t1I0000017hbSQAQ","attributeid__c":"a0K1I000003JDxVUAW","attributecategoryid__c":"a0J1I000000u9qlUAA","categorycode__c":"ACAT_ACC","categoryname__c":"Accessories","attributeuniquecode__c":"ATT_DURATION","attributeconfigurable__c":true,"attributedisplaysequence__c":"10","attributefilterable__c":false,"attributecloneable__c":true,"isactive__c":true,"attributedisplayname__c":"Duration","displaysequence__c":"null","categorydisplaysequence__c":50,"customconfiguitemplate__c":null,"formatmask__c":null,"hasrule__c":false,"isconfigurable__c":true,"ishidden__c":false,"valueinnumber__c":null,"objecttype__c":"Product2","querycode__c":null,"isreadonly__c":false,"isquerydriven__c":false,"querylabel__c":null,"id":"a0H1I000006ueDZUAY","isrequired__c":false,"rulemessage__c":null,"uidisplaytype__c":"Dropdown","value__c":null,"valuedatatype__c":"Picklist","valuedescription__c":null,"isnottranslatable__c":false,"attributegrouptype__c":null,"attributeRunTimeInfo":{"dataType":"Picklist","uiDisplayType":"Dropdown","values":[{"value":"1 Year","id":10,"displayText":"1 Year"},{"value":"2 Year","id":20,"displayText":"2 Year"},{"value":"3 Year","id":30,"displayText":"3 Year"}],"default":[],"selectedItem":{}},"$$AttributeDefinitionEnd$$":null}]}';
    public static String JSONAttributeStrV2 = '{"ATT_ROUTER_OPTN":"AT&T Managed","ATT_BILL_OPT":"Flat Rate","ATT_INTERFACE":"100Base-TXElectrical","ATT_SPEED":"150 Mbps","ATT_MBCSPD":null,"ATT_LCTP":null,"ATT_SHIPREQ":null}';
 
    public static String AttributeMetadata = '{"totalSize" : 1,"messages" : [ ],"records" : [ {"messages" : [ ],"displaySequence" : 30,"Code__c" : "ACAT_BBM_HARDWARE_DETAILS","Name" : "Hardware Details","id" : "a0s2f000000THQ5AAO","productAttributes" : {"totalSize" : 1,"messages" : [ ],"records" : [ {"messages" : [ ],"code" : "ATT_BBM_SC_TYPE","dataType" : "text","inputType" : "dropdown","multiselect" : false,"required" : false,"readonly" : true,"disabled" : true,"filterable" : true,"attributeId" : "a0t2f000000rJetAAE","label" : "Type","displaySequence" : 10,"hasRules" : false,"hidden" : false,"cloneable" : true,"isNotTranslatable" : false,"values" : [ {"id" : "24e142fa-ef83-f639-b071-cc3681108422","label" : "eSim","readonly" : false,"disabled" : false,"value" : "eSim","displaySequence" : 10}, {"id" : "fb3ede60-be92-0ef0-8cd3-e8f87fc5c238","label" : "Standard","readonly" : false,"disabled" : false,"value" : "Standard","displaySequence" : 20}, {"id" : "3860e474-8a7a-fd2b-13fb-7cd9029f2524","label" : "MicroSim","readonly" : false,"disabled" : false,"value" : "MicroSim","displaySequence" : 30}, {"id" : "ff4ca0bc-bd28-cf2c-d046-f1f7ad8c6fdd","label" : "NanoSim","readonly" : false,"disabled" : false,"value" : "NanoSim","displaySequence" : 40} ],"userValues" : null} ]}} ]}';
    public static String AttributeSelectedValues = '{"ATT_BBM_SC_TYPE":"MicroSim"}';

    // v2Attribute flag used for test methods
    public static Boolean v2Attribute = false;
    public static Boolean isV2AttributeMock(SObjectType itemObjectType) {
        return v2Attribute;
    }
    
    @isTest
    private static void testAll() {
        String jsonAttrStr;
        
        // v1
        jsonAttrStr = JSONAttributeStrV1; 
        System.assertEquals('Audio', (String)vHelper.getJSONAttributeValue(jsonAttrStr, 'ATT_DT_AT'));

        jsonAttrStr = vHelper.setJSONAttribute(jsonAttrStr, 'ATT_DT_AT', 'Chargers');
        System.assertEquals('Chargers', (String)vHelper.getJSONAttributeValue(jsonAttrStr, 'ATT_DT_AT'));

        // v2
        jsonAttrStr = JSONAttributeStrV2;
        // System.assertEquals('ATT_ROUTER_OPTN', (String)vHelper.getJSONAttributeValue(jsonAttrStr, 'AT&T Managed'));
        
        jsonAttrStr = vHelper.setJSONAttribute(jsonAttrStr, 'ATT_ROUTER_OPTN', 'BYOR');
        System.assertEquals('BYOR', (String)vHelper.getJSONAttributeValue(jsonAttrStr, 'ATT_ROUTER_OPTN'));

        // System.debug(vHelper.isV2Attribute('8027j000001ktTyAAI'));

    }

    @isTest
    private static void test_executeFieldMapper() {
        vlocity_cmt__CustomFieldMap__c[] mappings = new List<vlocity_cmt__CustomFieldMap__c> {
            new vlocity_cmt__CustomFieldMap__c(
                Name = '1',
                vlocity_cmt__SourceSObjectType__c = 'QuoteLineItem',
                vlocity_cmt__DestinationSObjectType__c = 'OpportunityLineItem',
                vlocity_cmt__SourceFieldName__c= 'Description',
                vlocity_cmt__DestinationFieldName__c = 'Description'
            ),
            new vlocity_cmt__CustomFieldMap__c(
                Name = '2',
                vlocity_cmt__SourceSObjectType__c = 'QuoteLineItem',
                vlocity_cmt__DestinationSObjectType__c = 'OpportunityLineItem',
                vlocity_cmt__SourceFieldName__c= 'vlocity_cmt__RecurringCharge__c',
                vlocity_cmt__DestinationFieldName__c = 'vlocity_cmt__RecurringCharge__c'
            )
        };

        insert mappings;

        QuoteLineItem qLI = new QuoteLineItem(
            Description = 'Test Quote',
            vlocity_cmt__RecurringCharge__c = 100
        );
        OpportunityLineItem oLI = new OpportunityLineItem();

        vHelper.executeFieldMapper(qLI, oLI);

        System.assertEquals(100, oLI.vlocity_cmt__RecurringCharge__c);
    }    

}