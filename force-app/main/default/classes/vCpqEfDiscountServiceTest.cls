@isTest
private with sharing class vCpqEfDiscountServiceTest {
    @isTest
    private static void testAll() {
        Id myPBId = Test.getStandardPricebookId();

        Account myAccount = new Account(
            Name = 'Test Account'
        );

        // Insert Product
        Product2 myProduct = new Product2(
            Name = ' Test Product',
            Description='Test Product Entry 1',
            ProductCode = 'ABC',
            IsActive = true
        );

        

        vlocity_cmt__EntityFilter__c myEF = new vlocity_cmt__EntityFilter__c(
            Name = 'Test EF',
            vlocity_cmt__FilterOnObjectName__c = 'OrderItem',
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__Type__c = 'Qualification'
        );

        
        insert new SObject[] { myAccount, myEF, myProduct } ;
   

        PricebookEntry myPE = new PricebookEntry(
            Pricebook2Id = myPBId,
            Product2Id = myProduct.Id,
            UnitPrice = 1,
            IsActive = true,
            UseStandardPrice = false
        );

        vlocity_cmt__Catalog__c myCatalog = new vlocity_cmt__Catalog__c(
            vlocity_cmt__CatalogCode__c = 'Test Catalog',
            vlocity_cmt__IsActive__c = true,
            EntityFilterId__c = myEF.Id
        );
           
        vlocity_cmt__AccountDiscount__c myAccountDisc = new vlocity_cmt__AccountDiscount__c(
            Name = 'Test Account Discount',
            vlocity_cmt__AccountId__c = myAccount.Id,
            vlocity_cmt__EffectiveStartDate__c = Datetime.now().addDays(-1)
        );

        Order myOrder = new Order(
            AccountId = myAccount.Id,
            Name = 'Test Order',
            Status = 'Draft',
            Pricebook2Id =  myPBId,
            EffectiveDate = Date.today()
        );

        Contract myContract = new Contract(
            AccountId = myAccount.Id,
            Name = 'Test Contract',
            StartDate = Date.today(),
            // Status = 'Activated',
            vlocity_cmt__IsFrameContract__c = true
        );


        insert new SObject[] { myCatalog, myAccountDisc, myOrder, myContract, myPE};

        vlocity_cmt__AccountDiscountItem__c myAccountDiscItem = new vlocity_cmt__AccountDiscountItem__c(
            vlocity_cmt__AccountDiscountId__c = myAccountDisc.Id,
            vlocity_cmt__CatalogCategoryId__c = myCatalog.Id
        );

        vlocity_cmt__AccountDiscountPricing__c myAccountDiscPricing = new vlocity_cmt__AccountDiscountPricing__c(
            vlocity_cmt__AccountDiscountId__c = myAccountDisc.Id,
            vlocity_cmt__AdjustmentValue__c = -100,
            vlocity_cmt__PricingVariableId__c = null
        );

        vlocity_cmt__ContractVersion__c myContractVer = new vlocity_cmt__ContractVersion__c(
            Name = 'Version 1',
            vlocity_cmt__ContractId__c = myContract.Id
        );

        vlocity_cmt__OrderDiscount__c myOrderDisc = new vlocity_cmt__OrderDiscount__c(
            vlocity_cmt__Action__c = 'New',
            Name = 'Test Order Discount',
            vlocity_cmt__DiscountType__c = 'Order',
            vlocity_cmt__OrderId__c = myOrder.Id
        );

        insert new SObject[] { myAccountDiscItem, myAccountDiscPricing, myContractVer, myOrderDisc };
        myContract.vlocity_cmt__ActiveContractVersionId__c = myContractVer.Id;
        myContract.Status = 'Activated';
        update myContract;

        //
        vlocity_cmt__ContractVersionDiscount__c myContractDisc = new vlocity_cmt__ContractVersionDiscount__c(
            Name = 'Test Contract Version Discount',
            vlocity_cmt__ContractVersionId__c = myContractVer.Id,
            vlocity_cmt__EffectiveStartDate__c = Datetime.now().addDays(-1)
        );

        vlocity_cmt__OrderDiscountItem__c myOrderDiscItem = new vlocity_cmt__OrderDiscountItem__c(
            vlocity_cmt__OrderDiscountId__c = myOrderDisc.Id,
            vlocity_cmt__CatalogCategoryId__c = myCatalog.Id
        );

        vlocity_cmt__OrderDiscountPricing__c myOrderDiscPricing = new vlocity_cmt__OrderDiscountPricing__c(
            vlocity_cmt__OrderDiscountId__c = myOrderDisc.Id,
            vlocity_cmt__AdjustmentValue__c = -75
        );

        insert new SObject[] {myContractDisc, myOrderDiscItem, myOrderDiscPricing};
        //
        vlocity_cmt__ContractVersionDiscountItem__c myContractDiscItem = new vlocity_cmt__ContractVersionDiscountItem__c(
            vlocity_cmt__CatalogCategoryId__c = myCatalog.Id,
            vlocity_cmt__ContractVersionDiscountId__c = myContractDisc.Id
        );
        vlocity_cmt__ContractVersionDiscountPricing__c myCotractDiscPricing = new vlocity_cmt__ContractVersionDiscountPricing__c(
            vlocity_cmt__AdjustmentValue__c = -25,
            vlocity_cmt__ContractVersionDiscountId__c = myContractDisc.Id
        );

        OrderItem oLI = new OrderItem(
            OrderId = myOrder.Id,
            Quantity = 1,
            UnitPrice = 240,
            Product2Id = myProduct.Id,
            PricebookEntryId = myPE.Id
        );
        insert new SObject[] {myContractDiscItem, myCotractDiscPricing, oLI};

  
        // Start Test
        vCpqEfDiscountService service = new vCpqEfDiscountService();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', myOrder);
        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', new SObject[] { oLI });

        service.invokeMethod('ApplyFilterBasedDiscount', input, output, options);
        System.debug([SELECT Count() FROM vlocity_cmt__OrderAppliedPromotion__c]);
        System.debug([SELECT Count() FROM vlocity_cmt__OrderAppliedPromotionItem__c]);
        System.debug([SELECT Count() FROM vlocity_cmt__OrderPriceAdjustment__c]);

        service.invokeMethod('ApplyFilterBasedDiscount', input, output, options);
    }
}
