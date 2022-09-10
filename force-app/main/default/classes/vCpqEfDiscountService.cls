/**
 * @description Service class to support EntityFilter based Discounts
 */
global with sharing class vCpqEfDiscountService implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod (String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        vLogger.writeInfo('Enter vCpqEfDiscountService.' + methodName);
        try {
            if (methodName == 'ApplyFilterBasedDiscount') {
                return applyFilterBasedDiscount(input, output, options);
            }

            return true;
        }
        catch (Exception ex) {
            vLogger.write(ex);
            return false;
        } finally {
            vLogger.writeInfo('Exit vCpqEfDiscountService.' + methodName);
        }
    }

    private Boolean applyFilterBasedDiscount(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        SObject parent = (SObject)vlocity_cmt.PricingPlanService.getFromPricingContext('Parent'); // cart object
        Id accountId = (Id)parent.get('AccountId');
        Id cartId = parent.Id;
        List<SObject> itemList = (List<SObject>)vlocity_cmt.PricingPlanService.getFromPricingContext('LineItemList');

        // Debug...
        for (SObject item : itemList) {
            item.put('vlocity_cmt__Action__c', 'Change');
            System.debug('Set to Change');
        }


        Map<Id, SObject> discountMap = getAllApplicableFilterBasedDiscounts(cartId, accountId);
        vLogger.writeVar('discountMap', discountMap);

        Map<Id, List<SObject>> efDiscountsMap = getFilterDiscountsMap(cartId, discountMap);
        vLogger.writeVar('efDiscountsMap', efDiscountsMap);

        Map<Id, Set<Id>> filterItemIdsMap = executeDiscountEntityFilter(cartId, itemList, efDiscountsMap);
        vLogger.writeVar('filterItemIdsMap', filterItemIdsMap);

        Boolean matched = false;
        for (Set<Id> itemIds : filterItemIdsMap.values()) {
            if (itemIds.size() > 0) {
                matched = true;
                break;
            }
        }

        if (matched) {
            Map<Id, SObject> appliedDiscountMap = getAppliedDiscounts(cartId, discountMap);
            vLogger.writeVar('appliedDiscountMap', appliedDiscountMap);

            Map<Id, List<Id>> discountItemIdsMap = getFilterBasedDiscountItems(cartId, itemList, filterItemIdsMap, efDiscountsMap, discountMap, appliedDiscountMap);
            vLogger.writeVar('discountItemIdsMap', discountItemIdsMap);
            
            applyFilterBasedDiscounts(cartId, discountItemIdsMap, discountMap, appliedDiscountMap);
        }

        return true;
    }

    /**
     * @description retrieve all applicabile filter based discounts for the given cart
     */
    public Map<Id, SObject> getAllApplicableFilterBasedDiscounts(Id cartId, Id accountId) {
        Datetime currentDatetime = Datetime.now();
        String cartObjName = cartId.getSObjectType().getDescribe().getName();
         // Cart (Opportunity/Quote/Order) Discount
        String qry = 'SELECT Id, Name, vlocity_cmt__AppliesToAllItems__c, vlocity_cmt__Description__c,vlocity_cmt__ReferenceNumber__c, vlocity_cmt__EffectiveStartDate__c, vlocity_cmt__EffectiveEndDate__c, vlocity_cmt__Action__c, vlocity_cmt__ApprovalStatus__c, vlocity_cmt__DiscountType__c, vlocity_cmt__Status__c, vlocity_cmt__Duration__c, vlocity_cmt__DurationUnitOfMeasure__c, vlocity_cmt__{0}Id__c, ' + 
                            '(SELECT Id,vlocity_cmt__CatalogCategoryId__c, vlocity_cmt__CatalogCategoryId__r.EntityFilterId__c, vlocity_cmt__ProductId__c, vlocity_cmt__Description__c FROM vlocity_cmt__{0}DiscountItems__r WHERE vlocity_cmt__CatalogCategoryId__r.EntityFilterId__c!=NULL), '  + 
                            '(SELECT Id,vlocity_cmt__AdjustmentValue__c,vlocity_cmt__Amount__c,vlocity_cmt__PricingVariableId__c,vlocity_cmt__TimePlanId__c,vlocity_cmt__TimePolicyId__c FROM vlocity_cmt__{0}DiscountPricing__r) '  +  
                        'FROM vlocity_cmt__{0}Discount__c ' +
                        'WHERE vlocity_cmt__{0}Id__c=:cartId ' + 
                        'AND ( vlocity_cmt__EffectiveEndDate__c = null OR vlocity_cmt__EffectiveEndDate__c < :currentDatetime ) ';
        qry = String.format(qry, new List<String> { cartObjName });
        List<SObject> cartDiscounts = Database.query(qry);

       // Contract (Version) Discount
        List<String> contractStatus = new List<String> { 'Activated' };
        List<vlocity_cmt__ContractVersionDiscount__c> contractDiscounts = [
            SELECT Id, Name, vlocity_cmt__AppliesToAllItems__c, vlocity_cmt__Description__c, vlocity_cmt__ReferenceNumber__c, vlocity_cmt__EffectiveStartDate__c, vlocity_cmt__EffectiveEndDate__c, vlocity_cmt__ContractVersionId__c, vlocity_cmt__DiscountTemplateId__c,
                    (SELECT Id,vlocity_cmt__CatalogCategoryId__c, vlocity_cmt__CatalogCategoryId__r.EntityFilterId__c, vlocity_cmt__ProductId__c, vlocity_cmt__Description__c FROM vlocity_cmt__ContractVersionDiscountItems__r WHERE vlocity_cmt__CatalogCategoryId__r.EntityFilterId__c!=NULL), 
                    (SELECT Id,vlocity_cmt__AdjustmentValue__c,vlocity_cmt__Amount__c,vlocity_cmt__PricingVariableId__c,vlocity_cmt__TimePlanId__c,vlocity_cmt__TimePolicyId__c FROM vlocity_cmt__ContractVersionDiscountPricing__r) 
            FROM vlocity_cmt__ContractVersionDiscount__c
            WHERE vlocity_cmt__ContractVersionId__c IN (
                        Select vlocity_cmt__ActiveContractVersionId__c 
                            FROM Contract 
                            WHERE vlocity_cmt__IsFrameContract__c=True AND Status IN :contractStatus AND AccountId=:accountId AND
                                StartDate <= :Date.today() AND (EndDate >= :Date.today() OR EndDate=NULL) 
                )
                AND (
                    (vlocity_cmt__EffectiveStartDate__c = NULL OR vlocity_cmt__EffectiveStartDate__c <= :currentDatetime) 
                    AND (vlocity_cmt__EffectiveEndDate__c >= :currentDatetime OR vlocity_cmt__EffectiveEndDate__c = NULL)
                )
                // AND vlocity_cmt__ReferenceNumber__c NOT IN ('6843f192-b59b-9a38-845e-ab3fce133a29')  
        ];   
        
        
        // Account Discount
        List<vlocity_cmt__AccountDiscount__c> accountDiscounts = [
            SELECT Id, Name, vlocity_cmt__AppliesToAllItems__c, vlocity_cmt__Description__c,vlocity_cmt__ReferenceNumber__c, vlocity_cmt__EffectiveStartDate__c, vlocity_cmt__EffectiveEndDate__c, vlocity_cmt__AccountId__c,vlocity_cmt__Duration__c, vlocity_cmt__DurationUnitOfMeasure__c,
                    (SELECT Id,vlocity_cmt__CatalogCategoryId__c, vlocity_cmt__CatalogCategoryId__r.EntityFilterId__c, vlocity_cmt__ProductId__c, vlocity_cmt__Description__c FROM vlocity_cmt__AccountDiscountItems__r WHERE vlocity_cmt__CatalogCategoryId__r.EntityFilterId__c!=NULL), 
                    (SELECT Id,vlocity_cmt__AdjustmentValue__c,vlocity_cmt__Amount__c,vlocity_cmt__PricingVariableId__c,vlocity_cmt__TimePlanId__c,vlocity_cmt__TimePolicyId__c FROM vlocity_cmt__AccountDiscountPricing__r) 
            FROM vlocity_cmt__AccountDiscount__c
            WHERE vlocity_cmt__AccountId__c=:accountId
                AND ( vlocity_cmt__EffectiveStartDate__c = null OR vlocity_cmt__EffectiveStartDate__c < :currentDatetime )  
                AND ( vlocity_cmt__EffectiveEndDate__c = null OR vlocity_cmt__EffectiveEndDate__c > :currentDatetime )  
                // AND vlocity_cmt__ReferenceNumber__c NOT IN :refNumList  
    
        ];

        Map<String, List<SObject>> discounts = new Map<String, List<SObject>> {
            'CartDiscounts' => cartDiscounts,
            'AccountDiscounts' => accountDiscounts,
            'ContractDiscounts' => contractDiscounts
        };

        Map<Id, SObject> discountMap = new Map<Id, SObject>();
        discountMap.putAll(new Map<Id, SObject>(cartDiscounts));
        discountMap.putAll(new Map<Id, SObject>(accountDiscounts));
        discountMap.putAll(new Map<Id, SObject>(contractDiscounts));

   
        return discountMap;
    }

    /**
     * @description retrieve all applied discounts by discount Id
     */
    public Map<Id, SObject> getAppliedDiscounts(Id cartId, Map<Id, SObject> discountMap) {
        String cartObjName = cartId.getSobjectType().getDescribe().getName();
        String qryStr = 'SELECT Id, Name, vlocity_cmt__Action__c, vlocity_cmt__SubAction__c, vlocity_cmt__Sequence__c, vlocity_cmt__PromotionId__c, vlocity_cmt__ReasonForCancellation__c,' + 
                        ' vlocity_cmt__AccountDiscountId__c, vlocity_cmt__ContractDiscountId__c, vlocity_cmt__' + cartObjName + 'DiscountId__c, vlocity_cmt__' + cartObjName + 'Id__c,' +
                        ' vlocity_cmt__RequestDate__c, vlocity_cmt__AppliesTo__c, vlocity_cmt__PricingStartDate__c, vlocity_cmt__PricingEndDate__c,' +
                        ' vlocity_cmt__CommitmentStartDate__c, vlocity_cmt__CommitmentEndDate__c, vlocity_cmt__ContractId__c,' +
                        ' (SELECT Id, vlocity_cmt__AppliedAction__c, vlocity_cmt__' + cartObjName + (cartObjName != 'Order' ? 'Line' : '') + 'ItemId__c, vlocity_cmt__MaximumChildItemQuantity__c, vlocity_cmt__MinimumChildItemQuantity__c, vlocity_cmt__MaxQuantity__c, vlocity_cmt__MinQuantity__c FROM vlocity_cmt__' + + cartObjName + 'AppliedPromotionAffectedItems__r),' + 
                        ' (SELECT Id, vlocity_cmt__Action__c,vlocity_cmt__SubAction__c, vlocity_cmt__AdjustmentValue__c,vlocity_cmt__Amount__c,vlocity_cmt__AppliesTo__c, vlocity_cmt__ContractId__c,' + 
                        ' vlocity_cmt__PricingVariableId__c, vlocity_cmt__' + cartObjName + 'ItemId__c, vlocity_cmt__Source__c, vlocity_cmt__EstimatedStartDate__c, vlocity_cmt__EstimatedEndDate__c,' +
                        ' vlocity_cmt__OverrideDefinitionId__c, vlocity_cmt__PriceListEntryId__c, vlocity_cmt__PricingVariableCode__c, vlocity_cmt__PromotionId__c, vlocity_cmt__TimePlanId__c, vlocity_cmt__TimePolicyId__c,' + 
                        ' vlocity_cmt__Sequence__c, vlocity_cmt__RequestDate__c FROM vlocity_cmt__' + cartObjName + 'PricingAdjustments__r)' +
                        ' FROM vlocity_cmt__' + cartObjName + 'AppliedPromotion__c' +
                        ' WHERE vlocity_cmt__' + cartObjName + 'Id__c=:cartId';
        vLogger.writeVar('qryStr', qryStr);
        List<SObject> appliedDiscounts = Database.query(qryStr);
        vLogger.writeVar('appliedDiscounts', appliedDiscounts);

        Map<Id, SObject> discAppliedMap = new Map<Id, SObject>();
        Map<Id, Set<Id>> discAppliedItemMap = new Map<Id, Set<Id>>();
        for (SObject appliedDisc : appliedDiscounts) {
            Id discId = (Id)appliedDisc.get('vlocity_cmt__' + cartObjName + 'DiscountId__c');
            if (discId == null) discId = (Id)appliedDisc.get('vlocity_cmt__ContractDiscountId__c');
            if (discId == null) discId = (Id)appliedDisc.get('vlocity_cmt__AccountDiscountId__c');

            if (discId != null) {
                discAppliedMap.put(discId, appliedDisc);
            }

            List<SObject> adjs = appliedDisc.getSObjects('vlocity_cmt__' + cartObjName + 'PricingAdjustments__r');
            if (adjs != null) {
                Set<Id> itemIds = new Set<Id>();
                for (SObject adj : adjs) {
                    itemIds.add((Id)adj.get('vlocity_cmt__' + cartObjName + 'ItemId__c'));
                }
                discAppliedItemMap.put(discId, itemIds);
            }
        }

        Map<String, Object> appliedDiscountsMap = new Map<String, Object> {
            'AppliedDiscountMap' => discAppliedMap, // Discount Id to applied Discount Map
            'AppliedAdjustmentsMap' => discAppliedItemMap // Discount Id to applied pricing adjustments Map
        };

        return discAppliedMap;
    }

    /**
     * 
     */
    public Map<Id, List<SObject>> getFilterDiscountsMap(Id cartId, Map<Id, SObject> discountMap) {
        Map<Id, List<SObject>> efDiscountsMap = new Map<Id, List<SObject>>();
        for (Id discId : discountMap.keySet()) {
            String discItemsRelName;
            if (discId.getSObjectType() == vlocity_cmt__ContractVersionDiscount__c.SObjectType) {
                discItemsRelName = 'vlocity_cmt__ContractVersionDiscountItems__r';
            } else if (discId.getSObjectType() == vlocity_cmt__AccountDiscount__c.SObjectType) {
                discItemsRelName = 'vlocity_cmt__AccountDiscountItems__r';
            } else /* CartDiscount */ {
                discItemsRelName = 'vlocity_cmt__' + cartId.getSobjectType().getDescribe().getName() + 'DiscountItems__r';
            }

            SObject discount = discountMap.get(discId);
            List<SObject> discItems = discount.getSObjects(discItemsRelName);
            if (discItems != null) {
                for (SObject discItem : discItems) {
                    // Discount with the EntityFilter associated 
                    vlocity_cmt__Catalog__c catalog = (vlocity_cmt__Catalog__c)discItem.getSObject('vlocity_cmt__CatalogCategoryId__r');
                    Id efId = catalog.EntityFilterId__c;
                    List<SObject> efDiscounts = efDiscountsMap.get(efId);
                    if (efDiscounts == null) {
                        efDiscounts= new List<SObject>();
                        efDiscountsMap.put(efId, efDiscounts);
                    }
                    efDiscounts.add(discount);
                }  
            }
        }

        return efDiscountsMap;
    }

    /**
     * @description 
     */
    public Map<Id, Set<Id>> executeDiscountEntityFilter(Id cartId, List<SObject> xLIs, Map<Id, List<SObject>> efDiscountsMap) {
        // Execute EntityFilter to filter out xLIs
        List<Id> efIds = new List<Id>(efDiscountsMap.keySet());
        vlocity_cmt.EntityFilterSupport efSupport = new vlocity_cmt.EntityFilterSupport();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        input.put('objectIds', new List<Id>((new Map<Id, SObject>(xLIs)).keySet()));
        // input.put('sObjectsList', xLIs);
        input.put('entityFilterIds', efIds);
        input.put('variablesMap',  new Map<String, Object>());
        input.put('variableNameToType', new Map<String, String>());
        if (!Test.isRunningTest()) {
            efSupport.invokeMethod('executeFilters', input, output, null);
        } else {
            Map<Id, Set<Id>> filterIdToObjectIds = new Map<Id, Set<Id>>();
            Set<Id> itemIds = new Map<Id, SObject>(xLIs).keySet();
            for (Id efId : efIds) {
                filterIdToObjectIds.put(efId, itemIds);
            }
            output.put('filterIdToObjectIds', filterIdToObjectIds);
        }
        Map<Id, Set<Id>> filterIdToObjectIds = (Map<Id, Set<Id>>) output.get('filterIdToObjectIds');
        
        return filterIdToObjectIds;
    }
    
    
    public Map<Id, List<Id>> getFilterBasedDiscountItems(Id cartId, List<SObject> xLIs, Map<Id, Set<Id>> filterItemIdsMap, Map<Id, List<SObject>> efDiscountsMap, Map<Id, SObject> discountMap, Map<Id, SObject> appliedDiscountMap) {
        Map<Id, Set<Id>> appliedDiscountItemsMap = new Map<Id, Set<Id>>();
        for (Id discId : appliedDiscountMap.keySet()) {
            SObject appliedDiscount = appliedDiscountMap.get(discId);
            Set<Id> appliedItemIds = new Set<Id>();
            appliedDiscountItemsMap.put(discId, appliedItemIds);
            List<SObject> adjs = appliedDiscount.getSObjects('vlocity_cmt__' + cartId.getSobjectType().getDescribe().getName() + 'PricingAdjustments__r');
            if (adjs != null) {
                for (SObject adj : adjs) {
                    appliedItemIds.add((Id)adj.get('vlocity_cmt__' + cartId.getSobjectType().getDescribe().getName() + 'ItemId__c'));
                }
            }
        }
        vLogger.writeVar('appliedDiscountItemsMap', appliedDiscountItemsMap);

        Map<Id, List<Id>> discountItemIdsMap = new Map<Id, List<Id>>();
        for (Id efId : filterItemIdsMap.keySet()) {
            Set<Id> itemIds =  filterItemIdsMap.get(efId);
            List<SObject> discs = efDiscountsMap.get(efId);
            if (itemIds.size() > 0 && discs.size() > 0) {
                for (SObject disc : discs) {
                    Set<Id> appliedItemIds = appliedDiscountItemsMap.get(disc.Id);

                    for (Id itemId : itemIds) {
                        if (appliedItemIds == null || !appliedItemIds.contains(itemId)) {
                            List<Id> discItems = discountItemIdsMap.get(disc.Id);
                            if (discItems == null) {
                                discItems = new List<Id>();
                                discountItemIdsMap.put(disc.Id, discItems);
                            }
                            discItems.add(itemId);
                        }
                    }
                }
            }
        }

        return discountItemIdsMap;
    }

    
    public SObject createAppliedDiscount(Id cartId, SObject discount) {
        String cartObjName = cartId.getSobjectType().getDescribe().getName();
        SObject appliedDiscount;
        if (cartObjName == 'Quote') {
            appliedDiscount = new vlocity_cmt__QuoteAppliedPromotion__c();
        } else if (cartObjName == 'Order') {
            appliedDiscount = new vlocity_cmt__OrderAppliedPromotion__c();
        } else {
            appliedDiscount = new vlocity_cmt__OpportunityAppliedPromotion__c();
        }
        appliedDiscount.put('vlocity_cmt__Action__c', 'Add');
        if (discount.getSObjectType() == vlocity_cmt__ContractVersionDiscount__c.SObjectType) {
            appliedDiscount.put('vlocity_cmt__ContractDiscountId__c', discount.Id);
        } else if (discount.getSObjectType() == vlocity_cmt__AccountDiscount__c.SObjectType) {
            appliedDiscount.put('vlocity_cmt__AccountDiscountId__c', discount.Id);
        } else /* CartDiscount */ {
            appliedDiscount.put('vlocity_cmt__' + cartObjName + 'DiscountId__c', discount.Id);
        }

        appliedDiscount.put('vlocity_cmt__' + cartObjName + 'Id__c', cartId);

        return appliedDiscount;
    }

    public SObject createAppliedDiscountItem(Id cartId, Id itemId, SObject appliedDiscount, SObject discount) {
        SObject discountItem;
        String cartObjName = cartId.getSobjectType().getDescribe().getName();
        if (cartObjName == 'Quote') {
            discountItem = new vlocity_cmt__QuoteAppliedPromotionItem__c();
        } else if (cartObjName == 'Order') {
            discountItem = new vlocity_cmt__OrderAppliedPromotionItem__c();
        } else if (cartObjName == 'Opportunity') {
            discountItem = new vlocity_cmt__OpportunityAppliedPromotionItem__c();
            cartObjName = 'Opportunity';
        }

        discountItem.put('vlocity_cmt__' + cartObjName + 'AppliedPromotionId__c', appliedDiscount.Id);
        discountItem.put('vlocity_cmt__AppliedAction__c', 'Add');
        discountItem.put('vlocity_cmt__' + cartObjName + 'ItemId__c', itemId);

        return discountItem;
    }

    public SObject createAppliedDiscountAdjustment(Id cartId, Id itemId, SObject appliedDiscount, SObject discount) {
        SObject pricingAdjustment;

        SObject[] discountPricings;
        if (discount.getSObjectType() == vlocity_cmt__ContractVersionDiscount__c.SObjectType) {
            discountPricings = discount.getSObjects('vlocity_cmt__ContractVersionDiscountPricing__r');
        } else if (discount.getSObjectType() == vlocity_cmt__AccountDiscount__c.SObjectType) {
            discountPricings = discount.getSObjects('vlocity_cmt__AccountDiscountPricing__r');
        } else /*CartDiscount*/ {
            discountPricings = discount.getSObjects('vlocity_cmt__' + cartId.getSobjectType().getDescribe().getName() + 'DiscountPricing__r');
        }

        // TODO: Handle the multiple discount pricing entries in the same discount in the future
        SObject discountPricing = discountPricings[0];
        String cartObjName = cartId.getSobjectType().getDescribe().getName();
        if (cartObjName == 'Quote') {
            pricingAdjustment = new vlocity_cmt__QuotePricingAdjustment__c();
        } else if (cartObjName == 'Order') {
            pricingAdjustment = new vlocity_cmt__OrderPriceAdjustment__c();
        } else if (cartObjName == 'Opportunity') {
            pricingAdjustment = new vlocity_cmt__OpportunityPriceAdjustment__c();
            cartObjName = 'Opportunity';
        }

        pricingAdjustment.put('vlocity_cmt__' + cartObjName + 'AppliedPromotionId__c', appliedDiscount.Id);
        pricingAdjustment.put('vlocity_cmt__Action__c', 'Add');
        pricingAdjustment.put('vlocity_cmt__Source__c', 'Discount');
        pricingAdjustment.put('vlocity_cmt__PricingVariableId__c', discountPricing.get('vlocity_cmt__PricingVariableId__c'));
        pricingAdjustment.put('vlocity_cmt__AdjustmentValue__c', discountPricing.get('vlocity_cmt__AdjustmentValue__c'));
        pricingAdjustment.put('vlocity_cmt__Amount__c', discountPricing.get('vlocity_cmt__Amount__c'));
        pricingAdjustment.put('vlocity_cmt__' + cartObjName + 'Id__c', cartId);
        pricingAdjustment.put('vlocity_cmt__' + cartObjName + 'ItemId__c', itemId);
        pricingAdjustment.put('vlocity_cmt__Sequence__c', 4001);

        return pricingAdjustment;
    }

    /**
     * @description apply discounts (EntityFilter based) to qualified line items
     */
    public void applyFilterBasedDiscounts(Id cartId, Map<Id, List<Id>> discountItemIdsMap, Map<Id, SObject> discountMap, Map<Id, SObject> appliedDiscountMap) {
        List<SObject> appliedDiscountsToInsert = new List<SObject>();
        for (Id discId : discountItemIdsMap.keySet()) {
            SObject appliedDiscount = appliedDiscountMap.get(discId);
            if (appliedDiscount == null) {
                appliedDiscount = createAppliedDiscount(cartId, discountMap.get(discId));
                appliedDiscountMap.put(discId, appliedDiscount);

                appliedDiscountsToInsert.add(appliedDiscount);
            }
        }
        vLogger.writeVar('appliedDiscountsToInsert', appliedDiscountsToInsert);
        Database.insert(appliedDiscountsToInsert);

        List<SObject> appliedItems = new List<SObject>();
        List<SObject> appliedAdjustments = new List<SObject>();
        for (Id discId : discountItemIdsMap.keySet()) {
            SObject appliedDiscount = appliedDiscountMap.get(discId);
            SObject discount = discountMap.get(discId);
            List<Id> itemIds = discountItemIdsMap.get(discId);
            for (Id itemId : itemIds) {
                appliedItems.add(createAppliedDiscountItem(cartId, itemId, appliedDiscount, discount));
                appliedAdjustments.add(createAppliedDiscountAdjustment(cartId, itemId, appliedDiscount, discount));
            }
        }

        List<SObject> appliedChildrenToInsert = new List<SObject>();
        appliedChildrenToInsert.addAll(appliedItems);
        appliedChildrenToInsert.addAll(appliedAdjustments);

        vLogger.writeVar('appliedChildrenToInsert', appliedChildrenToInsert);
        Database.insert(appliedChildrenToInsert);

    }
}
