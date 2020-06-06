# Vlocity Extension Package

This guide helps Salesforce developers who are new to Visual Studio Code go from zero to a deployed app using Salesforce Extensions for VS Code and Salesforce CLI.

## Part 1: CLIs to build the package
```
sfdx force:package:create --name vlocity-ex-base --description "Soforce vlocity extension base package" --packagetype Unlocked --path force-app --nonamespace --targetdevhubusername vdo-devhub
```

```
sfdx force:package:version:create -p "vlocity-ex-base" -d force-app -f config/project-scratch-def.json --installationkeybypass --wait 60 -v vdo-devhub
```
