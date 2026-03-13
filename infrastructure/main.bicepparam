using './main.bicep'

param location = 'westeurope'
param environment = 'dev'
param appName = 'brainhop-backend'
param domain = 'brainhop'
param costcenter = '10000'
param additionalTags = {}

param containerImageWithVersion = 'ghcr.io/<your-org>/brainhop-backend:latest'

param postgresAdminUser = 'brainhopadmin'
@secure()
param postgresAdminPassword = '<your-secure-password>'

param storageAccountName = 'brainhopbackendstorage'

param registry = {
  server: 'ghcr.io'
  username: 'cycrqr-max'
  passwordSecretRef: 'github-token'
}

param cpu = '0.5'
param memory = '1Gi'
param targetPort = 8080

param containerAppSecrets = [
  {
    name: 'github-token'
    keyVaultUrl: '<your-keyvault-url>/secrets/GitHubPAT'
  }
]

param containerAppEnvironmentVariables = [
  {
    name: 'ENVIRONMENT'
    value: 'dev'
  }
]