# Vlocity Extension (Vlocity-ex) Package
## Overview
Vlocity extension package is a unlocked package to extend the functionalities of Vlocity CMT managed package. 
Here is the list of features included in the extension package:
* **[Add Products to Cart (PostCartsItems) with Configuration (Attributes)](#add-products-with-cfg)**  
With Vlocity JSON Attribute Viewer, you can view and modify Vlocity attributes of a xLI record much faster and easier because you don't need to work with the fancy raw JSON blob anymore.  
Vlocity JSON Attribute Viewer is a Lightning Web Component which can be dropped into any SObject which supports JSONAttribut. Both v1 and v2 Attribute models are supported.  
* **[Vlocity JSON Attribute Viewer](#json-attribute-viewer)**  
With Vlocity JSON Attribute Viewer, you can view and modify Vlocity attributes of a xLI record much faster and easier because you don't need to work with the fancy raw JSON blob anymore.  
Vlocity JSON Attribute Viewer is a Lightning Web Component which can be dropped into any SObject which supports JSONAttribut. Both v1 and v2 Attribute models are supported.  

*  **[Using Lightning Flow in Vlocity OM (WIP)](#flow-in-om)**  
By applying the power of low-code, drag-and-drop functionality to customer engagement, Lightning Flow delivers an innovative new way for businesses to realize the benefits of process automation. This feature helps you to extend Vlocity OM automation task with the lighting flow.



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
```
sfdx force:source:deploy -x projects/addProductsWithCfg.xml -u {orgName}
```
### Post-Deployment Configuration
* Add “SoforceLogging” entry to the “CPQ Configuration Setup” of “Vlocity CMT Administration“. Set it to false by default. The setting is used to control the debug log output.
* Register the vCpqAppHandlerHookImpl to the CpqAppHandlerHook Interface Implementation. If you have your own CpqAppHandlerHook implementation, you need to merge the code into your implementation(see the last optional step below).
* Register the vCpqService.ProcessCartMessage to your Pricing Plan.
* (Optional) Merge vCpqAppHandlerHookImpl into your own CpqAppHandlerHook implementation by adding “vCpqService.addProductsWithCfg(inputMap)” into the “postCartsItems.PreInvoke” section. See the code snippet below:
```
            if (methodName == 'postCartsItems.PreInvoke') {
                vCpqService.addProductsWithCfg(inputMap);
            }
```
## <a id="json-attribute-viewer"></a> Vlocity Attribute Viewer
By adding the Vlocity JSON Attribute Viewer Lightning web component into the Lightning record page, you can easily view and manage the JSON attributes created for the xLI record, such as QuoteLineItem, OrderItem or Asset, vlocity_cmt__FulfillmentRequestLine__c etc. 
* You can view the attributes in a list
* You can open the attribute to see the details of it
* You can modify the attribute and save it back to the record

![Image of JSON Attribute Viewer](https://github.com/Soforce/vlocity-ex/blob/master/images/json-viewer.jpg)

### Deploy JSONAttribute Viewer
The "JsonViewer.xml" manifest file is created under the "projects" folder. You can execute the following sfdx command to deploy "JSONAttribute viewer" to your org:
```
sfdx force:source:deploy -x projects/JsonViewer.xml -u {orgName}
```

### How to use Vlocity JSONAttribute Viewer
1. Open the record (for example, QuoteLinteItem) in Lightning Experience
2. Click "Setup" icon from the top-right of the page and choose "Edit Page"
3. Find the "Vlocity JSON Attribute Viewer" under the "Custom" section of available components and drag & drop the component into your lighting record page.
## <a id="flow-in-om"></a> Using Lightning Flow in Vlocity OM
By applying the power of low-code, drag-and-drop functionality to customer engagement, Lightning Flow delivers an innovative new way for businesses to realize the benefits of process automation. This extension feature helps you to extend Vlocity OM automation task with the lighting flow.
To use Lightning autolaunched flow in your orchestration plan, you need add "AutoTask" orchestration item because there's no flow type of orchestration item at the moment.  




