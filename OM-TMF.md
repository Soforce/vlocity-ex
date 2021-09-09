# Order Management API Integration via TMF Specifications
## Overview
WIP...

The package depends on the DRHelper package. You need to deploy the DRHelper package first. Please reference the [Deployment](#deployment) section for details.


* **[Sumbit ProductOrder](#productorder-submission)**  
blabla...

## <a id="productorder-submission"></a> Sumbit ProductOrder
WIP...



## <a id="deployment"></a> Deployment
### Prerequiste
DRHelper package needs to be deployed first. You can execute the following command to deploy the DRHelper package:
```
sfdx force:source:deploy -x projects/DRHelper.xml -u {orgName}
```

### Salesforce Metadata Files
Execute the following command to deploy Salesforce metadata files:
```
sfdx force:source:deploy -x projects/TMFHelper.xml -u {orgName}
```
Execute the following command to deploy Salesforce metadata files with tests:
```
sfdx force:source:deploy -x projects/TMFHelper.xml -l RunSpecifiedTests -r vTMFInterfaceTest,vTMFDRHelperTest -u {orgName}
```
### Vlocity Metadata Files
Execute the following command to deploy Vlocity metadata files:
```
vlocity -job ./projects/TMFHelper.yaml packDeploy "-sfdx.username" {orgName} 
```