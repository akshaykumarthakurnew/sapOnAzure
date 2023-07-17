/*
Deploys N number of Linux Virtual Machines with OS disks into Availability zones specific to SAP

@parameters []

@author Akshay Kumar
@version 1.0
@date 29 June 2023
*/
param deployerMachine string
param location string
resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  name: '${deployerMachine}/customScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://akshaysapinstallable.blob.core.windows.net/sapinstalls/script.sh'
      ]
    }
    protectedSettings: {
      commandToExecute: 'bash  sudo script.sh -u "akki" -p "test123#"'
    }
  }
}





