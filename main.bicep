targetScope='subscription'

param resourceGroupName string = 'HANABicepRG'
param resourceGroupLocation string = 'westeurope'

@description('Type in the SAP HANA revision number, e.g. for HANA 2.0 REV64 => 64')
@minLength(2)
@maxLength(2)
param HANAVersion string = '64'

@minLength(3)
@maxLength(3)
param HANASID string = 'AZR'

@minLength(2)
@maxLength(2)
param HANANumber string = '00'

@maxLength(13)
param VMName string = 'hanavm'

@allowed([
  'Standard_DS14_v2 (112 GB, for B1)'
  'Standard_E16ds_v5 (128 GB)'
  'Standard_E20ds_v5 (160 GB)'
  'Standard_M32ts (192 GB)'
  'Standard_E32ds_v5 (256 GB)'
  'Standard_M32ls (256 GB)'
  'Standard_E48ds_v5 (384 GB)'
  'Standard_E64ds_v5 (512 GB)'
  'Standard_M64ls (512 GB)'
  'Standard_M32dms_v2 (875 GB)'
  'Standard_M64ds_v2 (1 TB)'
  'Standard_M64dms_v2 (1.7 TB)'
  'Standard_M128ds_v2 (2 TB)'
  'Standard_M208s_v2 (3 TB)'
  'Standard_M128dms_v2 (4 TB)'
])
param VMType string = 'Standard_E32ds_v5 (256 GB)'

@description('Type in the name of the Resource Group for an existing network or leave no to create new one')
param ExistingNetworkRG string = 'no'

param HANAVNet string = 'hanavnet'
param HANAVNetCIDR string = '10.0.0.0/25'
param HANASubnet string = 'hanasubnet'
param HANASubnetCIDR string = '10.0.0.0/26'

@description('Whether to use public IP or not')
@allowed([
  'yes'
  'no'
])
param PublicIP string = 'yes'

@description('URI where SAP bits are uploaded')
param SAPstorage string

@description('SAS token for SA')
@secure()
param SAStoken string

param VMUserName string = 'azureadmin'

@description('Password for VM and also for SAP HANA SYSTEM user')
@secure()
@minLength(6)
@maxLength(72)
param VMPassword string

@allowed([
  'SLES for SAP 12 SP5'
  'SLES for SAP 15 SP3'
  'RHEL for SAP 8.2 - not working yet'
])
param OperatingSystem string = 'SLES for SAP 15 SP3'


// variables
var VMSizeArray = split(VMType, ' ')
var VMSize = VMSizeArray[0]


// deployment
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
}

module network 'modules/network.bicep' = {
  scope: rg
  name: 'network'
  params: {
    VMName: VMName
    PublicIP: PublicIP
    ExistingNetworkRG: ExistingNetworkRG
    HANAVNet: HANAVNet
    HANAVNetCIDR: HANAVNetCIDR
    HANASubnet: HANASubnet
    HANASubnetCIDR: HANASubnetCIDR
  }
}

module vm 'modules/vm.bicep' = {
  scope: rg
  name: 'vm'
  params: {
    HANAVersion: HANAVersion
    HANASID: HANASID
    HANANumber: HANANumber
    VMName: VMName
    VMSize: VMSize
    SAPstorage: SAPstorage
    SAStoken: SAStoken
    OperatingSystem: OperatingSystem
    VMUserName: VMUserName
    VMPassword: VMPassword
    nicID: network.outputs.nicId
  }
}

output finish string = network.outputs.hostname
