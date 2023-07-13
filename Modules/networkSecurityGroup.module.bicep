/*
Deploys a Network Security Group with default rules. An existing subnet ID parameter must be provided.

@parameters 
  networkSecurityGroupName: String
  securityRules: Array[]. E.g:
        {
        name: 'allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
*/
param networkSecurityGroupName string = 'NSG-${uniqueString(resourceGroup().id)}'
param isDiagEnabled bool = false
param LAWworkspaceID string

param securityRules array = []

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName
  location: resourceGroup().location
  properties: {
    securityRules: securityRules
  }
}

resource service 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(isDiagEnabled){
  name: 'setbypolicy'
  scope: nsg
  properties: {
    workspaceId: LAWworkspaceID
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
  }
}

output nsgID string = nsg.id
