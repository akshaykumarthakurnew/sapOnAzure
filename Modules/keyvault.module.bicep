/*
Deploys a single Key Vault. If the name parameter is not supplied a randomly generated name will be used.


@parameters
vaultName: String
sku: String
tenant: String ID for AAD tenant to be used to auth with KV
enabledForDeployment: Boolean to support deployment
enabledForTemplateDeployment: Boolean to support template deployment
enabledForDiskEncryption: Boolean to support disk encryption
enableRbacAuthorization: Boolean for RBAC
enablePurgeProtection: Boolean for Purge Protection
softDeleteRetentionInDays: Boolean for soft delete
networkAcls: Array[] containing IPrules and virtual network rules for KV firewall

*/

param vaultName string = 'KV72-${uniqueString(resourceGroup().id)}'
param sku string = 'Standard'
param enabledForDeployment bool = true
param enabledForTemplateDeployment bool = true
param enabledForDiskEncryption bool = true
param enableRbacAuthorization bool = false
param enablePurgeProtection bool = false
param softDeleteRetentionInDays int = 90
param isDiagEnabled bool = false
param LAWworkspaceID string //Log Analytics WS
param networkAcls object = {
  defaultAction: 'Deny'
  bypass: 'AzureServices'
  ipRules: [
  {
    value: '49.36.178.42'
  }
]
  virtualNetworkRules:[]
}
param isPrivateEndpointEnabled bool 
param privateEndpointSubnetId string = ''
param requireNetworkAccessPolicyDisable bool = true
param privateDNSZoneIds array = [
  
]
param location string = resourceGroup().location

var tenant = subscription().tenantId

param accessPolicies array = []

resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: vaultName
  location: location
  properties: {
    tenantId: tenant
    sku: {
      family: 'A'
      name: sku
    }
    accessPolicies: accessPolicies
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enableRbacAuthorization: enableRbacAuthorization
    enablePurgeProtection: enablePurgeProtection == true ? true : any(null)
    networkAcls: networkAcls
  }
}
var principalID = '34eebf4c-b9ac-4fcf-a077-84aa2ebf4529'
var permissions = [
  'get'
  'list'
]
resource accesspolicy1 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  parent: keyvault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: principalID
        permissions: {
          secrets: permissions
          keys: permissions
        }
      }
    ]
  }
}

module kvPrivateEndpoint '../Modules/privateEndPoint.module.bicep' = if(isPrivateEndpointEnabled) {
  name: 'PE-${vaultName}'
  params: {
    privateDnsZoneIds: privateDNSZoneIds
    location: location
    privateEndPointName: 'PE-${vaultName}'
    requireNetworkAccessPolicyDisable: requireNetworkAccessPolicyDisable
     privateEndpointSubnetId: privateEndpointSubnetId
     linkServiceConnections: [
       {
         serviceId: keyvault.id
         groupIds: [
          'vault'
         ]
       }
     ]
  }
}

 resource service 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(isDiagEnabled) {
  scope: keyvault
  name: 'setbypolicy'
  properties: {
    
    workspaceId: LAWworkspaceID
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category:'AllMetrics'
        enabled: true
      }
    ]
  }

}
 
output keyVaultId string = keyvault.id
output keyVaultName string = keyvault.name
