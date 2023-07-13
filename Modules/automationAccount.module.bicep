/*
Deploys a single Automation Account with diagnostics enabled. If the name parameter is not supplied a randomly generated name will be used.

@parameters 
  LAWworkspaceID: String Existing OMS Workspace ID
  automationaccountName: String
*/
param LAWworkspaceID string
param automationaccountName string = 'AA-${uniqueString(resourceGroup().id)}'
param isDiagEnabled bool = false
resource automation_account 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  location: resourceGroup().location
  name: automationaccountName
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource service 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(isDiagEnabled){
  name: 'setbypolicy'
  scope: automation_account
  properties: {
    workspaceId: LAWworkspaceID
    logs: [
      {
        category: 'JobLogs'
        enabled: true
      }
      {
        category: 'JobStreams'
        enabled: true
      }
      {
        category: 'DscNodeStatus'
        enabled: true
      }
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics:[
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output automationAccountId string =  automation_account.id
