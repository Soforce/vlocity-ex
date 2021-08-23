@isTest
public class vJsonAttributeViewerControllerTest {
    public static SObject getLineItemMock(Id recordId) {
        Product2 p = new Product2(
            Id = '01t7j000002UElHAAW',
            vlocity_cmt__JSONAttribute__c = '{"VLO-PRO-0001":[{"$$AttributeDefinitionStart$$":null,"objectid__c":"01t5e000000LD9MAAW","attributeid__c":"a0J5e000000TTDVEA4","attributecategoryid__c":"a0I5e000000XdtTEAS","categorycode__c":"VLO-PRO-0001","categoryname__c":"TV Channels","attributeuniquecode__c":"ATTRIBUTE-021","attributeconfigurable__c":true,"attributedisplaysequence__c":"2","attributefilterable__c":false,"isactive__c":true,"attributedisplayname__c":"Genre","displaysequence__c":"9","formatmask__c":null,"hasrule__c":false,"isconfigurable__c":false,"ishidden__c":false,"valueinnumber__c":null,"objecttype__c":"Product2","querycode__c":null,"isreadonly__c":true,"isquerydriven__c":false,"querylabel__c":null,"id":"a0H5e000001QJehEAG","isrequired__c":false,"rulemessage__c":null,"uidisplaytype__c":"Text","value__c":"Kids, Adventure","valuedatatype__c":"Text","valuedescription__c":"The type of genres that are included in this package","attributecloneable__c":false,"customconfiguitemplate__c":null,"categorydisplaysequence__c":9,"isnottranslatable__c":false,"attributegrouptype__c":null,"attributeRunTimeInfo":{"dataType":"Text","uiDisplayType":"Text","default":"Kids, Adventure"},"$$AttributeDefinitionEnd$$":null}]}',
            vlocity_cmt__AttributeMetadata__c = '{"totalSize" : 1,"messages" : [ ],"records" : [ {"messages" : [ ],"displaySequence" : 9,"Code__c" : "VLO-PRO-0001","Name" : "TV Channels","id" : "a0I5e000000XdtTEAS","productAttributes" : {"totalSize" : 1,"messages" : [ ],"records" : [ {"messages" : [ ],"code" : "ATTRIBUTE-021","dataType" : "text","inputType" : "text","multiselect" : false,"required" : false,"readonly" : true,"disabled" : true,"filterable" : false,"attributeId" : "a0J5e000000TTDVEA4","label" : "Genre","displaySequence" : 2,"hasRules" : false,"description" : "The type of genres that are included in this package","hidden" : false,"cloneable" : false,"isNotTranslatable" : false,"values" : [ {"readonly" : true,"disabled" : true,"defaultValue" : "Kids, Adventure"} ],"userValues" : null} ]}} ]}',
            vlocity_cmt__AttributeDefaultValues__c = '{"ATTRIBUTE-021":"Kids, Adventure"}'
        );

        
        OrderItem lineItem = new OrderItem(
            Id = recordId,
            Product2 = p,
            vlocity_cmt__JSONAttribute__c = '{"VLO-PRO-0001":[{"$$AttributeDefinitionStart$$":null,"objectid__c":"01t36000001CmNdAAK","attributeid__c":"a0J36000000rXqKEAU","attributecategoryid__c":"a0I36000001YsHHEA0","categorycode__c":"VLO-PRO-0001","categoryname__c":"TV Channels","attributeuniquecode__c":"ATTRIBUTE-021","attributeconfigurable__c":true,"attributedisplaysequence__c":"2","attributefilterable__c":false,"isactive__c":true,"attributedisplayname__c":"Genre","displaysequence__c":"9","formatmask__c":null,"hasrule__c":false,"isconfigurable__c":false,"ishidden__c":false,"valueinnumber__c":null,"objecttype__c":"Product2","querycode__c":null,"isreadonly__c":true,"isquerydriven__c":false,"querylabel__c":null,"id":"a0H36000002rZqDEAU","isrequired__c":false,"rulemessage__c":null,"uidisplaytype__c":null,"value__c":"Kids, Adventure","valuedatatype__c":"Text","valuedescription__c":"The type of genres that are included in this package","attributeRunTimeInfo":{"dataType":"Text","default":"Kids, Adventure","value":"Kids, Adventure"},"$$AttributeDefinitionEnd$$":null}]}',
            vlocity_cmt__AttributeMetadataChanges__c = '{"ATTRIBUTE-021":{"isNotTranslatable":null}}',
            vlocity_cmt__AttributeSelectedValues__c = '{"ATTRIBUTE-021":"Kids, Adventure"}'
        );

        return lineItem;
    }


    @isTest
    private static void testAll() {
        Id lineItemId = '8027j000001kp42AAA';
        Map<String, Object> newVals = new Map<String, Object> {
            'ATTRIBUTE-021' => 'Kids, Home'
        };
        // Test v1JSON
        vHelperTest.v2Attribute = false; 
        {
            vJsonAttributeViewerController.JSONAttribute jsonAttribute = vJsonAttributeViewerController.getJSONAttribute(lineItemId);
            Map<String, Object> attributeValues = vJsonAttributeViewerController.getAttributeValues(lineItemId);
            vJsonAttributeViewerController.setAttributeValues(lineItemId, newVals);
        }
         
        // Test v2JSON
        vHelperTest.v2Attribute = true; 
        {
            vJsonAttributeViewerController.JSONAttribute jsonAttribute = vJsonAttributeViewerController.getJSONAttribute(lineItemId);
            Map<String, Object> attributeValues = vJsonAttributeViewerController.getAttributeValues(lineItemId);
            vJsonAttributeViewerController.setAttributeValues(lineItemId, newVals);
        }
            // vJsonAttributeViewerController.setAttributeValues(lineItemId)



        System.debug(vJsonAttributeViewerController.getJSONAttribute('8027j000001kp42AAA'));
    }
}
