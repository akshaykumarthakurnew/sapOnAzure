/*
A solution to deploy the SAP S4HANA infrastructure
Please use the correct Parameter file for creation of the environment This file supports 3 Environments
Namely

sbx = Sandbox
dev = Development
qas = Quality Assurance 

@author Rajdeep Das
@author Akshay Kumar
@version 1.0
@date 27 Feb 2023
*/

// Deployment scope

targetScope = 'subscription'

//---------------------------------------------------------------------------------------
// Parameter section
//---------------------------------------------------------------------------------------

//Global Parameters

param location string
var lawWorkspaceId = lawWorkspace.outputs.logAnalyticsWorkspaceID
param tags object = {
  Environment: Environment
  CreatedBy: 'Bicep'
  SAPSID: SAPSID

}



@description('Please provide the System Identifier')
@maxLength(3)
param SAPSID string = 'S4S'
param sidLower string = toLower(SAPSID)
//VM Global parameters

@description('The stack type of the SAP system.')
@allowed([
  'ABAP'
  'JAVA'
  'ABAP+JAVA'
])
param stackType string = 'ABAP'

@description('Define the availability type for the SAP System')
@allowed([
  'HA'
  'Not HA'
])
param systemAvailability string = 'Not HA'

@description('Username and password for accesing the VM')
param virtualMachineUserName string



@description('Application VM name')
param AppVMname string = '${sidLower}-APPVM'
param AvailbilitySetNameapp string = '${sidLower}-appavset'


@description('Webdispatcher VM Name')
param WebdispVMname string = '${sidLower}-WebDisp'
param AvailbilitySetNameWebdisp string = '${sidLower}-webavset'

@description('Database VM Name')

param DBVMname string = '${sidLower}-db'
param AvailbilitySetNamedb string = '${sidLower}-dbavset'

@description('The type of the operating system you want to deploy.')
@allowed([
  'Windows Server 2012 Datacenter'
  'Windows Server 2012 R2 Datacenter'
  'Windows Server 2016 Datacenter'
  'sles-sap-12-sp5'
])
param osType string

var vmSizes = {
  'Small < 30.000 SAPS': {
    'Not HA': {
      clserversize: 'Standard_D8s_v3'
      clservercount: 1
      clserverdisks: [
        {
          lun: 0
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 1
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 2
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 3
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }

      ]
      diserversize: 'Standard_D8s_v3'
      diservercount: 1
    }
    HA: {
      clserversize: 'Standard_D8s_v3'
      clservercount: 2
      clserverdisks: [
        {
          lun: 0
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 1
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 2
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 3
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 4
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
      ]
      diserversize: 'Standard_D8s_v3'
      diservercount: 2
    }
  }
  'Medium < 70.000 SAPS': {
    'Not HA': {
      clserversize: 'Standard_D16s_v3'
      clservercount: 1
      clserverdisks: [
        {
          lun: 0
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 1
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 2
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 3
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 4
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 5
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 6
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
      ]
      diserversize: 'Standard_D8s_v3'
      diservercount: 4
    }
    HA: {
      clserversize: 'Standard_D16s_v3'
      clservercount: 2
      clserverdisks: [
        {
          lun: 0
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 1
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 2
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 3
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 4
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 5
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 6
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
      ]
      diserversize: 'Standard_D8s_v3'
      diservercount: 4
    }
  }
  'Large < 180.000 SAPS': {
    'Not HA': {
      clserversize: 'Standard_GS4'
      clservercount: 1
      clserverdisks: [
        {
          lun: 0
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 1
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 2
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 3
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 4
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 5
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
      ]
      diserversize: 'Standard_D16s_v3'
      diservercount: 6
    }
    HA: {
      clserversize: 'Standard_GS4'
      clservercount: 2
      clserverdisks: [
        {
          lun: 0
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 1
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 2
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 3
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 4
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 5
          diskSizeGB: 512
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
      ]
      diserversize: 'Standard_D16s_v3'
      diservercount: 6
    }
  }
  'X-Large < 250.000 SAPS': {
    'Not HA': {
      clserversize: 'Standard_GS5'
      clservercount: 1
      clserverdisks: [
        {
          lun: 0
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 1
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 2
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 3
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 4
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 5
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 6
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
      ]
      diserversize: 'Standard_D16s_v3'
      diservercount: 10
    }
    HA: {
      clserversize: 'Standard_GS5'
      clservercount: 2
      clserverdisks: [
        {
          lun: 0
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 1
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 2
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 3
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 4
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 5
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
        {
          lun: 6
          diskSizeGB: 1023
          createOption: 'Empty'
          caching: 'ReadOnly'
        }
      ]
      diserversize: 'Standard_D16s_v3'
      diservercount: 10
    }
  }
}

var clvmCount = vmSizes[SAPSAPSType][systemAvailability].clservercount
var clvmDisks = vmSizes[SAPSAPSType][systemAvailability].clserverdisks
var divmCount = vmSizes[SAPSAPSType][systemAvailability].diservercount


var vmSkuSize = vmSizes[SAPSAPSType][systemAvailability].clserversize


// Parameter - RESOURCE GROUP

@description('Small=8000 SAPS,Medium=16000,Large=32000,Extra Large=64000')
@allowed([
  'Demo'
  'Small < 30.000 SAPS'
  'Medium < 70.000 SAPS'
  'Large < 180.000 SAPS'
  'X-Large < 250.000 SAPS' ])

param SAPSAPSType string = 'Small < 30.000 SAPS'

@description('Indicates the type if SAP solution the infra is intended for S4/Neweaver')

param SAPSolutionName string = 'S4HANA'

@description('Indiates Environment type sbx = Sandbox,dev = Development,qas = Quality Assurance')
@allowed([
  'sbx'
  'qas'
  'dev'
])
param Environment string

@description('Name of the resource Group')
param SAPsolRGname string = 'RG-${SAPSolutionName}-${sidLower}-${Environment}-${stackType}'

//NSG parameters

param appnetworkSecurityGroupName string 
param isDiagEnabled bool = false
var appsecurityRules = [ {
    name: 'allow-rdp'
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

param dbnetworkSecurityGroupName string
var dbsecurityRules = [ 
  {
    name: 'allow-apponly'
    properties: {
      priority: 100
      sourceAddressPrefix: appAddressPrefix
      protocol: 'Tcp'
      destinationPortRange: '1433'
      access: 'Allow'
      direction: 'Inbound'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
    }
  }
  {
    name: 'allow-anfonly'
    properties: {
      priority: 120
      sourceAddressPrefix: anfAddressPrefix
      protocol: 'Tcp'
      destinationPortRange: '445'
      access: 'Allow'
      direction: 'Inbound'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
    }
  }
 ]

//Vnet parameters

@description('Name of the Vnet')
param SAPs4vnet string = 'Vnet-${sidLower}-${Environment}'
@description('Address Prefix of the Vnet')
param SAPS4VnetaddressPrefix string = '10.0.0.0/16'

param appSubnet string
param appAddressPrefix string
param dbSubnet string
param dbAddressPrefix string
param anfSubnet string
param anfAddressPrefix string

var subnetPropertyObject = [
  {
    name: appSubnet
    properties: {
      addressPrefix: appAddressPrefix
      networkSecurityGroup: {
        id: appnsg.outputs.nsgID
      }
    }
  }
  {
    name: dbSubnet
    properties: {
      addressPrefix: dbAddressPrefix
      networkSecurityGroup: {
        id: dbnsg.outputs.nsgID
      }
    }
  }
  {
    name: anfSubnet
    properties: {
      addressPrefix: anfAddressPrefix
    }
  }
]

//NFS File share parameters

param FilshareSAPSystem string = 'sapnw1'
param FileshareSAPTransport string = 'saptrans'

param privateEndPointName string = 'pep-${SAPSID}-${Environment}'

//  Storage Account parameters

param storageAccounts string 
param dnsEndpointType string = 'Standard'
param defaultToOAuthAuthentication bool = false
param publicNetworkAccess string = 'Disabled'
param allowCrossTenantReplication bool = false
param minimumTlsVersion string = 'TLS1_2'
param allowBlobPublicAccess bool = false
param allowSharedKeyAccess bool = true
param largeFileSharesState string = 'Enabled'
param supportsHttpsTrafficOnly bool = false
param requireInfrastructureEncryption bool = false
param skuName string = 'Premium_ZRS'
//var AppSubnetID = '${Environment}${SAPSID}-appsubnet'

//Automation Account parameters

param AutomationAccountName string = '${Environment}-${SAPSID}-autacct'
param lawWorkspaceName string = '${Environment}-${SAPSID}-lawworkspace'



// Keyvault Parameters
@description('Generates a unix timestamp (epoch time) a year on from now')
param epochValue int = dateTimeToEpoch(dateTimeAdd(utcNow(), 'P1Y'))
param sapKvName string 


//--------------------------------------------------------------------------------------------------------------------------------------------------
// Resource section
//--------------------------------------------------------------------------------------------------------------------------------------------------

// Create the Resource Group

resource SapS4RGSBX 'Microsoft.Resources/resourceGroups@2022-09-01' = {

  name: SAPsolRGname
  location: location
  tags: tags
}


// Create the Network Security Group

module appnsg '../../Modules/networkSecurityGroup.module.bicep' = {
  scope: resourceGroup(SAPsolRGname)
  name: appnetworkSecurityGroupName
  dependsOn: [
    SapS4RGSBX
  ]
  params: {
    networkSecurityGroupName: toLower(appnetworkSecurityGroupName)
    LAWworkspaceID: lawWorkspaceId
    isDiagEnabled: isDiagEnabled
    securityRules: appsecurityRules
  }
}

module dbnsg '../../Modules/networkSecurityGroup.module.bicep' = {
  scope: resourceGroup(SAPsolRGname)
  name: dbnetworkSecurityGroupName
  dependsOn: [
    appnsg
  ]
  params: {
    networkSecurityGroupName: toLower(dbnetworkSecurityGroupName)
    LAWworkspaceID: lawWorkspaceId
    isDiagEnabled: isDiagEnabled
    securityRules: dbsecurityRules
  }
}

// Create the Vnets and Subnets

module SapS4HANAVnet '../../Modules/vnet.module.bicep' = {
  scope: resourceGroup(SAPsolRGname)
  dependsOn: [
    SapS4RGSBX
  ]
  name: SAPs4vnet
  params: {
    LAWworkspaceID: lawWorkspaceId
    vnetName: SAPs4vnet
    addressPrefix: SAPS4VnetaddressPrefix
    subnetPropertyObject: subnetPropertyObject
  }
}



// Deploy the Keyvault Resource

module sapVmkv '../../Modules/keyvault.module.bicep' = {
  scope: resourceGroup(SAPsolRGname)
  name: 'sapKeyvaultName'
  params: {
    vaultName: sapKvName
    isPrivateEndpointEnabled: false
    LAWworkspaceID: lawWorkspaceId
    location: location
    isDiagEnabled: isDiagEnabled
  }
}

// Deploy the Secrets

module sapVmkvSecretUserPass '../../Modules/keyVaultSecret.module.bicep' = {
  scope: resourceGroup(SAPsolRGname)
  name: 'sapkeyvaultSecret'
  params: {
    kvName: sapKvName
    secretExpDate: epochValue
    secretName: 'VirtualmachinePassword'
   
  }
  dependsOn: [
    sapVmkv
  ]
}

// Access te Keyvault secrets

resource sapVMKeyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: sapVmkv.outputs.keyVaultName
  scope: resourceGroup(SAPsolRGname)
}

param loadbalancerbackendPoolID array = []

// Deploy the Application and ASCS VM

module SAPsndBoxAppVM '../../Modules/virtualMachineLinuxSapAS.bicep' = {
  scope: resourceGroup(SAPsolRGname)
  name: AppVMname
  params: {
    availabilitySetName: AvailbilitySetNameapp
    Environment: Environment
    OperatingSystem: osType
    SubnetName: '${Environment}${SAPSID}-appsubnet'
    virtualMachineCount: clvmCount
    virtualMachineName: AppVMname
    virtualMachinePassword: sapVMKeyVault.getSecret('VirtualmachinePassword')
    virtualMachineSize: vmSkuSize
    virtualMachineUserName: virtualMachineUserName
    vNetName: SapS4HANAVnet.name
    vNetResourceGroup: SapS4RGSBX.name
    osType: osType
    loadBalancerBackendPoolid:loadbalancerbackendPoolID
    location: location
  }
  dependsOn: [
    SapS4HANAVnet
    sapVmkvSecretUserPass
  ]
}


// Deploy the Webdispatcher VM

module SAPsndBoxWebDispVM '../../Modules/virtualMachineLinuxSapAS.bicep' = {
  scope: resourceGroup(SAPsolRGname)
  name: WebdispVMname
  params: {
    availabilitySetName: AvailbilitySetNameWebdisp
    Environment: Environment
    OperatingSystem: osType
    SubnetName: '${Environment}${SAPSID}-appsubnet'
    virtualMachineCount: clvmCount
    virtualMachineName: WebdispVMname
    virtualMachinePassword: sapVMKeyVault.getSecret('VirtualmachinePassword')
    virtualMachineSize: vmSkuSize
    virtualMachineUserName: virtualMachineUserName
    vNetName: SapS4HANAVnet.name
    vNetResourceGroup: SapS4RGSBX.name
    osType: osType
    loadBalancerBackendPoolid:loadbalancerbackendPoolID
    location: location
    }
  dependsOn: [
    SAPsndBoxAppVM
    sapVmkvSecretUserPass
  ]
}

// Deploy the Database VM

module SAPsndBoxDBVM '../../Modules/virtualMachineLinuxSapAS.bicep' = {
  scope: resourceGroup(SAPsolRGname)
  name: DBVMname
  params: {
    availabilitySetName: AvailbilitySetNamedb
    Environment: Environment
    OperatingSystem: osType
    SubnetName: '${Environment}${SAPSID}-dbsubnet'
    virtualMachineCount: divmCount
    virtualMachineName: DBVMname
    virtualMachinePassword: sapVMKeyVault.getSecret('VirtualmachinePassword')
    virtualMachineSize: vmSkuSize
    virtualMachineUserName: virtualMachineUserName
    vNetName: SapS4HANAVnet.name
    vNetResourceGroup: SapS4RGSBX.name
    dataDisks: clvmDisks
    osType: osType
    loadBalancerBackendPoolid:loadbalancerbackendPoolID   
    location: location
  }

  dependsOn: [
    SAPsndBoxWebDispVM
    sapVmkvSecretUserPass
  ]
}


// Deploy the Storage account with PrivateEndpoint

module storageaccount '../../Modules/nfsafsfilshare.module.bicep' = {
  scope: resourceGroup(SAPsolRGname)
  dependsOn: [
    SapS4RGSBX
  ]
  name: storageAccounts
  params: {
    location: location
    allowBlobPublicAccess: allowBlobPublicAccess
    largeFileSharesState: largeFileSharesState
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    skuName: skuName
    allowCrossTenantReplication: allowCrossTenantReplication
    allowSharedKeyAccess: allowSharedKeyAccess
    defaultToOAuthAuthentication: defaultToOAuthAuthentication
    FileshareSAPTransport: FileshareSAPTransport
    FilshareSAPSystem: FilshareSAPSystem
    dnsEndpointType: dnsEndpointType
    minimumTlsVersion: minimumTlsVersion
    publicNetworkAccess: publicNetworkAccess
    requireInfrastructureEncryption: requireInfrastructureEncryption
    storageAccounts: storageAccounts
    privateEndPointSubnetID: '${SapS4HANAVnet.outputs.vnetID}/subnets/${Environment}${SAPSID}-appsubnet'
    privateEndPointName: privateEndPointName
    virtualNetworkID: SapS4HANAVnet.outputs.vnetID
    vnetLinkName: '${SAPs4vnet}-vnetlink'
  }
}

// Deploy the LogAnalytics Workspace

module lawWorkspace '../../Modules/logAnalyticsWorkspace.module.bicep' = {
  scope: resourceGroup(SAPsolRGname)
  dependsOn: [
    SapS4RGSBX
  ]
  name: lawWorkspaceName
  params: {
    logAnalyticsWorkspaceName: lawWorkspaceName

  }
}

// Deploy the Automation Account

module SAPStartStopAutomationAccount '../../Modules/automationAccount.module.bicep' = {
  scope: resourceGroup(SAPsolRGname)
  dependsOn: [
    lawWorkspace
  ]
  name: AutomationAccountName
  params: {
    automationaccountName: AutomationAccountName
    isDiagEnabled: true
    LAWworkspaceID: lawWorkspace.outputs.logAnalyticsWorkspaceID

  }
}

//Recovery Services Vault Parameters

param saprsvname string = 'sapvmrsv'
param rsvPolicy object = {
  name: 'EnginePolicy-IaasVM'
  instantRpRetentionRangeInDays: 2
  timeZone: 'UTC'
  scheduleRunTimes: [
    '17:00'
  ]
  dailyRetentionDurationCount: 7
  daysOfTheWeek: [
    'Sunday'
  ]
  weeklyRetentionDurationCount: 4
  monthlyRetentionDurationCount: 12
  monthsOfYear: [
    'December'
  ]
  yearlyRetentionDurationCount: 1
}

//Recovery Services Vault Resource creation

module rsvvm '../../Modules/recoveryServicesVault.module.bicep' = if (Environment == 'qas') {
  scope: resourceGroup(SAPsolRGname)
  name: saprsvname
  params: {
    LAWworkspaceID: lawWorkspaceId
    location: location
    isDiagEnabled: false
    rsvName: saprsvname
    rsvEnableCrossRegionRestore: false
    rsvPolicy: rsvPolicy
    rsvStorageType: 'LocallyRedundant'
    sku: 'Standard'
  }
}

//Azure Datafactory Parameters

param sapadfname string = 'azuredatafactoryforsapsol'

//Azure Datafactory resource creation

module sapadf '../../Modules/azureDataFactory.bicep' = if (Environment == 'qas') {
  name: sapadfname
  dependsOn:[
    SapS4RGSBX
  ]
  scope: resourceGroup(SAPsolRGname)
  params: {
    dataFactoryName: sapadfname
    identity: 'SystemAssigned'
    location: location

  }
}

//Azure Datalake Gen2 Storage account parameters

param azureDataLakeStorageAccountName string = 'sapdatalake${uniqueString('datalake')}'

//Azure Datalake Gen2 Storage account resource creation

module azureDataLakeforSAP '../../Modules/storageAccount.module.bicep' = if (Environment == 'qas') {
  scope: resourceGroup(SAPsolRGname)
  name: azureDataLakeStorageAccountName
  params: {
    LAWworkspaceID: lawWorkspaceId
    isDataLakeEnabled: true
    accessTier: 'Hot'
    allowBlobPublicAccess: allowBlobPublicAccess
    storageAccountKind: 'StorageV2'
    location: location

  }
}

// Parameter -  LoadBalancer

//Ascs Load Balancer

param AscsLoadbalancerName string = 'ASCS-loadbalancer'
param AscsLbBackendPoolName string = 'ascs-backendpool'
param AscsLBPrivateIP string = '10.0.0.11'
//var AscsLbBackendPoolID  = '${ascslbinternal.outputs.id}/backendAddressPools/ascs-backendpool'

var AscslbIPConfiguration = [
  {
    name: 'Ascs-frontend'
    subnetId: '${SapS4HANAVnet.outputs.vnetID}/subnets/${Environment}${SAPSID}-appsubnet'
    privateIPAddress: AscsLBPrivateIP
    privateIPAddressVersion: 'IPv4'
    privateIPAllocationMethod: 'Static'

    publicIPAddressId: ''

  }
]

var AscslbLoadbalancingRules = [
  {
    name: 'ascs-lbrule'
    frontendIPconfigurationname: 'ascs-frontend'
    backendAddressPoolName: AscsLbBackendPoolName
    frontendPort: 0
    backendPort: 0
    Protocol: 'ALL'
    enableFloatingIP: false
    idleTimeoutInMinutes: 5
    probeName: 'HealthProbe'

  }
]

var AscsLoadBalancerHealthProbe = [
  {
    name: 'HealthProbe'
    protocol: 'Tcp'
    port: 80
    intervalInSeconds: 5
    numberofProbes: 2
  }
]

//Web Dispatcher Load Balancer
param loadbalancerSku string = 'Standard'
param WebDispLoadbalancerName string = 'Webdisp-loadbalancer'
param WebDispLbBackendPoolName string = 'webdisp-backendpool'
param WebDispLBPrivateIP string = '10.0.0.12'


var WebDisplbIPConfiguration = [
  {
    name: 'Webdisp-frontend'
    subnetId: '${SapS4HANAVnet.outputs.vnetID}/subnets/${Environment}${SAPSID}-appsubnet'
    privateIPAddress: WebDispLBPrivateIP
    privateIPAddressVersion: 'IPv4'
    privateIPAllocationMethod: 'Static'
    publicIPAddressId: ''

  }
]

var WebdisplbLoadbalancingRules = [
  {
    name: 'webdisp-lbrule'
    frontendIPconfigurationname: 'webdisp-frontend'
    backendAddressPoolName: WebDispLbBackendPoolName
    frontendPort: 0
    backendPort: 0
    Protocol: 'ALL'
    enableFloatingIP: false
    idleTimeoutInMinutes: 5
    probeName: 'HealthProbe'

  }
]

var WebdispLoadBalancerHealthProbe = [
  {
    name: 'HealthProbe'
    protocol: 'Tcp'
    port: 80
    intervalInSeconds: 5
    numberofProbes: 2
  }
]

//Database LoadBalancer

param DBLoadbalancerName string = 'DB-loadbalancer'
param DBLbBackendPoolName string = 'DB-backendpool'
param DBLBPrivateIP string = '10.0.1.11'

var DBlbIPConfiguration = [
  {
    name: 'db-frontend'
    subnetId: '${SapS4HANAVnet.outputs.vnetID}/subnets/${Environment}${SAPSID}-dbsubnet'
    privateIPAddress: DBLBPrivateIP
    privateIPAddressVersion: 'IPv4'
    privateIPAllocationMethod: 'Static'
    publicIPAddressId: ''

  }
]

var DBlbLoadbalancingRules = [
  {
    name: 'db-lbrule'
    frontendIPconfigurationname: 'db-frontend'
    backendAddressPoolName: DBLbBackendPoolName
    frontendPort: 0
    backendPort: 0
    Protocol: 'ALL'
    enableFloatingIP: false
    idleTimeoutInMinutes: 5
    probeName: 'HealthProbe'

  }
]

var DBLoadBalancerHealthProbe = [
  {
    name: 'HealthProbe'
    protocol: 'Tcp'
    port: 80
    intervalInSeconds: 5
    numberofProbes: 2
  }
]


module webdisplbinternal '../../Modules/loadbalancer.module.bicep' = if (Environment == 'qas') {
  scope: resourceGroup(SAPsolRGname)
  name: WebDispLoadbalancerName
  params: {
    location: location
    name: WebDispLoadbalancerName
    frontendIPConfigurations: WebDisplbIPConfiguration
    backendAddressPools: [
      {
        name: WebDispLbBackendPoolName
      }
    ]
    loadBalancingRules: WebdisplbLoadbalancingRules
    probes: WebdispLoadBalancerHealthProbe
    loadBalancerSku: loadbalancerSku
    tags: tags

  }
}

module ascslbinternal '../../Modules/loadbalancer.module.bicep' = if (Environment == 'qas') {
  scope: resourceGroup(SAPsolRGname)
  name: AscsLoadbalancerName
  params: {
    location: location
    name: AscsLoadbalancerName
    frontendIPConfigurations: AscslbIPConfiguration
    backendAddressPools: [
      {
        name: AscsLbBackendPoolName
      }
    ]
    loadBalancingRules: AscslbLoadbalancingRules
    probes: AscsLoadBalancerHealthProbe
    loadBalancerSku: loadbalancerSku
    tags: tags

  }
}


module dblbinternal '../../Modules/loadbalancer.module.bicep' = if (Environment == 'qas') {
  scope: resourceGroup(SAPsolRGname)
  name: DBLoadbalancerName
  params: {
    location: location
    name: DBLoadbalancerName
    frontendIPConfigurations: DBlbIPConfiguration
    backendAddressPools: [
      {
        name: DBLbBackendPoolName
      }
    ]
    loadBalancingRules: DBlbLoadbalancingRules
    probes: DBLoadBalancerHealthProbe
    loadBalancerSku: loadbalancerSku
    tags: tags

  }
}




output sandboxVnetId string = SapS4HANAVnet.outputs.vnetID
output sanboxRgId string = SapS4RGSBX.id
output lawWorkspaceID string = lawWorkspace.outputs.logAnalyticsWorkspaceID
