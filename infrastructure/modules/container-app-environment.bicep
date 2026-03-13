@description('Location')
param location string

@description('Environment name')
param name string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${name}'
  location: location

  properties: {
    sku: {
      name: 'PerGB2018'
    }

    retentionInDays: 30
  }
}

resource containerEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: name
  location: location

  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: listKeys(logAnalytics.id, logAnalytics.apiVersion).primarySharedKey
      }
    }

    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

output containerEnvironmentId string = containerEnv.id
output containerEnvironmentName string = containerEnv.name