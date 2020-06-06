@isTest
public with sharing class vJSONAttributeTest {
    @isTest
    private static void test_Getter() {
        vlocity_cmt__FulfilmentRequestLine__c item = new vlocity_cmt__FulfilmentRequestLine__c(
            vlocity_cmt__JSONAttribute__c = vHelperTest.JSONAttributeStr                
        );
        insert item;

        List<vJSONAttributeGetter.Request> reqs = new List<vJSONAttributeGetter.Request> { new vJSONAttributeGetter.Request(item.Id) };
        vJSONAttributeGetter.Response[] resps = vJSONAttributeGetter.getAttributes(reqs);

        System.debug(JSON.serialize(resps));
        System.assertEquals(2, resps[0].attributes.size());

        reqs = new List<vJSONAttributeGetter.Request> { new vJSONAttributeGetter.Request(item.Id, 'ATT_DT_AT') };
        resps = vJSONAttributeGetter.getAttributes(reqs);

        System.debug(JSON.serialize(resps));
        System.assertEquals('Audio', resps[0].attribute.value);
    }

    @isTest
    private static void test_Setter() {
        vlocity_cmt__FulfilmentRequestLine__c item = new vlocity_cmt__FulfilmentRequestLine__c(
            vlocity_cmt__JSONAttribute__c = vHelperTest.JSONAttributeStr                
        );
        insert item;


        vNameValuePair[] attributes = new List<vNameValuePair> {
            new vNameValuePair('ATT_DT_AT', 'Chargers'),
            new vNameValuePair('ATT_DURATION', '1 Year')
        };

        List<vJSONAttributeSetter.Request> reqs = new List<vJSONAttributeSetter.Request> { new vJSONAttributeSetter.Request(item.Id, attributes[0]) };
        vJSONAttributeSetter.setAttributes(reqs);
        item = [SELECT vlocity_cmt__JSONAttribute__c FROM vlocity_cmt__FulfilmentRequestLine__c WHERE Id=:item.Id];
        String val = (String)vHelper.getJSONAttributeValue(item.vlocity_cmt__JSONAttribute__c, 'ATT_DT_AT');
        System.assertEquals('Chargers', val);

        reqs = new List<vJSONAttributeSetter.Request> { new vJSONAttributeSetter.Request(item.Id, attributes) };
        vJSONAttributeSetter.setAttributes(reqs);
        item = [SELECT vlocity_cmt__JSONAttribute__c FROM vlocity_cmt__FulfilmentRequestLine__c WHERE Id=:item.Id];
        Map<String, Object> attrVals = vHelper.getJSONAttributeValues(item.vlocity_cmt__JSONAttribute__c);
        System.debug(JSON.serialize(attrVals));
        System.assertEquals('Chargers', (String)attrVals.get('ATT_DT_AT'));
        System.assertEquals('1 Year', (String)attrVals.get('ATT_DURATION'));
    }
}
