param HANAVersion string
param HANASID string
param HANANumber string
param VMName string
param VMSize string
param SAPstorage string
param SAStoken string
param VMUserName string
param VMPassword string
param OperatingSystem string
param nicID string

var OperatingSystemSpec = {
  imagePublisher: (contains(OperatingSystem, 'SLES') ? 'SUSE' : 'RedHat')
  imageOffer: (contains(OperatingSystem, 'SLES') ? (contains(OperatingSystem, 'SP5') ? 'sles-sap-12-sp5' : 'sles-sap-15-sp2') : 'RHEL-SAP-HANA')
  sku: 'gen2'
}

var extrasmallVMs = [
  'Standard_DS14_v2'
  'Standard_E16s_v3'
  'Standard_E20ds_v4'
]
var smallVMs = [  
  'Standard_M32ts'
  'Standard_E32s_v3'
  'Standard_M32ls'  
]
var mediumVMs = [
  'Standard_E48ds_v4'
  'Standard_E64s_v3'
  'Standard_M64ls'
]
var largeVMs = [
  'Standard_M32dms_v2'
  'Standard_M64s'
]
/*
var extralargeVMs = [
  'Standard_M64ms'
  'Standard_M128s'
  'Standard_M208s_v2'
  'Standard_M128ms'
]*/

var extrasmallDisks = [
  {
    lun: 0
    name: '${VMName}-disk-shared'
    createOption: 'Empty'
    diskSizeGB: 128
    managedDisk: {
      storageAccountType: 'StandardSSD_LRS'
    }          
  }
  {
    lun: 1
    name: '${VMName}-disk-sap'
    createOption: 'Empty'
    diskSizeGB: 64
    managedDisk: {
      storageAccountType: 'StandardSSD_LRS'
    }          
  }
  {
    lun: 2
    name: '${VMName}-disk-backup'
    createOption: 'Empty'
    diskSizeGB: 256
    managedDisk: {
      storageAccountType: 'StandardSSD_LRS'
    }          
  }
  {
    lun: 3
    name: '${VMName}-disk-data1'
    createOption: 'Empty'
    diskSizeGB: 64
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
  }
  {
    lun: 4
    name: '${VMName}-disk-data2'
    createOption: 'Empty'
    diskSizeGB: 64
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
  }
  {
    lun: 5
    name: '${VMName}-disk-data3'
    createOption: 'Empty'
    diskSizeGB: 64
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
  }
  {
    lun: 6
    name: '${VMName}-disk-log1'
    createOption: 'Empty'
    diskSizeGB: 128
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
  }
  {
    lun: 7
    name: '${VMName}-disk-log2'
    createOption: 'Empty'
    diskSizeGB: 128
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
  }
]
var disks = [
  {
    lun: 0
    name: '${VMName}-disk-shared'
    createOption: 'Empty'
    diskSizeGB: (contains(smallVMs, VMSize)) ? 256 : (contains(mediumVMs, VMSize)) ? 512 : 1024
    managedDisk: {
      storageAccountType: 'StandardSSD_LRS'
    }          
  }
  {
    lun: 1
    name: '${VMName}-disk-sap'
    createOption: 'Empty'
    diskSizeGB: 64
    managedDisk: {
      storageAccountType: 'StandardSSD_LRS'
    }          
  }
  {
    lun: 2
    name: '${VMName}-disk-backup'
    createOption: 'Empty'
    diskSizeGB: (contains(smallVMs, VMSize)) ? 256 : (contains(mediumVMs, VMSize)) ? 512 : 1024
    managedDisk: {
      storageAccountType: 'StandardSSD_LRS'
    }          
  }
  {
    lun: 3
    name: '${VMName}-disk-data1'
    createOption: 'Empty'
    diskSizeGB: (contains(smallVMs, VMSize)) ? 64 : (contains(mediumVMs, VMSize)) ? 128 : (contains(largeVMs, VMSize)) ? 256 : 512
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
  }
  {
    lun: 4
    name: '${VMName}-disk-data2'
    createOption: 'Empty'
    diskSizeGB: (contains(smallVMs, VMSize)) ? 64 : (contains(mediumVMs, VMSize)) ? 128 : (contains(largeVMs, VMSize)) ? 256 : 512
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
  }
  {
    lun: 5
    name: '${VMName}-disk-data3'
    createOption: 'Empty'
    diskSizeGB: (contains(smallVMs, VMSize)) ? 64 : (contains(mediumVMs, VMSize)) ? 128 : (contains(largeVMs, VMSize)) ? 256 : 512
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
  }
  {
    lun: 6
    name: '${VMName}-disk-data4'
    createOption: 'Empty'
    diskSizeGB: (contains(smallVMs, VMSize)) ? 64 : (contains(mediumVMs, VMSize)) ? 128 : (contains(largeVMs, VMSize)) ? 256 : 512
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
  }
  {
    lun: 7
    name: '${VMName}-disk-log1'
    createOption: 'Empty'
    diskSizeGB: (contains(smallVMs, VMSize)) ? 128 : (contains(mediumVMs, VMSize)) ? 128 : 256
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
    writeAcceleratorEnabled: (contains(VMSize, 'Standard_M')) ? 'true' : 'false'
  }
  {
    lun: 8
    name: '${VMName}-disk-log2'
    createOption: 'Empty'
    diskSizeGB: (contains(smallVMs, VMSize)) ? 128 : (contains(mediumVMs, VMSize)) ? 128 : 256
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
    writeAcceleratorEnabled: (contains(VMSize, 'Standard_M')) ? 'true' : 'false'
  }
  {
    lun: 9
    name: '${VMName}-disk-log3'
    createOption: 'Empty'
    diskSizeGB: (contains(smallVMs, VMSize)) ? 128 : (contains(mediumVMs, VMSize)) ? 128 : 256
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
    writeAcceleratorEnabled: (contains(VMSize, 'Standard_M')) ? 'true' : 'false'
  }
]

resource hanavm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: VMName
  location: resourceGroup().location
  properties: {
      hardwareProfile: {
      vmSize: VMSize
    }
    osProfile: {
      computerName: VMName
      adminUsername: VMUserName
      adminPassword: VMPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicID
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: OperatingSystemSpec.imagePublisher
        offer: OperatingSystemSpec.imageOffer
        sku: OperatingSystemSpec.sku
        version: 'latest'
      }
      osDisk: {
        name: '${VMName}-disk-OS'
        createOption: 'FromImage'
        diskSizeGB: 64
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: (contains(extrasmallVMs, VMSize)) ? extrasmallDisks : disks
    }
  }
}

resource script 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${VMName}/scriptextension'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/1lomeno3/sap-hana-bicep/main/scripts/script.sh'
      ]
      commandToExecute: 'sh script.sh "${HANAVersion}" "${HANASID}" "${HANANumber}" "${VMSize}" "${SAPstorage}" "${SAStoken}" "${VMUserName}" "${VMPassword}"'
    }
  }
  dependsOn: [
    hanavm
  ]
}
