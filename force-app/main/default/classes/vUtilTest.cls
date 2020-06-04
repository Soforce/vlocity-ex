@isTest
private class vUtilTest {
    @isTest
    private static void testAll() {
        Account a1 = new Account(Name = 'ACME');
        Account a2 = new Account(Name = 'Salesforce');
        insert new Account[] { a1, a2 };

        Map<String, List<Object>> diffMap = (Map<String, List<Object>>)vUtil.compareSObjs(a1.Id, a2.Id);
        // System.debug(diffMap);
        System.assertEquals(true, diffMap.containsKey('name'));
    }
}
