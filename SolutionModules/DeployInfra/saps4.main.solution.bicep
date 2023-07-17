/*
A solution to deploy the SAP S4HANA infrastructure
Please use the correct Parameter file for creation of the environment This file supports 3 Environments
Namely

sbx = Sandbox
dev = Development
qas = Quality Assurance 

@author Akshay Kumar
@version 1.0
@date 27 Feb 2023
*/

// Deployment scope
targetScope = 'subscription'


//Global Parameters
@description('Specify if the managment place is required or not default value = true')
param isManagmentGroupRequired bool = true
param Environment string
param location string
param virtualMachineUserName string


//--------------------------------------------------------------------------------------------------------------------------------------------------
// Parameter section Managment 
//--------------------------------------------------------------------------------------------------------------------------------------------------


//Managment RG parameters
param coreMgtRgName string = 'RG-${SAPSolutionName}-Core-Management'

//Managment Network  parameters
param mgmtVnetAddressPrefix string
param mgmtVnetName string
param bastionVMName string
param isDiagEnabled bool
param lawWorkspaceName string


param gwSubnet string
param gwSubnetPrefix string
param gwNSG string

param ssSubnet string 
param ssSubnetPrefix string
param ssNSG string

param bastionSubnet string 
param bastionSubnetPrefix string
param bastionNSG string 

//Managment VM  parameters
param AvailabilitySetNameMgmt string
param deployerOsType string
param mgmtVmName string
param mgmtVmSize string

//StorageAccount Parameters
param sapBitsStrAccountName string = 'sapbits${uniqueString('sapbits')}'

param epochValue int = dateTimeToEpoch(dateTimeAdd(utcNow(), 'P1Y'))
param utc string = utcNow()
param mgmtKvName string = 'mgmtkvm${uniqueString(utc)}'

//--------------------------------------------------------------------------------------------------------------------------------------------------
// Resource section
//--------------------------------------------------------------------------------------------------------------------------------------------------



module sapmgt 'saps4.management.solution.bicep' = if (isManagmentGroupRequired) {
  name: 'sapmgt'
  params: {
    AvailabilitySetNameMgmt:AvailabilitySetNameMgmt
    bastionVMName:bastionVMName
    Environment:Environment
    isDiagEnabled:isDiagEnabled
    lawWorkspaceName:lawWorkspaceName
    deployerosType:deployerOsType
    sapBitsStrAccountName:sapBitsStrAccountName
    SAPSolutionName: SAPSolutionName
    virtualMachineUserName:virtualMachineUserName
    mgmtVmName:mgmtVmName
    mgmtVmSize:mgmtVmSize
    mgmtVnetAddressPrefix:mgmtVnetAddressPrefix
    mgmtVnetName:mgmtVnetName
    location: location
    epochValue:epochValue
    coreMgtRgName: coreMgtRgName
    kvName: mgmtKvName
    gwSubnet: gwSubnet
    gwSubnetPrefix: gwSubnetPrefix
    gwNSG: gwNSG    
    ssSubnet: ssSubnet
    ssSubnetPrefix: ssSubnetPrefix
    ssNSG: ssNSG
    bastionSubnet: bastionSubnet
    bastionSubnetPrefix: bastionSubnetPrefix
    bastionNSG: bastionNSG
  }
}


//--------------------------------------------------------------------------------------------------------------------------------------------------
// Parameter section SAP Application
//--------------------------------------------------------------------------------------------------------------------------------------------------

//Resource Group parameters
param SAPSolutionName string
param SAPsolRGname string = 'RG-${SAPSolutionName}-${sidLower}-${Environment}-${stackType}'

@description('Resource Tags')
param tags object = {
  Environment: Environment
  CreatedBy: 'Bicep'
  SAPSID: SAPSID
}

// VM Parameters

@description('Please provide the System Identifier')
@maxLength(3)
param SAPSID string
@description('Convert SID to lowercase')
param sidLower string = toLower(SAPSID)
@description('The stack type of the SAP system.')
@allowed([
  'ABAP'
  'JAVA'
  'ABAP+JAVA'
])
param stackType string
@description('Define the availability type for the SAP System')
@allowed([
  'HA'
  'Not HA'
])
param systemAvailability string

@description('Species the SAPS value required based on which VM are created')
param SAPSAPSType string

@description('Application VM name')
param AppVMname string = '${sidLower}-APPVM'
param AvailbilitySetNameapp string = '${sidLower}-appavset'

@description('Webdispatcher VM Name')
param WebdispVMname string = '${sidLower}-WebDisp'
param AvailbilitySetNameWebdisp string = '${sidLower}-webavset'

@description('Database VM Name')
param DBVMname string = '${sidLower}-db'
param AvailbilitySetNamedb string = '${sidLower}-dbavset'

//Storage Account Parameters
param applawWorkspaceName string
param allowBlobPublicAccess bool
param allowCrossTenantReplication bool
param allowSharedKeyAccess bool

//Network Parameters
param appSubnet string = '${Environment}${sidLower}-appsubnet'
param appAddressPrefix string
param appnetworkSecurityGroupName string = 'appnsg-${Environment}-${sidLower}'
param AutomationAccountName string = '${Environment}-${sidLower}-autacct'
param dbSubnet string = '${Environment}${sidLower}-dbsubnet'
param dbAddressPrefix string 
param dbnetworkSecurityGroupName string = 'dbnsg-${Environment}-${sidLower}'
param anfSubnet string = '${Environment}${sidLower}-anfsubnet'
param anfAddressPrefix string 


//Storage Account Parameters
param storageAccounts string = '${Environment}sapnfs${uniqueString(SAPsolRGname)}'
param defaultToOAuthAuthentication bool
param dnsEndpointType string
param FileshareSAPTransport string
param FilshareSAPSystem string
param largeFileSharesState string
param minimumTlsVersion string
//param ObjectID string
param osTypespoke string
param privateEndPointName string = 'pep-${sidLower}-${Environment}'
param publicNetworkAccess string
param requireInfrastructureEncryption bool
param skuName string
param supportsHttpsTrafficOnly bool


//Keyvault parameters
param sapKvName string = '${Environment}sapkvm${uniqueString(SAPsolRGname)}'
//param sapKvName string = 'sapkvmDev'


//Vnet Paramaters
param SAPs4vnet string = 'Vnet-${sidLower}-${Environment}'
param SAPS4VnetaddressPrefix string


//--------------------------------------------------------------------------------------------------------------------------------------------------
// Resource section SAP Application
//--------------------------------------------------------------------------------------------------------------------------------------------------

module sapsbx 'saps4hana.application.nonprod.solution.bicep' = {
  name: 'sapsbx'
  params: {
     allowBlobPublicAccess:allowBlobPublicAccess
     allowCrossTenantReplication:allowCrossTenantReplication
     allowSharedKeyAccess:allowSharedKeyAccess
     appSubnet: appSubnet
     appAddressPrefix: appAddressPrefix
     appnetworkSecurityGroupName:appnetworkSecurityGroupName
     AppVMname:AppVMname
     AutomationAccountName:AutomationAccountName
     AvailbilitySetNameapp:AvailbilitySetNameapp
     AvailbilitySetNamedb:AvailbilitySetNamedb
     AvailbilitySetNameWebdisp:AvailbilitySetNameWebdisp
     dbSubnet: dbSubnet
     dbAddressPrefix: dbAddressPrefix
     dbnetworkSecurityGroupName:dbnetworkSecurityGroupName
     DBVMname:DBVMname
     defaultToOAuthAuthentication:defaultToOAuthAuthentication
     dnsEndpointType:dnsEndpointType
     Environment:Environment
     FileshareSAPTransport:FileshareSAPTransport
     FilshareSAPSystem:FilshareSAPSystem
     isDiagEnabled:isDiagEnabled
     largeFileSharesState:largeFileSharesState
     lawWorkspaceName:applawWorkspaceName
     minimumTlsVersion:minimumTlsVersion
     osType:osTypespoke
     privateEndPointName:privateEndPointName
     publicNetworkAccess:publicNetworkAccess
     requireInfrastructureEncryption:requireInfrastructureEncryption
     sapKvName:sapKvName
     SAPs4vnet:SAPs4vnet
     SAPS4VnetaddressPrefix:SAPS4VnetaddressPrefix
     SAPSAPSType:SAPSAPSType
     SAPSID:SAPSID
     SAPsolRGname:SAPsolRGname
     SAPSolutionName:SAPSolutionName
     sidLower:sidLower
     skuName:skuName
     stackType:stackType
     storageAccounts: storageAccounts
     supportsHttpsTrafficOnly:supportsHttpsTrafficOnly
     systemAvailability:systemAvailability
     tags:tags
     WebdispVMname:WebdispVMname
     location: location
     virtualMachineUserName: virtualMachineUserName
     anfSubnet: anfSubnet
     anfAddressPrefix: anfAddressPrefix 
  }
}

//----------------------------------------------------------------------------------------
// Module call for vnet peering between Mgt network and SAP app network 
//----------------------------------------------------------------------------------------

module sapcoretosbx '../../Modules/vnetPeering.module.bicep' = if (isManagmentGroupRequired){
  scope: resourceGroup(coreMgtRgName)
  name: '${mgmtVnetName}-peering-${SAPs4vnet}'
  params: {
    localVnetName: mgmtVnetName
    remoteVnetId: sapsbx.outputs.sandboxVnetId
    remoteVnetName: SAPs4vnet
    useRemoteGateways:false
    allowForwardedTraffic:true
    allowGatewayTransit:true
    allowVirtualNetworkAccess:true
    
  }
}

module sapsbxtocore '../../Modules/vnetPeering.module.bicep' = if (isManagmentGroupRequired){
  scope: resourceGroup(SAPsolRGname)
  name: '${SAPs4vnet}-peering-${mgmtVnetName}'
  params: {
    localVnetName: SAPs4vnet
    remoteVnetId: sapmgt.outputs.coreMgtVnetId
    remoteVnetName: mgmtVnetName
    useRemoteGateways: false
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess:true
  }
 
}
