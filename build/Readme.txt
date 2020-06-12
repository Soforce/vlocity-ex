
How to
1. Create the package
sfdx force:package:create --name vlocity-extension --description "Soforce vlocity extension package" --packagetype Unlocked --path force-app --nonamespace --targetdevhubusername vdo20-hub
2. Create new version
sfdx force:package:version:create -p "vlocity-extension" -d force-app -f config/package-def.json --installationkeybypass --wait 120 -v vdo20-hub
