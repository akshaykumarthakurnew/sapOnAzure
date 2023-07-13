//--------------------------------------------------------------------------------------------------------------------------------------------------
// Parameter Section
//--------------------------------------------------------------------------------------------------------------------------------------------------

param storageAccounts string 
param location string
var FileStorageType = 'FileStorage'
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
param privateEndPointName string = 'pependpoint'
param privateEndPointSubnetID string
param virtualNetworkID string
//NFS File share parameters

param FilshareSAPSystem string = 'sapnw1'
param FileshareSAPTransport string = 'saptrans'
var FileshareProperties = {

  accessTier: 'Premium'
  shareQuota: 128
  enabledProtocols: 'NFS'
  rootSquash: 'NoRootSquash'
}

//--------------------------------------------------------------------------------------------------------------------------------------------------
// Deploy the storage Account
//--------------------------------------------------------------------------------------------------------------------------------------------------

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccounts
  location: location
  sku: {
    name: skuName
  }
  kind: FileStorageType
  properties: {
    dnsEndpointType: dnsEndpointType
    defaultToOAuthAuthentication: defaultToOAuthAuthentication
    publicNetworkAccess: publicNetworkAccess
    allowCrossTenantReplication: allowCrossTenantReplication
    minimumTlsVersion: minimumTlsVersion
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    largeFileSharesState: largeFileSharesState

    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    encryption: {
      requireInfrastructureEncryption: requireInfrastructureEncryption
      services: {
        file: {
          enabled: true
          keyType: 'Account'
        }
        blob: {
          enabled: true
          keyType: 'Account'
        }

      }
      keySource: 'Microsoft.Storage'
    }

  }
}
resource StorageAccountShareSettings 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {
        multichannel: {
          enabled: false
        }
      }
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource SAPNFSFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  parent: StorageAccountShareSettings
  name: FilshareSAPSystem
  properties: FileshareProperties

}

resource SAPNFStrans 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  parent: StorageAccountShareSettings
  name: FileshareSAPTransport
  properties: FileshareProperties

}

//Private endpoint resource creation

resource filsSharePrivateEndPoint 'Microsoft.Network/privateEndpoints@2022-11-01' = {
  name: privateEndPointName
  location: location
  properties: {
    subnet: {
      id: privateEndPointSubnetID
    }
    customNetworkInterfaceName: '${storageAccounts}-nic'
    privateLinkServiceConnections: [
      {
        name: privateEndPointName
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

//Private DNS zone Resource Creation

var dnsZoneName =  'privatelink.file.core.windows.net'


resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneName
  location: 'global'
 
 
}




resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-11-01' = {
  name: '${storageAccounts}-default'
  parent: filsSharePrivateEndPoint
  properties: {
     privateDnsZoneConfigs: [
       {
        name: dnsZoneName
         properties: {
           privateDnsZoneId: dnsZone.id
         }
       }
     ]
  }
}



param vnetLinkName string
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
 name: vnetLinkName
 parent: dnsZone
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: virtualNetworkID
    }
  }
}
