/*
Deploys a Recovery services vault with Default Backup configuration for Storage Replication Type is set to Geo-redundant (GRS). 
Default Security settings for Soft Delete is enabled. 
Default Policys are also created.
Will also create a custom policy with the name and details specified in the rsvPolicy object e.g.
{ 
  name: 'EnginePolicy-IaasVM'
  instantRpRetentionRangeInDays: 2
  timeZone: 'UTC'
  scheduleRunTimes: ['17:00'
  ]
  dailyRetentionDurationCount: 7
  daysOfTheWeek: ['Sunday'
  ]
  weeklyRetentionDurationCount: 4
  monthlyRetentionDurationCount: 12
  monthsOfYear : ['December'
  ]
  yearlyRetentionDurationCount: 1
}

@parameters 
  rsvName: String name of the RSV
  
@author David Hole
@version 2.0
@date 14th September 2022
*/

@description('Recovery Services vault name')
param rsvName string = 'RSV-${uniqueString(resourceGroup().id)}'

@description('Location of Recovery Services vault')
param location string = resourceGroup().location

@allowed([
  'Standard'
  'RS0'
])
param sku string = 'RS0'

@description('Storage replication type for Recovery Services vault')
@allowed([
  'LocallyRedundant'
  'GeoRedundant'
  'ReadAccessGeoZoneRedundant'
  'ZoneRedundant'
])
param rsvStorageType string = 'GeoRedundant'

@description('Enable cross region restore')
param rsvEnableCrossRegionRestore bool = true

param rsvPolicy object = { 
  name: 'EnginePolicy-IaasVM'
  instantRpRetentionRangeInDays: 2
  timeZone: 'UTC'
  scheduleRunTimes: [
    '17:00'
  ]
  dailyRetentionDurationCount: 7
  daysOfTheWeek: [
    'Sunday'
  ]
  weeklyRetentionDurationCount: 4
  monthlyRetentionDurationCount: 12
  monthsOfYear : [
    'December'
  ]
  yearlyRetentionDurationCount: 1
}
param isDiagEnabled bool = true
param LAWworkspaceID string

resource rsv 'Microsoft.RecoveryServices/vaults@2021-03-01' = {
  name: rsvName
  location: location
  sku: {
    name: sku
    tier: 'Standard'
  }
  properties: {}
}

resource rsvConfig 'Microsoft.RecoveryServices/vaults/backupstorageconfig@2021-04-01' = {
  name: '${rsv.name}/VaultStorageConfig'
  properties: {
    crossRegionRestoreFlag: rsvStorageType == 'GeoRedundant' ? rsvEnableCrossRegionRestore : false
    storageType: rsvStorageType
  }
}

resource service 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(isDiagEnabled){
  name: 'setbypolicy'
  scope: rsv
  properties: {
    workspaceId: LAWworkspaceID
    logs: [
      {
        category: 'AzureBackupReport'
        enabled: true
      }
      {
        category: 'AzureSiteRecoveryJobs'
        enabled: true
      }
      {
        category: 'AzureSiteRecoveryEvents'
        enabled: true
      }
      {
        category: 'AzureSiteRecoveryReplicatedItems'
        enabled: true
      }
      {
        category: 'AzureSiteRecoveryReplicationStats'
        enabled: true
      }
      {
        category: 'AzureSiteRecoveryRecoveryPoints'
        enabled: true
      }
      {
        category: 'AzureSiteRecoveryReplicationDataUploadRate'
        enabled: true
      }
      {
        category: 'AzureSiteRecoveryProtectedDiskDataChurn'
        enabled: true
      }
      {
        category: 'CoreAzureBackup'
        enabled: true
      }
      {
        category: 'AddonAzureBackupJobs'
        enabled: true
      }
      {
        category: 'AddonAzureBackupAlerts'
        enabled: true
      }
      {
        category: 'AddonAzureBackupPolicy'
        enabled: true
      }
      {
        category: 'AddonAzureBackupStorage'
        enabled: true
      }
      {
        category: 'AddonAzureBackupProtectedInstance'
        enabled: true
      }
    ]
    metrics:[
      {
        category: 'Health'
        enabled: true
      }
    ]
  }
}

resource vaultName_policyName 'Microsoft.RecoveryServices/vaults/backupPolicies@2021-03-01' = {
  parent: rsv
  name: rsvPolicy.name
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: rsvPolicy.instantRpRetentionRangeInDays
    timeZone: rsvPolicy.timeZone
    schedulePolicy: {
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: rsvPolicy.scheduleRunTimes
      schedulePolicyType: 'SimpleSchedulePolicy'
    }
    retentionPolicy: {
      dailySchedule: {
        retentionTimes: rsvPolicy.scheduleRunTimes
        retentionDuration: {
          count: rsvPolicy.dailyRetentionDurationCount
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        
        daysOfTheWeek: rsvPolicy.daysOfTheWeek
        retentionTimes: rsvPolicy.scheduleRunTimes
        retentionDuration: {
          count: rsvPolicy.weeklyRetentionDurationCount
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Daily'
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 0
              isLast: true
            }
          ]
        }
        retentionTimes: rsvPolicy.scheduleRunTimes
        retentionDuration: {
          count: rsvPolicy.monthlyRetentionDurationCount
          durationType: 'Months'
        }
      }
      yearlySchedule: {
        retentionScheduleFormatType: 'Daily'
        monthsOfYear: rsvPolicy.monthsOfYear
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 0
              isLast: true
            }
          ]
        }
        retentionTimes: rsvPolicy.scheduleRunTimes
        retentionDuration: {
          count: rsvPolicy.yearlyRetentionDurationCount
          durationType: 'Years'
        }
      }
      retentionPolicyType: 'LongTermRetentionPolicy'
    }
  } 
}

output rsvId string = rsv.id
output policyId string = vaultName_policyName.id
