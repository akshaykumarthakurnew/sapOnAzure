/*
Deploys a storageAccount resource type or Data Lake resource type

@parameters 
  location: string
  storageAccountName: string
  storageAccountKind: string
  skuName: string 
  accessTier: string
  minimumTlsVersion: string
  allowBlobPublicAccess: bool
  allowSharedKeyAccess: bool
  isDataLakeEnabled: bool
  largeFileSharesState: string
  isNfsV3Enabled: bool
  supportsHttpsTrafficOnly: bool
  bypassExceptions: string
  dataProtectionEnabled: bool
  containerRestorePolicyEnabled: bool
  containerRestorePolicyDays: int
  deleteRetentionPolicyEnabled: bool
  deleteRetentionPolicyDays: int
  isBlobVersioningEnabled: bool
  enableBlobChangeFeed: bool
  containerDeleteRetentionPolicyEnabled: bool
  containerDeleteRetentionPolicyDays: int
  requireCmksForStorageAccountEncryption: bool
  keyvaultName: string
  LAWworkspaceID: string
  isDiagEnabled bool

@relatedModule encryptStorageAccountWithCmks.module.bicep
@author Basit Farooq
@version 1.0.2
@date 5th October 2021
*/

param location string = resourceGroup().location
param storageAccountName string = 'sa${uniqueString(resourceGroup().id)}'

/*
  Choose whether you want to have premium performance for block blobs, file shares, or page blobs in your storage account.
*/
@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
param storageAccountKind string = 'StorageV2'

/*
  The data in your Azure storage account is always replicated to ensure durability and high availability. 
  Choose a replication strategy that matches your durability requirements. 
*/
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param skuName string = 'Standard_LRS'

/*
  The account access tier is the default tier that is inferred by any blob without an explicitly set tier. 
  The hot access tier is ideal for frequently accessed data, and the cool access tier is ideal for infrequently accessed data. 
  The archive access tier can only be set at the blob level and not on the account.
*/
@allowed([
  'Hot'
  'Cool'
])
param accessTier string = 'Hot'

/*
  Set the minimum TLS version needed by applications using your storage account's data.
*/
@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
])
param minimumTlsVersion string = 'TLS1_2'

/*
  By default, Azure encrypts storage account data at rest. Infrastructure encryption adds a second layer of encryption to your storage account’s data.
*/
param infrastructureEncryptionEnabled bool = true
/* 
  When allow blob public access is enabled, one is permitted to configure container ACLs 
  to allow anonymous access to blobs within the storage account. 
*/
param allowBlobPublicAccess bool = false

/*
  When Allow storage account key access is disabled, any requests to the account that are authorized with Shared Key, 
  including shared access signatures (SAS), will be denied.
*/
param allowSharedKeyAccess bool = true

/*
  Choose to enable Data Lake Storage Gen2 hierarchical namespace to support accelerated big data analytics workloads
  and enables file-level access control lists (ACLs).
*/
param isDataLakeEnabled bool = false

/*
  Choose to enable large file share support up to a maximum of 100 TiB. 
*/
param largeFileSharesState string = 'Disabled'

/*
  Choose to enable Network File System Protocol for your storage account, which allows users to share files across a network.
*/
param isNfsV3Enabled bool = false

/*
  Choose to enable secure transfer option, which enhances the security of your storage account by only allowing requests 
  to the storage account by secure connection. 
*/
param supportsHttpsTrafficOnly bool = true

/*
  Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. 
  Possible values are any combination of Logging|Metrics|AzureServices (For example, "Logging, Metrics"), or None to bypass none of those traffics. 
*/
param bypassExceptions string = 'AzureServices'

/*
  Choose to enable Data protection, which provides options for recovering your data when it is erroneously modified or deleted.
*/
param dataProtectionEnabled bool = false

/* 
  Data protection related parameters
*/

/*
  Use this point-in-time restore parameters to restore one or more containers to an earlier state. 
  If this parameter is enabled, then versioning (isBlobVersioningEnabled), change feed (enableBlobChangeFeed), and 
  blob soft delete (deleteRetentionPolicyEnabled & deleteRetentionPolicyDays) parameters must also be enabled.
*/
param containerRestorePolicyEnabled bool = false
param containerRestorePolicyDays int = 7

/*
  Enables Soft delete feature for blob, which will you to recover blobs that were previously marked for deletion,
  including blobs that were overwritten.
*/
param deleteRetentionPolicyEnabled bool = true
param deleteRetentionPolicyDays int = 7

/*
  Enables versioning for blobs, which will allow you to automatically maintain previous versions of your blobs for 
  recovery and restoration.
*/
param isBlobVersioningEnabled bool = false

/*
  Enable blob change feed, which will allow you to keep track of create, modification, and delete changes 
  to blobs in your account.
*/
param enableBlobChangeFeed bool = false

/*
  Enable soft delete for containers, which will allow you to recover containers that were previously marked for deletion.
*/
param containerDeleteRetentionPolicyEnabled bool = true
param containerDeleteRetentionPolicyDays int = 7

/*
  Specify values for "allowedVNets" paramenter in JSON format, see Example below:
  param AllowedVNets array = [
    {
      vNetId: ''
      subnetName: 'Subnet01'
    }
    {
      vNetId: ''
      subnetName: 'Subnet02'
    }
    ...
  ]
*/
param allowedVNets array = []

param LAWworkspaceID string
param isDiagEnabled bool = false

/*
  Enable customer managed keys for storage account encryption. If this is set to "true", you must also grant storage account access  
  to the selected key vault. Both soft delete and purge protection are also enabled on the key vault and cannot be disabled.
*/
param requireCmksForStorageAccountEncryption bool = false

/*
  Name of the Azure Key Vault and key to be used for storage account encryption. Only specify values for these parameters,
  if customer managed keys are required for storage account encryption.
*/
param keyvaultName string = ''

var kvName = requireCmksForStorageAccountEncryption == true ? keyvaultName : 'cmkNotEnabled'

param tags object = {}

var selectedVirtualNetworks = [for selected in allowedVNets: {
  id: '${selected.vNetId}/subnets/${selected.subnetName}'
  action: 'Allow'
  state: 'Succeeded'
}]

var tenantId = subscription().tenantId

var secretsPermissions = [
  'get'
  'list'
  'wrapKey'
  'unwrapKey'
]

param privateEndpointSubnetId string = ''
param isSaPrivateEndpointBlobEnabled bool = false
param isSaPrivateEndpointFileEnabled bool = false
param isSaPrivateEndpointDfsEnabled bool = false
param requireNetworkAccessPolicyDisable bool = true
param privateDnsZoneIdsDfs array = [

]
param privateDnsZoneIdsBlob array = [

]
param privateDnsZoneIdsFile array = [

]

@description('Array of container information. Container Name and Public Access bool')
param storageContainer array = []
 
resource sa 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  kind: storageAccountKind
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    accessTier: accessTier
    minimumTlsVersion: minimumTlsVersion
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    isHnsEnabled: isDataLakeEnabled
    largeFileSharesState: largeFileSharesState
    isNfsV3Enabled: isNfsV3Enabled
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: infrastructureEncryptionEnabled
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
        queue: {
          enabled: true
          keyType: 'Account'
        }
        table: {
          enabled: true
          keyType: 'Account'
        }
      }
    }
      networkAcls: {
      bypass: bypassExceptions
      virtualNetworkRules:  selectedVirtualNetworks 
      ipRules: []
      defaultAction: 'Deny'
    }
  }
  tags: tags
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = if (dataProtectionEnabled) {
  name: '${storageAccountName}/default'
  properties: {
    isVersioningEnabled: isBlobVersioningEnabled

    deleteRetentionPolicy: {
      enabled: deleteRetentionPolicyEnabled
      days: deleteRetentionPolicyDays
    }
    changeFeed: {
      enabled: enableBlobChangeFeed
    }
    restorePolicy: {
      enabled: containerRestorePolicyEnabled
      days: containerRestorePolicyDays
    }
    containerDeleteRetentionPolicy: {
      enabled: containerDeleteRetentionPolicyEnabled
      days: containerDeleteRetentionPolicyDays
    }
  }

  dependsOn: [
    sa
  ]
}

module saBlobPrivateEndpoint './privateEndPoint.module.bicep' = if(isSaPrivateEndpointBlobEnabled) {
  name: 'PEblob-${storageAccountName}'
  params: {
    privateDnsZoneIds: privateDnsZoneIdsBlob
    location: location
    privateEndPointName: 'PEblob-${storageAccountName}'
     privateEndpointSubnetId: privateEndpointSubnetId
     linkServiceConnections: [
       {
         serviceId: sa.id
         groupIds: [
          'blob'
         ]
       }
     ]
  }
}

module saFilePrivateEndpoint './privateEndPoint.module.bicep' = if(isSaPrivateEndpointFileEnabled) {
  name: 'PEfile-${storageAccountName}'
  params: {
    privateDnsZoneIds: privateDnsZoneIdsFile
    location: location
    privateEndPointName: 'PEfile-${storageAccountName}'
     privateEndpointSubnetId: privateEndpointSubnetId
     requireNetworkAccessPolicyDisable: requireNetworkAccessPolicyDisable
     linkServiceConnections: [
       {
         serviceId: sa.id
         groupIds: [
          'file'
         ]
       }
     ]
  }
}

module saDfsPrivateEndpoint './privateEndPoint.module.bicep' = if(isSaPrivateEndpointDfsEnabled) {
  name: 'PEDfs-${storageAccountName}'
  params: {
    privateDnsZoneIds: privateDnsZoneIdsDfs
    location: location
    privateEndPointName: 'PEdfs-${storageAccountName}'
     privateEndpointSubnetId: privateEndpointSubnetId
     requireNetworkAccessPolicyDisable: requireNetworkAccessPolicyDisable
     linkServiceConnections: [
       {
         serviceId: sa.id
         groupIds: [
          'dfs'
         ]
       }
     ]
  }
}

resource saContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = [for item in storageContainer: if(storageContainer!='') {
  name: '${storageAccountName}/default/${item.name}'
  properties: {
    publicAccess: item.publicAccess //may file due to global config
  }
  dependsOn: [
    sa
  ]
}]

resource service 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(isDiagEnabled) {
  scope: sa
  name: 'setbypolicy'
  properties: {
    
    workspaceId: LAWworkspaceID
     metrics: [
      {
        category:'Transaction'
        enabled: true
      }
    ]
  }
  dependsOn: [
    sa
  ]
}


resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' existing = if (requireCmksForStorageAccountEncryption) {
  name: keyvaultName
}

resource assignStorageAccountManagedIdentityAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = if (requireCmksForStorageAccountEncryption) {
  name: '${kvName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: reference(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2021-06-01', 'full').identity.principalId
        permissions: {
          keys: secretsPermissions
        }
      }
    ]
  }
  dependsOn: [
    sa
  ]
}

output storageAccountId string = sa.id
output skuName string = sa.sku.name
output storageAccountKind string = sa.kind
output primaryEndpointsDfs string = sa.properties.primaryEndpoints.dfs
