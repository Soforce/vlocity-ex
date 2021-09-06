# Order Management Integration with TMF Specifications
## Overview
Vlocity extension package is a unlocked package to extend the functionalities of Vlocity CMT managed package. 
Here is the list of features included in the extension package:

* **[ProductOrder Submission](#productorder-submission)**  
blabla...

## <a id="productorder-submission"></a> Sumbit ProductOrder with OM Callout Task
Custom functions for Dataraptor are provided by this package. The "DRHelper.xml" manifest file is created under the "projects" folder. You can execute the following sfdx command to deploy "Datarapator helper functions" to your org:  
* **deploy without tests**
```
sfdx force:source:deploy -x projects/DRHelper.xml -u {orgName}
```
* **deploy with tests**
```
sfdx force:source:deploy -x projects/DRHelper.xml -u {orgName} -l RunSpecifiedTests -r vLoggerTest,vHelperTest,vDRHelperTest
```
The custom metadata type for custom functions are included in the manifest file.

### <a id="dataraptor-helper-QueryAggregate"></a> QueryAggregate
You can exeute aggregate SOQL query and return the aggregated results with the helper function.
#### Signature
```
QueryAggregate(queryString, arg1, arg2, ...)
```
#### Parameters
* ***queryString***  
  The template query string with arguments to be substituted with arg1, arg2 which follows the same [String.format(...)](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_string.htm#apex_System_String_format) pattern.
* ***arg1, arg2,...***  
  The actual value(s) used to substitute the argument(s) in the queryString.  

#### Example
Get aggregated recurring and onetime totals by the product family of a given quote by QuoteId.
```
QueryAggregate("SELECT Product2.Family Family, SUM(vlocity_cmt__OneTimeTotal__c) NRC, SUM(vlocity_cmt__RecurringTotal__c) MRC FROM QuoteLineItem WHERE QuoteId=''{0}'' GROUP BY Product2.Family", %QuoteId%)
```
Notice, two single quote ('') is needed to quote the paramter inside the queryString.   
Here is a sample result:
```
{
  "QuoteSummary": [
    {
      "attributes": {
        "type": "AggregateResult"
      },
      "Family": "Internet",
      "NRC": 0,
      "MRC": 105
    },
    {
      "attributes": {
        "type": "AggregateResult"
      },
      "Family": "Services",
      "NRC": 1000,
      "MRC": 575
    }
  ]
}
```
