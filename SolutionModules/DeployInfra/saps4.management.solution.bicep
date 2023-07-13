/*
A solution to deploy the SAP S4HANA infrastructure
@author Rajdeep Das
@author Akshay Kumar
@version 1.0
@date 01 June 2023
*/

targetScope = 'subscription'


param location string
param lawWorkspaceName string = 'coreManagement-lawworkspace'
param virtualMachineUserName string

@description('Deployment Machine name')
param mgmtVmName string 

@description('Indicates the type if SAP solution the infra is intended for S4/Netweaver')
param SAPSolutionName string 
@description('Name of the resource group')
param coreMgtRgName string = 'RG-${SAPSolutionName}-Core-Management'
param sapBitsStrAccountName string = 'sapbitsDownloadSw'

// NSG params

param isDiagEnabled bool = false
var gatewaySecurityRules = [ {
    name: 'allow-ssh'
    properties: {
      priority: 100
      sourceAddressPrefix: '130.41.187.64/26'
      protocol: 'Tcp'
      destinationPortRange: '22'
      access: 'Allow'
      direction: 'Inbound'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
    }
  } 
]


var bastionSecurityRules = [
  {
    name: 'Inbound-HTTPS-Allow'
    properties: {
        protocol: 'TCP'
        sourcePortRange: '*'
        destinationPortRange: '443'
        sourceAddressPrefix: 'Internet'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 100
        direction: 'Inbound'
        sourcePortRanges: []
        destinationPortRanges: []
        sourceAddressPrefixes: []
        destinationAddressPrefixes: []
    }
}
{
    name: 'Inbound-GWManager-Allow'
    properties: {
        protocol: 'TCP'
        sourcePortRange: '*'
        destinationPortRange: '443'
        sourceAddressPrefix: 'GatewayManager'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 120
        direction: 'Inbound'
        sourcePortRanges: []
        destinationPortRanges: []
        sourceAddressPrefixes: []
        destinationAddressPrefixes: []
    }
}
{
  name: 'Inbound-LoadBalancer-Allow'
  properties: {
      protocol: 'TCP'
      sourcePortRange: '*'
      destinationPortRange: '443'
      sourceAddressPrefix: 'AzureLoadBalancer'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 140
      direction: 'Inbound'
      sourcePortRanges: []
      destinationPortRanges: []
      sourceAddressPrefixes: []
      destinationAddressPrefixes: []
  }
}
{
  name: 'Inbound-BastionHostComms-Allow'
  properties: {
      protocol: 'TCP'
      sourcePortRange: '*'
      destinationPortRange: ''
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 160
      direction: 'Inbound'
      sourcePortRanges: []
      destinationPortRanges: [
        '8080'
        '5701'
      ]
      sourceAddressPrefixes: []
      destinationAddressPrefixes: []
  }
}
{
  name: 'Outbound-BastionHostComms-Allow'
  properties: {
      protocol: 'TCP'
      sourcePortRange: '*'
      destinationPortRange: ''
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 180
      direction: 'Outbound'
      sourcePortRanges: []
      destinationPortRanges: [
        8080
        5701
      ]
      sourceAddressPrefixes: []
      destinationAddressPrefixes: []
  }
}
{
    name: 'Outbound-SSH-Allow'
    properties: {
        protocol: 'TCP'
        sourcePortRange: '*'
        destinationPortRange: '22'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: 'VirtualNetwork'
        access: 'Allow'
        priority: 200
        direction: 'Outbound'
        sourcePortRanges: []
        destinationPortRanges: []
        sourceAddressPrefixes: []
        destinationAddressPrefixes: []
    }
}
{
    name: 'Outbound-RDP-Allow'
    properties: {
        protocol: 'TCP'
        sourcePortRange: '*'
        destinationPortRange: '3389'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: 'VirtualNetwork'
        access: 'Allow'
        priority: 220
        direction: 'Outbound'
        sourcePortRanges: []
        destinationPortRanges: []
        sourceAddressPrefixes: []
        destinationAddressPrefixes: []
    }
}
{
    name: 'Outbound-HTTPStoAzureCloud'
    properties: {
        description: 'Egress Traffic to other public endpoints in Azure'
        protocol: 'TCP'
        sourcePortRange: '*'
        destinationPortRange: '443'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: 'AzureCloud'
        access: 'Allow'
        priority: 240
        direction: 'Outbound'
        sourcePortRanges: []
        destinationPortRanges: []
        sourceAddressPrefixes: []
        destinationAddressPrefixes: []
    }
}
{
  name: 'Outbound-HTTPtoInternetd'
  properties: {
      description: 'Egress Traffic to other public endpoints in Azure'
      protocol: 'TCP'
      sourcePortRange: '*'
      destinationPortRange: '80'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'Internet'
      access: 'Allow'
      priority: 260
      direction: 'Outbound'
      sourcePortRanges: []
      destinationPortRanges: []
      sourceAddressPrefixes: []
      destinationAddressPrefixes: []
  }
}
]



var sharedServicesSecurityRules = [ {
    name: 'allow-ssh'
    properties: {
      priority: 100
      sourceAddressPrefix: '130.41.187.64/26'
      protocol: 'Tcp'
      destinationPortRange: '22'
      access: 'Allow'
      direction: 'Inbound'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
    }
  } ]

//---------------
// Vnet params
//---------------

@description('Name of the Virtual Network')
param mgmtVnetName string
@description('Address prefix of the Vnet')
param mgmtVnetAddressPrefix string

param gwSubnet string
param gwSubnetPrefix string
param gwNSG string   
param ssSubnet string
param ssSubnetPrefix string
param ssNSG string
param bastionSubnet string
param bastionSubnetPrefix string
param bastionNSG string

var subnetPropertyObject = [
  {
    name: gwSubnet
    properties: {
      addressPrefix: gwSubnetPrefix
      networkSecurityGroup: {
        id: gatewaynsg.outputs.nsgID
      }
    }
  }
  {
    name: ssSubnet
    properties: {
      addressPrefix: ssSubnetPrefix
      networkSecurityGroup: {
        id: sharedservicesnsg.outputs.nsgID
      }
    }
  }
  {
    name: bastionSubnet
    properties: {
      addressPrefix: bastionSubnetPrefix
      networkSecurityGroup: {
        id: bastionnsg.outputs.nsgID
      }
    }
  }
]

param AvailabilitySetNameMgmt string
param deployerosType string 
param mgmtVmSize string 
param Environment string = 'mgmt'
param bastionVMName string 
var subnetRef = '${coreMgtVnet.outputs.vnetID}/subnets/AzureBastionSubnet'

// Keyvault Parameters
@description('Generates a unix timestamp (epoch time) a year on from now')
param epochValue int = dateTimeToEpoch(dateTimeAdd(utcNow(), 'P1Y'))
param kvName string


//----------------------------------------------------------------------------------------------------------
// Resource Creation
//----------------------------------------------------------------------------------------------------------

// Create the resource group


resource coreMgtRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: coreMgtRgName
  location: location
}


module lawWorkspace '../../Modules/logAnalyticsWorkspace.module.bicep' = {
  scope: resourceGroup(coreMgtRgName)
  dependsOn: [
    coreMgtRG
  ]
  name: lawWorkspaceName
  params: {
    logAnalyticsWorkspaceName: lawWorkspaceName
  }
}

module coreMgtVnet '../../Modules/vnet.module.bicep' = {
  scope: resourceGroup(coreMgtRgName)
  dependsOn: [
    coreMgtRG
  ]
  name: mgmtVnetName
  params: {
    LAWworkspaceID: lawWorkspace.outputs.logAnalyticsWorkspaceID
    vnetName: mgmtVnetName
    addressPrefix: mgmtVnetAddressPrefix
    subnetPropertyObject: subnetPropertyObject
  }
}



module gatewaynsg '../../Modules/networkSecurityGroup.module.bicep' = {
  scope: resourceGroup(coreMgtRgName)
  name: gwNSG
  dependsOn: [
    coreMgtRG
  ]
  params: {
    networkSecurityGroupName: gwNSG
    LAWworkspaceID: lawWorkspace.outputs.logAnalyticsWorkspaceID
    isDiagEnabled: isDiagEnabled
    securityRules: gatewaySecurityRules
  }
}
module bastionnsg '../../Modules/networkSecurityGroup.module.bicep' = {
  scope: resourceGroup(coreMgtRgName)
  name: 'bastionnsg'
  dependsOn: [
    coreMgtRG
  ]
  params: {
    networkSecurityGroupName: bastionNSG
    LAWworkspaceID: lawWorkspace.outputs.logAnalyticsWorkspaceID
    isDiagEnabled: isDiagEnabled
    securityRules: bastionSecurityRules
  }
}
module sharedservicesnsg '../../Modules/networkSecurityGroup.module.bicep' = {
  scope: resourceGroup(coreMgtRgName)
  name: ssNSG
  dependsOn: [
    coreMgtRG
  ]
  params: {
    networkSecurityGroupName: ssNSG
    LAWworkspaceID: lawWorkspace.outputs.logAnalyticsWorkspaceID
    isDiagEnabled: isDiagEnabled
    securityRules: sharedServicesSecurityRules
  }
}



// Deploy the Keyvault Resource

module mgmtVmKv '../../Modules/keyvault.module.bicep' = {
  scope: resourceGroup(coreMgtRgName)
  name: 'managementkeyVault'
  params: {
    vaultName: kvName
    isPrivateEndpointEnabled: false
    LAWworkspaceID: lawWorkspace.outputs.logAnalyticsWorkspaceID
    location: location
    isDiagEnabled: isDiagEnabled
  }
}



// Deploy the Secrets

module mgmtVmKvSecretUserPass '../../Modules/keyVaultSecret.module.bicep' = {
  scope: resourceGroup(coreMgtRgName)
  name: 'VirtualmachinePassword'
  dependsOn: [
    mgmtVmKv
  ]
  params: {
    kvName: kvName
    secretExpDate: epochValue
    secretName: 'VirtualmachinePassword'
   
  }
}

// Access te Keyvault secrets

resource mgmtVMKeyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  //name: mgmtVmKv.name
  name: mgmtVmKv.outputs.keyVaultName
  scope: resourceGroup(coreMgtRgName)

}


// SAP deployer machine deployment 

module deployerMachine '../../Modules/virtualMachineLinuxSapAS.bicep' = {
  scope: resourceGroup(coreMgtRgName)
  name: mgmtVmName
  params: {
    availabilitySetName: AvailabilitySetNameMgmt
    OperatingSystem: deployerosType
    SubnetName: 'Shared-Services-Subnet'
    virtualMachineCount: 1
    virtualMachineName: mgmtVmName
    virtualMachineUserName: virtualMachineUserName
    virtualMachinePassword: mgmtVMKeyVault.getSecret('VirtualmachinePassword')
    virtualMachineSize: mgmtVmSize
    vNetName: mgmtVnetName
    vNetResourceGroup: coreMgtRgName
    osType: deployerosType
    Environment: Environment
    loadBalancerBackendPoolid:[]
    location: location
  }
  dependsOn: [
    coreMgtVnet
    mgmtVmKvSecretUserPass
  ]
}

// Bastion Machine deployment

module bastionMachine '../../Modules/bastion.module.bicep' = {
  scope: resourceGroup(coreMgtRgName)
  name: bastionVMName
  params: {
    bastionSubnetID: subnetRef
    LAWworkspaceID: lawWorkspace.outputs.logAnalyticsWorkspaceID
    bastionRG: coreMgtRgName
    location: location
  }
  dependsOn: [
    coreMgtVnet
  ]
}

// SAP installable storage account



module sapBitsStorageAccount  '../../Modules/storageAccount.module.bicep' = {
  scope: resourceGroup(coreMgtRgName)
  name: sapBitsStrAccountName
  params: {
    LAWworkspaceID: lawWorkspace.outputs.logAnalyticsWorkspaceID
    location: location

  }
}


output coreMgtVnetId string = coreMgtVnet.outputs.vnetID
output coreMgtRgName string = coreMgtRG.name
