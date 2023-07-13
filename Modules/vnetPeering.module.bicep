/*
Creates a vnet peering between two vnets

@parameters 
  localVnetName: String
  remoteVnetName: String
  remoteVnetId: String Existing ID for remote hub vnet

*/
param localVnetName string
param remoteVnetName string
param remoteVnetId string
param allowForwardedTraffic bool = true
param allowGatewayTransit bool = false
param allowVirtualNetworkAccess bool = true
param useRemoteGateways bool = false

resource peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-06-01' = {
  name: '${localVnetName}/${localVnetName}-to-${remoteVnetName}'
  properties: {
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
  }
}
