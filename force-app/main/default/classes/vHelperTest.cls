@isTest
public class vHelperTest {
    public static String JSONAttributeStrV1 = '{"ACAT_ACC":[{"$$AttributeDefinitionStart$$":null,"objectid__c":"01t1I0000017hbSQAQ","attributeid__c":"a0K1I0000019ltpUAA","attributecategoryid__c":"a0J1I000000u9qlUAA","categorycode__c":"ACAT_ACC","categoryname__c":"Accessories","attributeuniquecode__c":"ATT_DT_AT","attributeconfigurable__c":true,"attributedisplaysequence__c":"1","attributefilterable__c":true,"attributecloneable__c":true,"isactive__c":true,"attributedisplayname__c":"Accessory Type","displaysequence__c":"50","categorydisplaysequence__c":50,"customconfiguitemplate__c":null,"formatmask__c":null,"hasrule__c":false,"isconfigurable__c":true,"ishidden__c":false,"valueinnumber__c":null,"objecttype__c":"Product2","querycode__c":null,"isreadonly__c":true,"isquerydriven__c":false,"querylabel__c":null,"id":"a0H1I000000o8ksUAA","isrequired__c":false,"rulemessage__c":null,"uidisplaytype__c":"Dropdown","value__c":"Audio","valuedatatype__c":"Picklist","valuedescription__c":null,"isnottranslatable__c":false,"attributegrouptype__c":null,"attributeRunTimeInfo":{"dataType":"Picklist","uiDisplayType":"Dropdown","default":[{"value":"Audio","id":30,"displayText":"Audio"}],"values":[{"value":"Chargers","id":10,"displayText":"Chargers"},{"value":"Cases","id":20,"displayText":"Cases"},{"value":"Audio","id":30,"displayText":"Audio"}],"selectedItem":{"value":"Audio","id":30,"displayText":"Audio"}},"$$AttributeDefinitionEnd$$":null},{"$$AttributeDefinitionStart$$":null,"objectid__c":"01t1I0000017hbSQAQ","attributeid__c":"a0K1I000003JDxVUAW","attributecategoryid__c":"a0J1I000000u9qlUAA","categorycode__c":"ACAT_ACC","categoryname__c":"Accessories","attributeuniquecode__c":"ATT_DURATION","attributeconfigurable__c":true,"attributedisplaysequence__c":"10","attributefilterable__c":false,"attributecloneable__c":true,"isactive__c":true,"attributedisplayname__c":"Duration","displaysequence__c":"null","categorydisplaysequence__c":50,"customconfiguitemplate__c":null,"formatmask__c":null,"hasrule__c":false,"isconfigurable__c":true,"ishidden__c":false,"valueinnumber__c":null,"objecttype__c":"Product2","querycode__c":null,"isreadonly__c":false,"isquerydriven__c":false,"querylabel__c":null,"id":"a0H1I000006ueDZUAY","isrequired__c":false,"rulemessage__c":null,"uidisplaytype__c":"Dropdown","value__c":null,"valuedatatype__c":"Picklist","valuedescription__c":null,"isnottranslatable__c":false,"attributegrouptype__c":null,"attributeRunTimeInfo":{"dataType":"Picklist","uiDisplayType":"Dropdown","values":[{"value":"1 Year","id":10,"displayText":"1 Year"},{"value":"2 Year","id":20,"displayText":"2 Year"},{"value":"3 Year","id":30,"displayText":"3 Year"}],"default":[],"selectedItem":{}},"$$AttributeDefinitionEnd$$":null}]}';
    public static String JSONAttributeStrV2 = '{"ATT_ROUTER_OPTN":"AT&T Managed","ATT_BILL_OPT":"Flat Rate","ATT_INTERFACE":"100Base-TXElectrical","ATT_SPEED":"150 Mbps","ATT_MBCSPD":null,"ATT_LCTP":null,"ATT_SHIPREQ":null}';
 
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

        System.debug(vHelper.isV2Attribute('8027j000001ktTyAAI'));

    }
}
