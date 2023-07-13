/*
Deploys an array of subnets to an existing vnet, this can be used if you have dependences like azure firewall 

@parameters 
  parentvnetName: String
  subnetDefinitions: Array[] including any valid subnet properties
  e.g.   [{
          parentVnetName: 'vnet01' 
          name: 'default'
          properties: {
            addressPrefix: '10.0.1.0/24'
            networkSecurityGroup: {
             id: NSG.outputs.nsgID
            }
           routeTable: {
            id: UDR.outputs.id
           }
          }
         }]

*/
param subnetPropertyObject array 
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = [for sn in subnetPropertyObject: { 
  name: '${sn.parentVnetName}/${sn.name}'
  properties: sn.properties
}]
