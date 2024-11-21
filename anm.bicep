param acrName string
param imageName string
param containerAppName string
param managedEnvironmentName string
param targetPort int
param keyVaultName string

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: 'northeurope' // Replace with your location
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', managedEnvironmentName)
    configuration: {
      registries: [
        {
          server: '${acrName}.azurecr.io'
          username: acrName
          passwordSecretRef: 'acr-password'
        }
      ]
      ingress: {
        external: true
        targetPort: targetPort
      }
      secrets: [
        {
          name: 'acr-password'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=acr-password)'
        }
      ]
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: '${acrName}.azurecr.io/${imageName}:latest'
          resources: {
            cpu: 2
            memory: '4Gi'
          }
          env: [
            {
              name: 'ACCEPT_GENERAL_CONDITIONS'
              value: 'yes'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}
