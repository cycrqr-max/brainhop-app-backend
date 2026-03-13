@description('Location of the resource')
param location string

@description('Container App Environment resource ID')
param containerAppEnvironmentId string

@description('Name of the container app')
param name string

@description('Container image including tag')
param containerImageWithVersion string

@description('Port the container listens on')
param targetPort int

@description('CPU allocation')
param cpu string = '0.25'

@description('Memory allocation')
param memory string = '0.5Gi'

@description('Container registry config')
param registry object

@description('Secrets for container')
param secrets array = []

@description('Environment variables')
param environmentVariables array = []

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location

  properties: {
    environmentId: containerAppEnvironmentId

    configuration: {
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'auto'
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }

      registries: [
        registry
      ]

      secrets: secrets
    }

    template: {
      containers: [
        {
          name: name
          image: containerImageWithVersion

          resources: {
            cpu: json(cpu)
            memory: memory
          }

          env: environmentVariables
        }
      ]

      scale: {
        minReplicas: 0
        maxReplicas: 5
      }
    }
  }
}

output containerAppName string = containerApp.name
output containerAppResourceId string = containerApp.id
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn