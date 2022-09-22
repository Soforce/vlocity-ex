DELETE [SELECT Id FROM vlocity_cmt__CustomFieldMap__c 
        WHERE (vlocity_cmt__SourceSObjectType__c = 'QuoteLineItem' AND vlocity_cmt__DestinationSObjectType__c = 'vlocity_cmt__ContractLineItem__c') 
            OR (vlocity_cmt__SourceSObjectType__c = 'vlocity_cmt__ContractLineItem__c' AND vlocity_cmt__DestinationSObjectType__c = 'QuoteLineItem')
            OR (vlocity_cmt__SourceSObjectType__c = 'OrderItem' AND vlocity_cmt__DestinationSObjectType__c = 'vlocity_cmt__ContractLineItem__c')
            OR (vlocity_cmt__SourceSObjectType__c = 'vlocity_cmt__ContractLineItem__c' AND vlocity_cmt__DestinationSObjectType__c = 'OrderItem')];