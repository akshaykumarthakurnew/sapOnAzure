/*
A module that creates a load balancer

*/

@description('Required. The Load Balancer Name')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Tags to apply to the resource ')
param tags object

@description('Optional. Name of a load balancer SKU.')
@allowed([
  'Basic'
  'Standard'
])
param loadBalancerSku string = 'Standard'

@description('Required. Array of objects containing all frontend IP configurations')
@minLength(1)
param frontendIPConfigurations array

@description('Optional. Collection of backend address pools used by a load balancer.')
param backendAddressPools array = []

@description('Optional. Array of objects containing all load balancing rules')
param loadBalancingRules array = []

@description('Optional. Array of objects containing all probes, these are references in the load balancing rules')
param probes array = []

@description('Optional. Collection of inbound NAT Rules used by a load balancer. Defining inbound NAT rules on your load balancer is mutually exclusive with defining an inbound NAT pool. Inbound NAT pools are referenced from virtual machine scale sets. NICs that are associated with individual virtual machines cannot reference an Inbound NAT pool. They have to reference individual inbound NAT rules.')
param inboundNatRules array = []

@description('Optional. The outbound rules.')
param outboundRules array = []

var frontendsSubnets = [for item in frontendIPConfigurations: {
  id: item.subnetId
}]
var frontendsPublicIPAddresses = [for item in frontendIPConfigurations: {
  id: item.publicIPAddressId
}]
var frontendsObj = {
  subnets: frontendsSubnets
  publicIPAddresses: frontendsPublicIPAddresses
}

var frontendIPConfigurationsvar = [for (frontendIPConfiguration, i) in frontendIPConfigurations: {
  name: frontendIPConfiguration.name
  properties: {
    subnet: !empty(frontendIPConfiguration.subnetId) ? frontendsObj.subnets[i] : null
    publicIPAddress: !empty(frontendIPConfiguration.publicIPAddressId) ? frontendsObj.publicIPAddresses[i] : null
    privateIPAddress: !empty(frontendIPConfiguration.privateIPAddress) ? frontendIPConfiguration.privateIPAddress : null
    privateIPAllocationMethod: !empty(frontendIPConfiguration.subnetId) ? (empty(frontendIPConfiguration.privateIPAddress) ? 'Dynamic' : 'Static') : null
  }
}]

var loadBalancingRulesvar = [for loadBalancingRule in loadBalancingRules: {
  name: loadBalancingRule.name
  properties: {
    backendAddressPool: {
      id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', name, loadBalancingRule.backendAddressPoolName)
    }
    backendPort: loadBalancingRule.backendPort
    disableOutboundSnat: contains(loadBalancingRule, 'disableOutboundSnat') ? loadBalancingRule.disableOutboundSnat : true
    enableFloatingIP: contains(loadBalancingRule, 'enableFloatingIP') ? loadBalancingRule.enableFloatingIP : false
    enableTcpReset: contains(loadBalancingRule, 'enableTcpReset') ? loadBalancingRule.enableTcpReset : false
    frontendIPConfiguration: {
      id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, loadBalancingRule.frontendIPConfigurationName)
    }
    frontendPort: loadBalancingRule.frontendPort
    idleTimeoutInMinutes: contains(loadBalancingRule, 'idleTimeoutInMinutes') ? loadBalancingRule.idleTimeoutInMinutes : 4
    loadDistribution: contains(loadBalancingRule, 'loadDistribution') ? loadBalancingRule.loadDistribution : 'Default'
    probe: {
      id: '${resourceId('Microsoft.Network/loadBalancers', name)}/probes/${loadBalancingRule.probeName}'
    }
    protocol: contains(loadBalancingRule, 'protocol') ? loadBalancingRule.protocol : 'Tcp'
  }
}]

var outboundRulesvar = [for outboundRule in outboundRules: {
  name: outboundRule.name
  properties: {
    frontendIPConfigurations: [
      {
        id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, outboundRule.frontendIPConfigurationName)
      }
    ]
    backendAddressPool: {
      id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', name, outboundRule.backendAddressPoolName)
    }
    protocol: contains(outboundRule, 'protocol') ? outboundRule.protocol : 'All'
    allocatedOutboundPorts: contains(outboundRule, 'allocatedOutboundPorts') ? outboundRule.allocatedOutboundPorts : 63984
    enableTcpReset: contains(outboundRule, 'enableTcpReset') ? outboundRule.enableTcpReset : true
    idleTimeoutInMinutes: contains(outboundRule, 'idleTimeoutInMinutes') ? outboundRule.idleTimeoutInMinutes : 4
  }
}]

var probesvar = [for probe in probes: {
  name: probe.name
  properties: {
    protocol: contains(probe, 'protocol') ? probe.protocol : 'Tcp'
    requestPath: (contains(probe, 'protocol') && toLower(probe.protocol) == 'tcp') ? null : probe.requestPath
    port: contains(probe, 'port') ? probe.port : 80
    intervalInSeconds: contains(probe, 'intervalInSeconds') ? probe.intervalInSeconds : 5
    numberOfProbes: contains(probe, 'numberOfProbes') ? probe.numberOfProbes : 2
  }
}]

resource loadBalancer 'Microsoft.Network/loadBalancers@2022-05-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: loadBalancerSku
  }
  properties: {
    frontendIPConfigurations: frontendIPConfigurationsvar
    backendAddressPools: backendAddressPools
    loadBalancingRules: loadBalancingRulesvar
    outboundRules: outboundRulesvar
    probes: probesvar
  }
}

// module loadBalancer_backendAddressPools 'loadbalancerBackendAddressPool.module.bicep' = [for (backendAddressPool, i) in backendAddressPools: {
//   name: '${uniqueString(deployment().name, location)}-LoadBalancer-backendAddressPools-${i}'
//   params: {
//     loadBalancerName: loadBalancer.name
//     name: backendAddressPool.name
//     loadBalancerBackendAddresses: contains(backendAddressPool, 'loadBalancerBackendAddresses') ? backendAddressPool.loadBalancerBackendAddresses : []
//     tunnelInterfaces: contains(backendAddressPool, 'tunnelInterfaces') ? backendAddressPool.tunnelInterfaces : []
//   }
// }]

// module loadBalancer_inboundNATRules 'loadbalancerInboundNatRules.module.bicep' = [for (inboundNATRule, i) in inboundNatRules: {
//   name: '${uniqueString(deployment().name, location)}-LoadBalancer-inboundNatRules-${i}'
//   params: {
//     loadBalancerName: loadBalancer.name
//     name: inboundNATRule.name
//     frontendIPConfigurationName: inboundNATRule.frontendIPConfigurationName
//     frontendPort: inboundNATRule.frontendPort
//     backendPort: contains(inboundNATRule, 'backendPort') ? inboundNATRule.backendPort : inboundNATRule.frontendPort
//     backendAddressPoolName: contains(inboundNATRule, 'backendAddressPoolName') ? inboundNATRule.backendAddressPoolName : ''
//     enableFloatingIP: contains(inboundNATRule, 'enableFloatingIP') ? inboundNATRule.enableFloatingIP : false
//     enableTcpReset: contains(inboundNATRule, 'enableTcpReset') ? inboundNATRule.enableTcpReset : false
//     frontendPortRangeEnd: contains(inboundNATRule, 'frontendPortRangeEnd') ? inboundNATRule.frontendPortRangeEnd : -1
//     frontendPortRangeStart: contains(inboundNATRule, 'frontendPortRangeStart') ? inboundNATRule.frontendPortRangeStart : -1
//     idleTimeoutInMinutes: contains(inboundNATRule, 'idleTimeoutInMinutes') ? inboundNATRule.idleTimeoutInMinutes : 4
//     protocol: contains(inboundNATRule, 'protocol') ? inboundNATRule.protocol : 'Tcp'
//   }
//   dependsOn: [
//     //loadBalancer_backendAddressPools
//   ]
// }]

@description('The name of the load balancer')
output name string = loadBalancer.name

@description('The resource ID of the load balancer')
output id string = loadBalancer.id
