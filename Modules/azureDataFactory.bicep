/*This module deploys a single datafactory resource. If the name parameter is not supplied a random unique name will be generated

@param dataFactoryName: string
@param location: string
@param identity: string
Note: Currently only SystemAssigned identity type is supported for Bicep modules

*/

param dataFactoryName string = 'adf${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
@allowed([
  'SystemAssigned'
  'UserAssigned'
])
param identity string = 'SystemAssigned'

resource adf 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location:location
  tags:{}
  identity:{
    type:identity
  }
}
output dataFactoryNameId string = adf.id
