/*
Deploys a single Log Analytics workspace with diagnostics enabled. If the name parameter is not supplied a randomly generated name will be used.
Outputs the LAW ID

@parameters 
  logAnalyticsWorkspaceName: String
@author Aaron Cross
@version 1.0
@date 16th June 2021
*/
param logAnalyticsWorkspaceName string = 'LA-${uniqueString(resourceGroup().id)}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: resourceGroup().location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource logAnalyticsWorkspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: logAnalyticsWorkspace
  name: 'diagnosticSettings'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'Audit'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
  }
}

output logAnalyticsWorkspaceID string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
