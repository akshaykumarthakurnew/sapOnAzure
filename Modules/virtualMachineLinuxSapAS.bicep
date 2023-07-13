/*
Deploys N number of Linux Virtual Machines with OS disks into Availability zones specific to SAP

@parameters []

@author Akshay Kumar
@version 1.0
@date 29 June 2023
*/

param virtualMachineName string
param virtualMachineSize string
param virtualMachineUserName string
@secure()
param virtualMachinePassword string
param OperatingSystem string
param availabilitySetName string
param availabilitySetPlatformFaultDomainCount int = 2
param availabilitySetPlatformUpdateDomainCount int = 5
param vNetResourceGroup string
param vNetName string
param SubnetName string
param virtualMachineCount int
param Environment string
param loadBalancerBackendPoolid array
param location string


//param loadBalancerName string
//param backendpoolname string

@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

var subnetRef = resourceId(vNetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vNetName, SubnetName)
//var loadbalancerId = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, backendpoolname)
var images = {
  'Windows Server 2012 Datacenter': {
    sku: '2012-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    version: 'latest'
    OSType: 'Windows'
    UsePlan: false
  }
  'Windows Server 2012 R2 Datacenter': {
    sku: '2012-R2-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    version: 'latest'
    OSType: 'Windows'
    UsePlan: false
  }
  'Windows Server 2016 Datacenter': {
    sku: '2016-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    version: 'latest'
    OSType: 'Windows'
    UsePlan: false
  }
  'sles-sap-12-sp5': {
    sku: 'gen2'
    offer: 'sles-sap-12-sp5'
    publisher: 'SUSE'
    version: 'latest'
    OSType: 'Linux'
    UsePlan: false
  }
 }

 @allowed([
  'Windows Server 2012 Datacenter'
  'Windows Server 2012 R2 Datacenter'
  'Windows Server 2016 Datacenter'
  'sles-sap-12-sp5'
  'RHEL 7.2'
  'Oracle Linux 7.2'
])
param osType string


var OperatingSystemSpec = {
  imagePublisher: images[osType].publisher
  imageOffer: images[osType].offer
  sku: images[osType].sku
}



@description('Optional. Specifies the data disks.')
param dataDisks array = []



//-------------------------------------------------------------------------------------------------------
// For VM creation calls
//-------------------------------------------------------------------------------------------------------

    resource hanavm 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, virtualMachineCount) : {
    name: '${virtualMachineName}-${i+1}'
    location: location
    properties: {
        hardwareProfile: {
        vmSize: virtualMachineSize
      }
      osProfile: {
        computerName: '${virtualMachineName}-${i+1}'
        adminUsername: virtualMachineUserName
        adminPassword: virtualMachinePassword
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: resourceId('Microsoft.Network/networkInterfaces', '${virtualMachineName}-${i+1}-nic1')
          }
        ]
      }
      availabilitySet: {
        id: availabilityset.id
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: false        
        }
      }
      storageProfile: {
        imageReference: {
          publisher: OperatingSystemSpec.imagePublisher
          offer: OperatingSystemSpec.imageOffer
          sku: OperatingSystemSpec.sku
          version: 'latest'
        }
        osDisk: {
          name: '${virtualMachineName}-${i+1}-disk-OS'   
          createOption: 'FromImage'
          diskSizeGB: 64
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
  
        dataDisks: [for (dataDisk, index) in dataDisks: {
          lun: index
          name: '${virtualMachineName}${i+1}-disk-data-${padLeft((index + 1), 2, '0')}'
          diskSizeGB: dataDisk.diskSizeGB
          createOption: dataDisk.createOption
          caching: dataDisk.caching
        }]
       }
      }
    dependsOn: [    
      nic
    ]
  }]
  

   resource nic 'Microsoft.Network/networkInterfaces@2020-11-01' = [for i in range(0, virtualMachineCount) : {
    name: '${virtualMachineName}-${i+1}-nic1'
    location: location
    properties: {
      enableAcceleratedNetworking: true
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            subnet: {
              id: subnetRef
            }      
            loadBalancerBackendAddressPools: loadBalancerBackendPoolid
          }
        }
      ]
      enableIPForwarding: false
    }
    dependsOn:[
      availabilityset
    ]
  }]
  
  //---------------------------------------------
  // Availability Set Code Deployment
  //---------------------------------------------
    resource availabilityset 'Microsoft.Compute/availabilitySets@2021-03-01' = {
    name: availabilitySetName
    location: location
    properties: {
      platformFaultDomainCount: availabilitySetPlatformFaultDomainCount
      platformUpdateDomainCount: availabilitySetPlatformUpdateDomainCount
    }
    sku: {
      name: 'Aligned'
    }
  }


/*
//------------------------------------------------------------------------------------------
// Virtual Machine Deployment for QAS -- test code for LBR , still in progress!!
//------------------------------------------------------------------------------------------
                                                                  

  resource hanavmQAS 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, virtualMachineCount) : if(Environment == 'qas') {
  name: '${virtualMachineName}-${i+1}'
  location: location
  properties: {
      hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
      computerName: '${virtualMachineName}-${i+1}'
      adminUsername: virtualMachineUserName
      adminPassword: virtualMachinePassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${virtualMachineName}-${i+1}-nic1')
        }
      ]
    }
    availabilitySet: {
      id: availabilitysetQAS.id
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false        
      }
    }
    storageProfile: {
      imageReference: {
        publisher: OperatingSystemSpec.imagePublisher
        offer: OperatingSystemSpec.imageOffer
        sku: OperatingSystemSpec.sku
        version: 'latest'
      }
      osDisk: {
        name: '${virtualMachineName}-${i+1}-disk-OS'   
        createOption: 'FromImage'
        diskSizeGB: 64
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }

      dataDisks: [for (dataDisk, index) in dataDisks: {
        lun: index
        name: '${virtualMachineName}${i+1}-disk-data-${padLeft((index + 1), 2, '0')}'
        diskSizeGB: dataDisk.diskSizeGB
        createOption: dataDisk.createOption   
        caching: dataDisk.caching
      }]
     }
    }
  dependsOn: [    
    nicQAS
  ]
}]


  resource nicQAS 'Microsoft.Network/networkInterfaces@2020-11-01' = [for i in range(0, virtualMachineCount) : if(Environment == 'qas') {
  name: '${virtualMachineName}-${i+1}-nic1'
  location: location
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRef
          }
          loadBalancerBackendAddressPools: [ 
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, backendpoolname)
            }
          ]
          
        }
      }
    ]
    enableIPForwarding: false
  }
  dependsOn:[
    availabilitysetQAS
  ]
}]

resource availabilitysetQAS 'Microsoft.Compute/availabilitySets@2021-03-01' = if (Environment == 'qas') {
  name: availabilitySetName
  location: location
  properties: {
    platformFaultDomainCount: availabilitySetPlatformFaultDomainCount
    platformUpdateDomainCount: availabilitySetPlatformUpdateDomainCount
  }
  sku: {
    name: 'Aligned'
  }
}

*/
