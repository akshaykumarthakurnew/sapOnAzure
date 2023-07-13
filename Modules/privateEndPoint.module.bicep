/*
Deploys a privateEndpoints resource type

@parameters 
  privateEndPointName: String
  location: string
  linkServiceConnections array
  privateEndpointSubnetId string
  
@author Basit Farooq
@version 1.0
@date 21st September 2021
*/
param location string = resourceGroup().location
param privateEndPointName string = 'privateEndpoint${uniqueString(resourceGroup().id)}'
param linkServiceConnections array
param privateEndpointSubnetId string
param requireNetworkAccessPolicyDisable bool = true
param tags object = {}
var privateDnsZoneGroupName = '${privateEndPointName}-privateDnsZoneGroup'
param privateDnsZoneIds array = [
  
]

var vnet = split('${privateEndpointSubnetId}','/')[8]
var vnetRG = split('${privateEndpointSubnetId}','/')[4]
var subnet = last(split('${privateEndpointSubnetId}','/'))
var subscription = split('${privateEndpointSubnetId}','/')[2]

resource PESubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  name: '${vnet}/${subnet}'
  scope: resourceGroup(subscription,vnetRG)

}
var existingAddressPrifix = PESubnet.properties.addressPrefix
var vnetObject = [
  {
  parentVnetName: vnet
  name: subnet
  properties: {
    addressPrefix: existingAddressPrifix
    privateEndpointNetworkPolicies : 'Disabled'
  }
 }
]
module redeploySubnet 'subnet.module.bicep' = if(requireNetworkAccessPolicyDisable) {
  name: subnet
  scope: resourceGroup(subscription,vnetRG)
  params: {
    subnetPropertyObject: vnetObject
  }
}

resource privateEndPoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: privateEndPointName

  dependsOn: [
    redeploySubnet
  ]
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [for item in linkServiceConnections: {
      name: privateEndPointName
      properties: {
        privateLinkServiceId: item.serviceId
        groupIds: item.groupIds
      }
    }]
  }
  tags: tags
}

resource PrivateDnsZoneGroupName 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-07-01' = {
  parent: privateEndPoint
  name: privateDnsZoneGroupName
  properties: {
    privateDnsZoneConfigs: [for item in privateDnsZoneIds: {
      name: 'dnsConfig'
      properties: {
        privateDnsZoneId: item
      }
    }]
  }
}

output privateEndPointId string = privateEndPoint.id
output privateEndPointName string = privateEndPoint.name
