@allowed([
  '2.0 SPS01 REV10 (51052030)'
  '2.0 SPS02 REV20 (51052325)'
  '2.0 SPS03 REV30 (51053061)'
  '2.0 SPS04 REV40 (51053787)'
  '2.0 SPS05 REV56'
])
param HANAVersion string = '2.0 SPS05 REV56'

@minLength(3)
@maxLength(3)
param HANASID string = 'AZR'

@minLength(2)
@maxLength(2)
param HANANumber string = '00'

@maxLength(13)
param VMName string = 'HANABicepTest'

@allowed([
  'Standard_DS14_v2 (112 GB, for B1)'
  'Standard_E16s_v3 (128 GB)'
  'Standard_E20ds_v4 (160 GB)'
  'Standard_M32ts (192 GB)'
  'Standard_E32s_v3 (256 GB)'
  'Standard_E48ds_v4 (384 GB)'
  'Standard_E64s_v3 (432 GB)'
  'Standard_M64ls (512 GB)'
  'Standard_M64s (1 TB)'
  'Standard_M64ms (1.7 TB)'
  'Standard_M128s (2 TB)'
  'Standard_M208s_v2 (3 TB)'
  'Standard_M128ms (4 TB)'
])
param VMType string = 'Standard_E32s_v3 (256 GB)'

@description('Type in the name of the Resource Group for an existing network or leave no to use the same one')
param ExistingNetworkRG string = 'no'

param HANAVNet string = 'HANAVNet'
param HANAVNetCIDR string = '10.0.0.0/16'
param HANASubnet string = 'defaultsubnet'
param HANASubnetCIDR string = '10.0.0.1/24'

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

@secure()
param VMPassword string

@allowed([
  'SLES for SAP 12 SP5'
  'SLES for SAP 15 SP2'
  'RHEL 7.2 for SAP HANA - not working yet'
])
param OperatingSystem string = 'SLES for SAP 15 SP2'


var VNetID = vnet.id
var HANASubnetRef = ((ExistingNetworkRG == 'no') ? '${VNetID}/subnets/${HANASubnet}' : '${resourceId(ExistingNetworkRG, 'Microsoft.Network/virtualNetworks/', HANAVNet)}/subnets/${HANASubnet}')
var VMSizeArray = split(VMType, ' ')
var VMSize = VMSizeArray[0]

resource vnet 'Microsoft.Network/virtualNetworks@2016-09-01' = if (ExistingNetworkRG == 'no') {
  name: HANAVNet
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        HANAVNetCIDR
      ]
    }
    subnets: [
      {
        name: HANASubnet
        properties: {
          addressPrefix: HANASubnetCIDR
        }
      }
    ]
  }
}

module smallVM 'modules/small.bicep' = if (VMSize == 'Standard_DS14_v2' || VMSize == 'Standard_E16s_v3' || VMSize == 'Standard_E20ds_v4' || VMSize == 'Standard_M32ts' || VMSize == 'Standard_E32s_v3' || VMSize == 'Standard_E48ds_v4' || VMSize == 'Standard_E64s_v3' || VMSize == 'Standard_M64ls') {
  name: 'smallbicep'
  params: {
    HANAVersion: HANAVersion
    HANASID: HANASID
    HANANumber: HANANumber
    VMName: VMName
    VMSize: VMSize
    SAPstorage: SAPstorage
    SAStoken: SAStoken
    HANASubnetRef: HANASubnetRef
    PublicIP: PublicIP
    OperatingSystem: OperatingSystem
    VMUserName: VMUserName
    VMPassword: VMPassword   
  }
}
