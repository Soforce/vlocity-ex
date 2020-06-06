@isTest
private class vOrchestrationAttributesTest {
    public static Map<String, Object> setupTestData() {
        List<Product2> pds = new List<Product2> {
            new Product2(
                Name = 'Test Product - Parent',
                ProductCode = 'TP-PARENT'
            ),
            new Product2(
                Name = 'Test Product - Child',
                ProductCode = 'TP-CHILD'
            )
        };
        insert pds;

        List<PricebookEntry> pbes = new List<PricebookEntry> {
            new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(), 
                UnitPrice = 100, 
                Product2Id = pds[0].Id, 
                IsActive = true
            ),
            new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(), 
                UnitPrice = 50, 
                Product2Id = pds[1].Id, 
                IsActive = true
            )
        };
        insert pbes;


        Account account = new Account(Name = 'Soforce');
        insert account;

        Order order = new Order(
            AccountId = account.Id,
            EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(), 
            Status = 'Draft'
        );
        insert order;

        List<OrderItem> oLIs = new List<OrderItem> {
            new OrderItem(
                OrderId = order.Id,
                PricebookEntryId = pbes[0].Id, 
                Quantity = 1, 
                UnitPrice = 100, 
                Product2Id = pds[0].Id,
                vlocity_cmt__Product2Id__c = pds[0].Id,
                vlocity_cmt__Action__c = 'Add', 
                vlocity_cmt__LineNumber__c = '0001',
                vlocity_cmt__JSONAttribute__c = vHelperTest.JSONAttributeStr
            ),
            new OrderItem(
                OrderId = order.Id,
                PricebookEntryId = pbes[1].Id, 
                Quantity = 1, 
                UnitPrice = 50, 
                Product2Id = pds[1].Id,
                vlocity_cmt__Product2Id__c = pds[1].Id,
                vlocity_cmt__Action__c = 'Add', 
                vlocity_cmt__LineNumber__c = '0001.0001',
                vlocity_cmt__JSONAttribute__c = vHelperTest.JSONAttributeStr
            )
        };
        insert oLIs;

        vlocity_cmt__FulfilmentRequest__c fr = new vlocity_cmt__FulfilmentRequest__c(
            vlocity_cmt__AccountId__c = account.Id,
            vlocity_cmt__Status__c = 'New' 
        );
        List<vlocity_cmt__FulfilmentRequestLine__c> frls = new List<vlocity_cmt__FulfilmentRequestLine__c> {
            new vlocity_cmt__FulfilmentRequestLine__c(
                // vlocity_cmt__FulfilmentRequestID__c = fr.Id,
                vlocity_cmt__Product2Id__c = pds[0].Id,
                vlocity_cmt__Action__c = 'Add',
                // vlocity_cmt__LineNumber__c = '0001',
                vlocity_cmt__JSONAttribute__c = vHelperTest.JSONAttributeStr                
            ),
            new vlocity_cmt__FulfilmentRequestLine__c(
                // vlocity_cmt__FulfilmentRequestID__c = fr.Id,
                vlocity_cmt__Product2Id__c = pds[1].Id,
                vlocity_cmt__Action__c = 'Add',
                // vlocity_cmt__LineNumber__c = '0001',
                vlocity_cmt__JSONAttribute__c = vHelperTest.JSONAttributeStr                
            )
        };
        insert new SObject[] { fr, frls[0], frls[1] };
        frls[0].vlocity_cmt__FulfilmentRequestID__c = fr.Id;
        frls[0].vlocity_cmt__LineNumber__c = frls[0].Id + '.0001';
        frls[1].vlocity_cmt__FulfilmentRequestID__c = fr.Id;
        frls[1].vlocity_cmt__LineNumber__c = frls[1].Id + '.0001';
        update frls;

        return new Map<String, Object> {
            'account' => account,
            'order' => order,
            'oLIs' => oLIs,
            'fr' => fr,
            'frls' => frls
        };
    }

    @isTest
    private static void test_readOrchestrationItemData_OLI() {
        Map<String, Object> testData = setupTestData();
        vlocity_cmt__OrchestrationPlan__c plan = new vlocity_cmt__OrchestrationPlan__c();
        insert plan;

        vlocity_cmt__OrchestrationItem__c item = new vlocity_cmt__OrchestrationItem__c(
            vlocity_cmt__OrchestrationPlanId__c = plan.Id,
            vlocity_cmt__OrderItemId__c = ((OrderItem[])testData.get('oLIs'))[0].Id

        );
        insert item;

        vOrchestrationItemAttributes.Request[] requests = new List<vOrchestrationItemAttributes.Request> {
            new vOrchestrationItemAttributes.Request(item.Id)
        };
        List<vOrchestrationItemAttributes.Result> results = vOrchestrationItemAttributesGetter.readOrchestrationItemData(requests);
        
        System.assertEquals(((Account)testData.get('account')).Id, results[0].item.account_id);
    }

    @isTest
    private static void test_readOrchestrationItemData_FRLs() {
        Map<String, Object> testData = setupTestData();
        vlocity_cmt__OrchestrationPlan__c plan = new vlocity_cmt__OrchestrationPlan__c();
        insert plan;

        vlocity_cmt__OrchestrationItem__c[] items = new List<vlocity_cmt__OrchestrationItem__c> {
            new vlocity_cmt__OrchestrationItem__c(
                vlocity_cmt__OrchestrationPlanId__c = plan.Id,
                vlocity_cmt__FulfilmentRequestLineId__c = ((vlocity_cmt__FulfilmentRequestLine__c[])testData.get('frls'))[0].Id
            ), 
            new vlocity_cmt__OrchestrationItem__c(
                vlocity_cmt__OrchestrationPlanId__c = plan.Id,
                vlocity_cmt__FulfilmentRequestLineId__c = ((vlocity_cmt__FulfilmentRequestLine__c[])testData.get('frls'))[1].Id
            )
        };
        insert items;

        vOrchestrationItemAttributes.Request[] requests = new List<vOrchestrationItemAttributes.Request> {
            new vOrchestrationItemAttributes.Request(new List<Id> { items[0].Id, items[1].Id })
        };
        List<vOrchestrationItemAttributes.Result> results = vOrchestrationItemAttributesGetter.readOrchestrationItemData(requests);
        System.assertEquals(null, results[0].item);
        System.assertEquals(2, results[0].items.size());
    }
}
