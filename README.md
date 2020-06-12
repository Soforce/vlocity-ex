# Vlocity Extension Package

This guide helps Salesforce developers who are new to Visual Studio Code go from zero to a deployed app using Salesforce Extensions for VS Code and Salesforce CLI.

## Part 1: CLIs to build the package
```
sfdx force:package:create --name vlocity-extension --description "Soforce vlocity extension package" --packagetype Unlocked --path force-app --nonamespace --targetdevhubusername vdo20-hub
```

```
sfdx force:package:version:create -p "vlocity-extension" -d force-app -f config/package-def.json --installationkeybypass --wait 120 -v vdo20-hub
```


```
https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000002HDHRAA4   
sfdx force:package:install --package 04t3h000002HDHRAA4
```
