# Vlocity Extension (Vlocity-ex) Package
## Overview
Vlocity extension package is a unlocked package to extend the functionalities of Vlocity CMT managed package. 
Here is the list of features included in the extension package:
* **[Vlocity JSON Attribute Viewer](#json-attribute-viewer)**  
With Vlocity JSON Attribute Viewer, you can view and modify Vlocity attributes of a xLI record much faster and easier because you don't need to work with the fancy raw JSON blob anymore.  
Vlocity JSON Attribute Viewer is a Lightning Web Component which can be dropped into any SObject which has been extended with vlocity_cmt__JSONAttribute__c field.  

*  **[Using Lightning Flow in Vlocity OM](#flow-in-om)**  
By applying the power of low-code, drag-and-drop functionality to customer engagement, Lightning Flow delivers an innovative new way for businesses to realize the benefits of process automation. This feature helps you to extend Vlocity OM automation task with the lighting flow.

## Install & Configure Vlocity-ex Package
### <a id="install-package"></a>Install Vlocity-ex package
You can install the extension package either
```
https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000002HkLhAAK
```
or
```
sfdx force:package:install --package 04t3h000002HkLhAAK
```
### <a id="configure-package"></a> Configure Vlocity-ex package


## <a id="json-attribute-viewer"></a> Vlocity JSON Attribute Viewer
By adding the Vlocity JSON Attribute Viewer Lightning web component into the Lightning record page, you can easily view and manage the JSON attributes created for the xLI record, such as QuoteLineItem, OrderItem or Asset, vlocity_cmt__FulfillmentRequestLine__c etc. 
* You can view the attributes in a list
* You can open the attribute to see the details of it
* You can modify the attribute and save it back to the record
* You can copy the JSON attribute blob into the clipboard

![Image of JSON Attribute Viewer](https://github.com/Soforce/vlocity-ex/blob/master/images/json-viewer.jpg)


### How to use Vlocity JSON Attribute Viewer
1. Open the record (for example, QuoteLinteItem) in Lightning Experience
2. Click "Setup" icon from the top-right of the page and choose "Edit Page"
3. Find the "Vlocity JSON Attribute Viewer" under the "Custom" section of available components and drag & drop the component into your lighting record page.
## <a id="flow-in-om"></a> Using Lightning Flow in Vlocity OM



