@description('Location')
param location string

@description('Storage account name')
param name string

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location

  sku: {
    name: 'Standard_LRS'
  }

  kind: 'StorageV2'

  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storage
}

resource videos 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: 'videos'
  parent: blobService

  properties: {
    publicAccess: 'None'
  }
}

resource thumbnails 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: 'thumbnails'
  parent: blobService

  properties: {
    publicAccess: 'None'
  }
}

output storageAccountName string = storage.name
output storageAccountId string = storage.id
output blobEndpoint string = storage.properties.primaryEndpoints.blob