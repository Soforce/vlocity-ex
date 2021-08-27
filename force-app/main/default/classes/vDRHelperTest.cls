@isTest
private class vDRHelperTest {
    @isTest
    private static void test_StructureJsonConverter() {
        String payload ='{"name":"Soforce","specification.id":"123","specification.name":"456","relatedParty[owner].name":"Jyue","relatedParty[owner].role":"owner","parent.child[1].name":"Mike","parent.child[1].age":"24","parent.child[2].name":"Michelle","parent.child[2].age":"12","parent.Mike.name":"Mike","parent.Mike.age":"24","parent.Michelle.name":"Michelle","parent.Michelle.age":"12"}';
        Object flatJSON = (Map<String, Object>)JSON.deserializeUntyped(payload);
        
        vDRHelper.JSONT jsont = new vDRHelper.JSONT();
        Map<String, Object> input = new Map<String, Object> {
            'arguments' => new List<Object> {
                flatJSON, true
            }
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Boolean result = jsont.invokeMethod('toStructure', input, output, options); // (flatJSON, 'name', 'value');
        System.debug(JSON.serialize(output));

        payload = '[{"name":"name","value":"Soforce"},{"name":"relatedParty[owner].name","value":"Jyue"},{"name":"relatedParty[owner].role","value":"owner"},{"name":"specification.id","value":"123"},{"name":"specification.name","value":"456"}]';
        flatJSON = (List<Object>)JSON.deserializeUntyped(payload);
        input = new Map<String, Object> {
            'arguments' => new List<Object> {
                flatJSON, false, 'name', 'value'
            }
        };
        result = jsont.invokeMethod('toStructure', input, output, options);
        System.debug(JSON.serialize(output));
    }
}
