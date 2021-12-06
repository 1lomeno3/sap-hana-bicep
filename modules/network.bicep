param VMName string
param ExistingNetworkRG string
param HANAVNet string
param HANAVNetCIDR string
param HANASubnet string
param HANASubnetCIDR string 
param PublicIP string

var DNSPrefix = toLower('${VMName}-${uniqueString(resourceGroup().id, VMName)}')
var HANASubnetRef = ((ExistingNetworkRG == 'no') ? '${vnet.id}/subnets/${HANASubnet}' : '${resourceId(ExistingNetworkRG, 'Microsoft.Network/virtualNetworks/', HANAVNet)}/subnets/${HANASubnet}')


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

resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = if (PublicIP == 'yes') {
  name: '${VMName}-pip'
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: DNSPrefix
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: '${VMName}-nic'
  location: resourceGroup().location
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: HANASubnetRef
          }
        }
      }
    ]
  }
}

output nicId string = nic.id
output hostname string = (PublicIP == 'yes') ? pip.properties.dnsSettings.fqdn : nic.properties.ipConfigurations[0].properties.privateIPAddress
