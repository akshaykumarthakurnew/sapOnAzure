/*
Deploys a Bastion instance into an existing virtual network. An existing subnet ID parameter must be provided.

@parameters 
  bastionSubnetID: String Existing vnet/subnet ID
  bastionHostName: String
@author Aaron Cross
@version 1.0
@date 16th June 2021
*/

param location string
param bastionSubnetID string

param bastionHostName string = 'BASTION-${uniqueString(resourceGroup().id)}'

param isDiagEnabled bool = false

param LAWworkspaceID string

param bastionRG string

var publicIpAddressName = 'PIP-${bastionHostName}'

module publicIPaddress 'publicIP.module.bicep' = {
  name: 'bastionPIP'
  scope: resourceGroup(bastionRG)
  params:{
    location: location
    pipName: publicIpAddressName
    pipSku: 'Standard'
    pipTier: 'Regional'
    LAWworkspaceID: LAWworkspaceID
    isDiagEnabled: isDiagEnabled
    pipAllocationMethod: 'Static'     
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2020-05-01' = {
  name: bastionHostName
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-${bastionHostName}-ipcfg'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: bastionSubnetID
          }
          publicIPAddress: {
            id: publicIPaddress.outputs.publicIpID
          }
        }
      }
    ]
  }
}

resource service 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(isDiagEnabled){
  name: 'setbypolicy'
  scope: bastionHost
  properties: {
    workspaceId: LAWworkspaceID
    logs: [
      {
        category: 'BastionAuditLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}


// output bastionHostId string = bastionHost.id
