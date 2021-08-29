@isTest
private class vDRHelperTest {
    @isTest
    private static void test_QueryAggregateAndQueryEx() {
        // select name, count(id) from vlocity_cmt__CpqConfigurationSetup__c group by name
        vlocity_cmt__CpqConfigurationSetup__c[] testData = new List<vlocity_cmt__CpqConfigurationSetup__c> {
            new vlocity_cmt__CpqConfigurationSetup__c(name='1-1', vlocity_cmt__SetupValue__c='group1'),
            new vlocity_cmt__CpqConfigurationSetup__c(name='1-2', vlocity_cmt__SetupValue__c='group1'),
            new vlocity_cmt__CpqConfigurationSetup__c(name='2', vlocity_cmt__SetupValue__c='group2')
        };
        insert testData;

        // Test QueryAggregate
        Map<String, Object> input = new Map<String, Object> {
            'arguments' => new Object[] {
                'SELECT {0}, COUNT(id) FROM vlocity_cmt__CpqConfigurationSetup__c GROUP BY {0}',
                'vlocity_cmt__SetupValue__c'
            }
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        vlocity_cmt.VlocityOpenInterface helper = new vDRHelper();
        helper.invokeMethod('QueryAggregate', input, output, options);
        Object[] result = (Object[])output.get('result');
        System.assertEquals(2, result.size());

        System.debug(output);

        // Test QueryEx
        input = new Map<String, Object> {
            'arguments' => new Object[] {
                'SELECT Name, vlocity_cmt__SetupValue__c FROM vlocity_cmt__CpqConfigurationSetup__c WHERE Name=\'2\''
            }
        };
        output = new Map<String, Object>();
        
        helper.invokeMethod('QueryEx', input, output, options);
        result = (Object[])output.get('result');
        System.assertEquals(1, result.size());

        System.debug(output);
    }

    @isTest
    private static void test_GetLineItemAttributes() {
        // v1 Attribute Model
        vHelperTest.v2Attribute = false;

        Map<String, Object> input = new Map<String, Object> {
            'arguments' => new Object[] {
                vHelperTest.JSONAttributeStrV1,
                true
            }
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        vlocity_cmt.VlocityOpenInterface helper = new vDRHelper();
        helper.invokeMethod('GetLineItemAttributes', input, output, options);
        Object[] result = (Object[])output.get('result');       
        System.debug(JSON.serialize(output));
        System.assertEquals(1, result.size());
       
        // v2 Attribute Model
        vHelperTest.v2Attribute = true;

        input = new Map<String, Object> {
            'arguments' => new Object[] {
                vHelperTest.AttributeSelectedValues,
                vHelperTest.AttributeMetadata,
                true
            }
        };
        output = new Map<String, Object>();
        helper = new vDRHelper();
        helper.invokeMethod('GetLineItemAttributes', input, output, options);
        result = (Object[])output.get('result');       
        System.debug(JSON.serialize(output));
        System.assertEquals(1, result.size());
    }

    @isTest
    private static void test_ToProductHierarchy() {
        List<Map<String, Object>> items = new List<Map<String, Object>> {
            new Map<String, Object> {
                'product' => 'Back to school',
                'vlocity_cmt__LineNumber__c' => '0001'
            },
            new Map<String, Object> {
                'product' => 'Phone Number',
                'vlocity_cmt__LineNumber__c' => '0001.0001'
            },
            new Map<String, Object> {
                'product' => 'SIM',
                'vlocity_cmt__LineNumber__c' => '0001.0002'
            },
            new Map<String, Object> {
                'product' => 'Apple iPhone X',
                'vlocity_cmt__LineNumber__c' => '0002'
            }
        };
        Map<String, Object> input = new Map<String, Object> {
            'arguments' => items
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        vlocity_cmt.VlocityOpenInterface helper = new vDRHelper();
        helper.invokeMethod('ToProductHierarchy', input, output, options);
        Object[] result = (Object[])output.get('result');       
        System.debug(JSON.serialize(output));
        System.assertEquals(2, result.size());        
    }

    @isTest
    private static void test_ToStructureJson() {
        String payload ='{"name":"Soforce","specification.id":"123","specification.name":"456","relatedParty[owner].name":"Jyue","relatedParty[owner].role":"owner","parent.child[1].name":"Mike","parent.child[1].age":"24","parent.child[2].name":"Michelle","parent.child[2].age":"12","parent.Mike.name":"Mike","parent.Mike.age":"24","parent.Michelle.name":"Michelle","parent.Michelle.age":"12"}';
        Object flatJSON = (Map<String, Object>)JSON.deserializeUntyped(payload);
        
        vlocity_cmt.VlocityOpenInterface helper = new vDRHelper();
        Map<String, Object> input = new Map<String, Object> {
            'arguments' => new List<Object> {
                flatJSON, true
            }
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Boolean result = helper.invokeMethod('ToStructureJson', input, output, options); // (flatJSON, 'name', 'value');
        System.debug(JSON.serialize(output));
        System.assertNotEquals(null, result);

        payload = '[{"name":"name","value":"Soforce"},{"name":"relatedParty[owner].name","value":"Jyue"},{"name":"relatedParty[owner].role","value":"owner"},{"name":"specification.id","value":"123"},{"name":"specification.name","value":"456"}]';
        flatJSON = (List<Object>)JSON.deserializeUntyped(payload);
        ((List<Object>)flatJSON).addAll(new List<Object> { false, 'name', 'value' });
        input = new Map<String, Object> {
            'arguments' => flatJSON
        };
        result = helper.invokeMethod('ToStructureJson', input, output, options);
        System.debug(JSON.serialize(output));
        System.assertNotEquals(null, result);
    }
}