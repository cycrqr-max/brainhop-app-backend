@description('Location')
param location string

@description('Server name')
param serverName string

@description('Database name')
param databaseName string

@description('Admin username')
param adminUser string

@secure()
@description('Admin password')
param adminPassword string

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: serverName
  location: location

  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }

  properties: {
    version: '15'

    administratorLogin: adminUser
    administratorLoginPassword: adminPassword

    storage: {
      storageSizeGB: 32
    }

    backup: {
      backupRetentionDays: 7
    }

    network: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-06-01-preview' = {
  name: databaseName
  parent: postgresServer
}

output postgresServerName string = postgresServer.name
output postgresServerFqdn string = postgresServer.properties.fullyQualifiedDomainName
output databaseName string = database.name