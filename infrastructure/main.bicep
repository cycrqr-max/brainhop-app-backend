targetScope = 'resourceGroup'

@description('Location of resources')
param location string = 'westeurope'

@description('Environment name (dev/test/prod)')
param environment string = 'dev'

@description('Application name (no spaces/special chars)')
param appName string = 'brainhop-backend'

@description('Domain / project prefix')
param domain string = 'brainhop'

@description('Cost center for tagging')
param costcenter string = '10000'

@description('Additional tags')
param additionalTags object = {}

@description('Container image to deploy')
param containerImageWithVersion string

@description('Postgres admin username')
param postgresAdminUser string

@secure()
@description('Postgres admin password')
param postgresAdminPassword string

@description('Storage account name')
param storageAccountName string

@description('Container registry configuration')
param registry object

@description('CPU for container app')
param cpu string = '0.5'

@description('Memory for container app')
param memory string = '1Gi'

@description('Port container app listens on')
param targetPort int = 8080

@description('Secrets to pass to container app')
param containerAppSecrets array = []

@description('Environment variables for container app')
param containerAppEnvironmentVariables array = []

// Storage account
module storage 'modules/storage-account.bicep' = {
  name: 'storage-${appName}-${environment}'
  params: {
    location: location
    name: storageAccountName
  }
}

// PostgreSQL database
var postgresServerName = '${appName}-pg-${environment}'
module database 'modules/database-postgres.bicep' = {
  name: 'db-${appName}-${environment}'
  params: {
    location: location
    serverName: postgresServerName
    databaseName: '${appName}-${environment}'
    adminUser: postgresAdminUser
    adminPassword: postgresAdminPassword
  }
}

// Container App Environment
var containerEnvName = '${appName}-env-${environment}'
module containerAppEnv 'modules/container-app-environment.bicep' = {
  name: 'container-env-${appName}-${environment}'
  params: {
    location: location
    name: containerEnvName
  }
}

// Container App (backend)
var containerAppName = '${appName}-ca-${environment}'
module containerApp 'modules/container-app.bicep' = {
  name: 'container-${appName}-${environment}'
  params: {
    location: location
    containerAppEnvironmentId: containerAppEnv.outputs.containerEnvironmentId
    name: containerAppName
    containerImageWithVersion: containerImageWithVersion
    targetPort: targetPort
    cpu: cpu
    memory: memory
    registry: registry
    secrets: containerAppSecrets
    environmentVariables: concat(
      containerAppEnvironmentVariables,
      [
        {
          name: 'DATABASE_URL'
          value: 'postgresql://${postgresAdminUser}:${postgresAdminPassword}@${database.outputs.postgresServerFqdn}:5432/${database.outputs.databaseName}'
        },
        {
          name: 'STORAGE_ACCOUNT_NAME'
          value: storage.outputs.storageAccountName
        },
        {
          name: 'STORAGE_BLOB_ENDPOINT'
          value: storage.outputs.blobEndpoint
        }
      ]
    )
  }
}

output containerAppFqdn string = containerApp.outputs.containerAppFqdn
output storageAccountName string = storage.outputs.storageAccountName
output postgresFqdn string = database.outputs.postgresServerFqdn
output postgresDatabase string = database.outputs.databaseName