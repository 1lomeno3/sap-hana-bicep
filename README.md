# SAP HANA Deployment via Bicep
The repository is used to install SAP HANA on a single VM using the Bicep language. It is based on the [SAP-HANA-ARM repository](https://github.com/1lomeno3/SAP-HANA-ARM), which means that a similar logic is applied:
1. infrastracture deployment with predefined SKUs and recommended disk layout
2. custom script extension for the OS update and configuration of the VM
3. installation of SAP HANA using SAP media located in the defined Storage Account
4. preparation for Azure backup with SAP HANA

## Deployment steps
At this time (December 2021), there is no direct way to deploy Bicep files through Azure portal (as with ARM templates). However, we can use Azure CLI or PowerShell for the local deployment.
```
git clone https://github.com/1lomeno3/sap-hana-bicep.git
cd sap-hana-bicep
az group create -n HANABicepRG -l westeurope
az deployment group create -g HANABicepRG -f azuredeploy.bicep --parameters azuredeploy.parameters.json
```

## ToDo list
1. add SAP monitoring extension
2. activation of Azure Sentinel
3. deployment via Azure DevOps
