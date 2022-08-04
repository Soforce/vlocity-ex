# Vlocity Extension (Vlocity-ex) Package
## Overview
Vlocity extension package is a unlocked package to extend the functionalities of Vlocity CMT managed package. 
Here is the list of features included in the extension package:

* **[Helper Methods](#generic-helper)**  
The custom functions provided includes:
  * **[executeFieldMapper](#generic-helper-executeFieldMapper)**  
    Copy the values from source object to the target based on FieldMapper.  

* **[Dataraptor Helper Functions](#dataraptor-helper)**  
The custom functions provided includes:
  * **[QueryAggregate](#dataraptor-helper-QueryAggregate)**  
    Execute aggregate SOQL and return the aggregated results. 
  * **[QueryEx](#dataraptor-helper-QueryEx)**  
    Enhance the OOTB QUERY function to execute a SOQL query that returns a JSON list of object instead of one column. Both child-to-parent and parent-to-child [SOQL relationships](https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_relationships_query_using.htm) are supported.
  * **[GetLineItemAttributes](#dataraptor-helper-GetLineItemAttributes)**  
    Return the list of JSON attributes for the given OpportunityLineItem, QuoteLineItem, OrderItem and vlocity_cmt__ContractLineItem__c record. Both v1 and v2 Attribute Models are supported.
  * **[ToProductHierarchy](#dataraptor-helper-ToProductHierarchy)**  
    Convert the list (flat) of line items to the hierarchy based on the product structure. The conversation uses the vlocity_cmt__LineNumber__c field to re-construct the structure of line items. 
  * **[ToStructureJson](#dataraptor-helper-ToStructureJson)**  
    Convert a list of attribute name & value pairs into the structured JSON by the attribute name. For example: *{ "parent.child": "some value" }* is converted to *{ 
      "parent": { "child": "some value" } }*.   

* **[Add Products to Cart (PostCartsItems) with Configuration (Attributes)](#add-products-with-cfg)**  
This solution provides you the ability to set attribute values on adding products to the cart with postCartsItems CPQ API. Similar to set field values with the "fieldsToUpdate", a new "attributesToUpdate" is added to the postCartsItems API. Follow the instructions to install and configure the manifest (addProductsWithCfg.xml) file and no extra coding is required. 

* **[Discount with Filter-Based Product Catalog](#ef-based-discount)**  
The solution allows you to use entity filter to define the qualifed products for a given discount instead of pre-selected products or catalogs in the design time. 

* **[Vlocity JSON Attribute Viewer](#json-attribute-viewer)**  
With Vlocity JSON Attribute Viewer, you can view and modify Vlocity attributes of a xLI record much faster and easier because you don't need to work with the fancy raw JSON blob anymore.  
Vlocity JSON Attribute Viewer is a Lightning Web Component which can be dropped into any SObject which supports JSONAttribut. Both v1 and v2 Attribute models are supported.  


* **[Order Management API Integration via TMF Specifications](OM-TMF.md)**


*  **[Using Lightning Flow in Vlocity OM (WIP)](#flow-in-om)**  
By applying the power of low-code, drag-and-drop functionality to customer engagement, Lightning Flow delivers an innovative new way for businesses to realize the benefits of process automation. This feature helps you to extend Vlocity OM automation task with the lighting flow.

## <a id="generic-helper"></a> Helper Methods
Utility or helper methods.
### <a id="generic-helper-executeFieldMapper"></a> executeFieldMapper
Copy the field values from the source sobject to the target based on the FieldMappers.
#### Signature
```
executeFieldMapper(sourceObj, targetObj)
```
#### Parameters
* ***sourceObj***  
  The source sobject.
* ***targetObj***  
  The target sobject.  

#### Return
The target sobject is returned.

## <a id="dataraptor-helper"></a> Helper Functions for Dataraptor
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

### <a id="dataraptor-helper-QueryEx"></a> QueryEx
This is an enhanced version of OOTB Query function. Multiple fields can be returned by the query. Both child-to-parent and parent-to-child relationships are supported. 
#### Signature
```
QueryEx(queryString, arg1, arg2, ...)
```
#### Parameters
* ***queryString***  
  The template query string with arguments to be substituted with arg1, arg2 which follows the same [String.format(...)](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_string.htm#apex_System_String_format) pattern.
* ***arg1, arg2,...***  
  The actual value(s) used to substitute the argument(s) in the queryString.  

#### Example
Get the account name and contact records (parent-to-child relationship) of a given account record.
```
QueryEx("SELECT Id, Name, (SELECT Id, FirstName, LastName FROM Contacts) FROM Account WHERE Id=''{0}''", %AccountId%)
```
Here is a sample result:
```
{
  "Account": {
    "attributes": {
      "type": "Account",
      "url": "/services/data/v52.0/sobjects/Account/0015e000003Ei1hAAC"
    },
    "Id": "0015e000003Ei1hAAC",
    "Name": "Smith - San Francisco Residence",
    "RecordTypeId": "0125e000000J0LWAA0",
    "Contacts": {
      "totalSize": 1,
      "done": true,
      "records": [
        {
          "attributes": {
            "type": "Contact",
            "url": "/services/data/v52.0/sobjects/Contact/0035e000002OTWXAA4"
          },
          "AccountId": "0015e000003Ei1hAAC",
          "Id": "0035e000002OTWXAA4",
          "FirstName": "Jenny",
          "LastName": "Smith"
        }
      ]
    }
  }
}
```
The contact records are embeded in the parent account record.

### <a id="dataraptor-helper-GetLineItemAttributes"></a> GetLineItemAttributes
Parse the attribute JSON blob into a list of attribute values of a given line item. It supports both **v2** and **v1** Attribute Model. The order of attribute values is determined by "Display Sequence" field for the attribute category and attribute itself.
#### Signature
##### v1 Attribute Model
```
GetLineItemAttributes(JSONAttribute, skipEmptyAttribute)
```
##### v2 Attribute Model
```
GetLineItemAttributes(attributeSelectedValues, attributeMetadata, skipEmptyAttribute)
```
#### Parameters
* ***JSONAttribute***  
  The JSON blob from *vlocity_cmt__JSONAttribute__c* field. This is used for v1 Attribute Model.
* ***attributeSelectedValues***  
  The JSON string from *vlocity_cmt__AttributeSelectedValues__c* field. This is used for v2 Attribute Model.  
* ***attributeMetadata***  
  The JSON string from *Product2.vlocity_cmt__AttributeMetadata__c* field. This is used for v2 Attribute Model.
* ***skipEmptyAttribute***  
  A boolean value, the empty attribute(s) are ignored if the param is set to TRUE. 

#### Example
##### v1 Attribute Model example
```
GetLineItemAttributes(%Quote:Items:vlocity_cmt__JSONAttribute__c%, false)
```
##### v1 Attribute Model example
```
GetLineItemAttributes(%Quote:Items:vlocity_cmt__AttributeSelectedValues__c%, %Quote:Items:Product2.vlocity_cmt__AttributeMetadata__c%, true)
```
Here is a sample result:
```
{
  "Items": [
    {
      "Id": "0QL5e000000CeScGAK",
      "Attributes": [
        {
          "sequence": 1,
          "value": null,
          "name": "Billing Code",
          "code": "ATTRIBUTE-117"
        },
        {
          "sequence": 4,
          "value": null,
          "name": "Provider",
          "code": "ATTRIBUTE-124"
        }
      ]
    }
  ]
}
```

### <a id="dataraptor-helper-ToProductHierarchy"></a> ToProductHierarchy
By default, the extract action in Dataraptor returns the list of line itme records. This function can convert the list (flat) of line items to the hierarchical structure based on the product definition. The conversation uses the *vlocity_cmt__LineNumber__c* field.
#### Signature
```
ToProductHierarchy(%lineItems%)
```
#### Parameters
* ***lineItems***
  The line item records. The *vlocity_cmt__LineNumber__c* field must be present on the list records.
#### Example
```
ToProductHierarchy(%Quote:Items%)
```
Here is a sample result:
```
{
  "StructureItems": [
    {
      "Id": "0QL7h000000AL2UGAW",
      "QuoteId": "0Q07h0000005xZbCAI",
      "vlocity_cmt__LineNumber__c": "0001",
      "items": [
        {
          "Id": "0QL7h000000AL2VGAW",
          "QuoteId": "0Q07h0000005xZbCAI",
          "vlocity_cmt__LineNumber__c": "0001.0001"
        },
        {
          "Id": "0QL7h000000AL2WGAW",
          "QuoteId": "0Q07h0000005xZbCAI",
          "vlocity_cmt__LineNumber__c": "0001.0002"
        }
      ]
    },
    {
      "Id": "0QL7h000000AL2oGAG",
      "QuoteId": "0Q07h0000005xZbCAI",
      "vlocity_cmt__LineNumber__c": "0002"
    }
  ]
}
```

### <a id="dataraptor-helper-ToStructureJson"></a> ToStructureJson
The function can transform a list of name/value pairs into a structured JSON by the attribute name. The transformation follow the [JSLT](https://github.com/schibsted/jslt "JSON Query & Transformation Language") notation:
* **"parent.child.name": value**
  The DOT(.) is used the specify the object hierarchy level. The above name&value pair will be converted to the "parent" object with a "child" object which has a "name" attribute with the given value.
* **"arrayName[index].name": value**
  The bracket([]) is used to define an array in the JSON. Any elements with the same "index" value to be grouped into the same array element. The "index" is a string or number. A "arrayIdx" special data elment is to the array record which holds the "Index" value.

#### Signature
```
ToStructureJson(flatJson, isMap, nameField, valueField)
```  
#### Parameters
* ***flatJson***
  The flat JSON String to be transformed. The flat JSON can be either a Map or a List.
* ***isMap***
  A boolean value which indicates if the input flatJSON is a map or a List. Optional with default to *True*
* ***nameField***
  The name of the name field is the flat JSON is sent in the List format. Optional with default to "name"
* ***valueField***
  The name of the value field is the flat JSON is sent in the List format. Optional with default to "value".

#### Example
##### **Input flat JSON as Map**
```
ToStructureJson(%items:attribute%, true)
```
Here is a sample input:
```
{
  "items": [
    {
      "id": "0Q05e000000L49HCAS",
      "attribute": {
        "author": "Jane Doe",
        "specification.id": "IP-10",
        "specification.name": "Apple iPhone X",
        "relatedParty[owner].name": "Apple",
        "relatedParty[owner].role": "Maker",
        "parent.child[1].name": "Mike",
        "parent.child[1].age": "24",
        "parent.child[2].name": "Michelle",
        "parent.child[2].age": "12",
        "parent.Mike.name": "Mike",
        "parent.Mike.age": "24",
        "parent.Michelle.name": "Michelle",
        "parent.Michelle.age": "12"
      }
    }
  ]
}
```
Here is the transformed result
```
{
  "Items": {
    "attribute": {
      "author": "Jane Doe",
      "specification": {
        "id": "IP-10",
        "name": "Apple iPhone X"
      },
      "relatedParty": [
        {
          "name": "Apple",
          "role": "Maker",
          "@arrayKey": "owner"
        }
      ],
      "parent": {
        "child": [
          {
            "name": "Michelle",
            "age": "12",
            "@arrayKey": "2"
          },
          {
            "name": "Mike",
            "age": "24",
            "@arrayKey": "1"
          }
        ],
        "Mike": {
          "name": "Mike",
          "age": "24"
        },
        "Michelle": {
          "name": "Michelle",
          "age": "12"
        }
      }
    }
  }
}
```
##### **INput flat JSON as LIST**
```
ToStructureJson(%items:attribute%, false, "name", "value")
```
Here is a sample input:
```
{
  "items": [
    {
      "id": "",
      "attribute": [
        {
          "name": "name",
          "value": "Soforce"
        },
        {
          "name": "relatedParty[maker].name",
          "value": "Jyue"
        },
        {
          "name": "relatedParty[maker].role",
          "value": "maker"
        },
        {
          "name": "specification.id",
          "value": "ip-x"
        },
        {
          "name": "specification.name",
          "value": "Apple iPhone X"
        }
      ]
    }
  ]
}
```
Here is the transformed result
```
{
  "Items": {
    "attribute": {
      "specification": {
        "name": "Apple iPhone X",
        "id": "ip-x"
      },
      "relatedParty": [
        {
          "role": "maker",
          "name": "Jyue",
          "@arrayKey": "maker"
        }
      ],
      "name": "Soforce"
    }
  }
}
```

## <a id="add-products-with-cfg"></a> Add Products to Carts (PostCartsItems) with Configuration (attributes)
With the postCartsItems API, you can set the field values with the “fieldsToUpdate” parameter but you cannot achieve the same thing for attributes. In field implementation, it’s normally done by hooking up custom code in the PostCartsItems_PostInvoke event or initiating another putCartsItems API call. Both of them are not ideal because they impact the performance and need custom development.

Here is the solution which allows you to add products with configured attribute values. Once you deploy and configure the solution, it will automatically set the attribute values passed by the extra “attributesToUpdate” JSON node of the “PostCartsItems” payload. This solution has no extra SOQLs and DMLs and almost zero impact on the performance and governor limits.

Here is a sample payload for the CPQ PostCartsItems API: 
```
{
  "methodName": "postCartsItems",
  "items": [
    {
      "itemId": "01u5e000001918uAAA",
      "attributesToUpdate": {
        "ATTRIBUTE-016": "Space Grey"
      }
    }
  ],
  "cartId": "8015e000000p7muAAA",
  "price": true,
  "validate": true,
  "includeAttachment": false,
  "pagesize": 10,
  "lastRecordId": null,
  "hierarchy": -1,
  "query": "Apple iPhone Xs"
}
```
Similar to the “fieldsToUpdate” which allows you to set the value for the field, the new introduced “attributesToUpdate” allows you to set the value for the attributes.

“V2 Attribute Model” is supported. 
### Deployment
The "addProductsWithCfg.xml" manifest file is created under the "projects" folder. You can execute the following sfdx command to deploy "JSONAttribute viewer" to your org:
* **deploy without tests**
```
sfdx force:source:deploy -x projects/addProductsWithCfg.xml -u {orgName}
```
* **deploy with tests**
```
sfdx force:source:deploy -x projects/addProductsWithCfg.xml -u {orgName} -l RunSpecifiedTests -r vHelperTest,vCpqServiceTest,vCpqAppHandlerHookImplTest,vLoggerTest
```
### Post-Deployment Configuration
* Add “SoforceLogging” entry to the “CPQ Configuration Setup” of “Vlocity CMT Administration“. Set it to false by default. The setting is used to control the debug log output.
* Register the vCpqAppHandlerHookImpl to the CpqAppHandlerHook Interface Implementation. If you have your own CpqAppHandlerHook implementation, you need to merge the code into your implementation(see the last optional step below).
* Register the vCpqService.ProcessCartMessage to your Pricing Plan.
![Image of vCpqService.ProcessCartMessage Step](https://github.com/Soforce/vlocity-ex/blob/master/images/vCpqService-ProcessCartMessage-Step.PNG)
* (Optional) Merge vCpqAppHandlerHookImpl into your own CpqAppHandlerHook implementation by adding “vCpqService.addProductsWithCfg(inputMap)” into the “postCartsItems.PreInvoke” section. See the code snippet below:
```
            if (methodName == 'postCartsItems.PreInvoke') {
                vCpqService.addProductsWithCfg(inputMap);
            }
```

## <a id="ef-based-discount"></a> Configure Discount Products with Entity Filter
You can either select product(s) or catalogs when you configure a discount in the Product Designer (or Product Console). Sometime you may need to configure a dynamic products for a discount based off run-time query instead of static predefined product selections. This solution extends the OOTB Discount with EntityFilter to support dynamic query for the qualified products. For example, the discount is qualfiied for any rate plans with 5GB or bigger data plan.

### Deploy Filter Based Discount
The "EfDiscount.xml" manifest file is created under the "projects" folder. You can execute the following sfdx command to deploy "Filter Based Discount" to your org:
* **deploy without tests**
```
sfdx force:source:deploy -x projects/EfDiscount.xml -u {orgName}
```
* **deploy with tests**
```
sfdx force:source:deploy -x projects/EfDiscount.xml -u {orgName} -l RunSpecifiedTests -r vLoggerTest,vEfDiscountServiceTest
```

### Post-Deployment Configuration
* Register the vCpqEfDiscountService.ApplyFilterBasedDiscount to your Pricing Plan.
![Image of vCpqEfDiscountService.ApplyFilterBasedDiscount Step](https://github.com/Soforce/vlocity-ex/blob/master/images/vEfDiscount-PPlan.PNG)

### Configure Filter Based Discount
* Create your EntityFilter, e.g. the following a filter for all black iphones:
![Image of Black iPhone Filter](https://github.com/Soforce/vlocity-ex/blob/master/images/vEfDiscount-EF.PNG)
* Create a catalog and select the entity filter created in the previous step:
![Image of Catalog with EF](https://github.com/Soforce/vlocity-ex/blob/master/images/vEfDiscount-Catalog.PNG)
* Create your discount and select the catalog configured above.



## <a id="json-attribute-viewer"></a> Vlocity Attribute Viewer
By adding the Vlocity JSON Attribute Viewer Lightning web component into the Lightning record page, you can easily view and manage the JSON attributes created for the xLI record, such as QuoteLineItem, OrderItem or Asset, vlocity_cmt__FulfillmentRequestLine__c etc. 
* You can view the attributes in a list
* You can open the attribute to see the details of it
* You can modify the attribute and save it back to the record

![Image of JSON Attribute Viewer](https://github.com/Soforce/vlocity-ex/blob/master/images/json-viewer.jpg)

### Deploy JSONAttribute Viewer
The "JsonViewer.xml" manifest file is created under the "projects" folder. You can execute the following sfdx command to deploy "JSONAttribute viewer" to your org:
* **deploy without tests**
```
sfdx force:source:deploy -x projects/JsonViewer.xml -u {orgName}
```
* **deploy with tests**
```
sfdx force:source:deploy -x projects/JsonViewer.xml -u {orgName} -l RunSpecifiedTests -r vHelperTest,vJsonAttributeViewerControllerTest
```

### How to use Vlocity JSONAttribute Viewer
1. Open the record (for example, QuoteLinteItem) in Lightning Experience
2. Click "Setup" icon from the top-right of the page and choose "Edit Page"
3. Find the "Vlocity JSON Attribute Viewer" under the "Custom" section of available components and drag & drop the component into your lighting record page.


