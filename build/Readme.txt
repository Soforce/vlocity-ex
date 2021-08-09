
How to
1. Create the package
sfdx force:package:create --name vlocity-extension --description "Soforce vlocity extension package" --packagetype Unlocked --path force-app --nonamespace --targetdevhubusername vdo20-hub
2. Create new version
sfdx force:package:version:create -p "vlocity-extension" -d force-app -f config/package-def.json --installationkeybypass --wait 120 -v vdo20-hub


3. Bulk delete debug logs
sfdx force:data:soql:query -q "Select id from ApexLog" -r csv > apexlog.csv  
sfdx force:data:bulk:delete -s ApexLog -f apexlog.csv  

