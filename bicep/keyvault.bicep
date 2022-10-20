targetScope= 'resourceGroup'

@description('The location into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The Tenant Id that should be used throughout the deployment.')
param tenantId string = subscription().tenantId

@description('Name of KeyVault to Store SaS Token')
param keyVaultName string = 'kvadoautomate'

@description('A place holder secret for the PAT token')
@secure()
param githubPAT string = ''

@description('The github PAT secret name')
param githubPATSecretName string = 'GitHubPATSecret'

@description('Object Id to assign to kv policy, this can be got by running az ad user show --id <your email> --query id')
param userObjId string

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  
  location: location
  tags: {
    displayName: keyVaultName
  }
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    tenantId: tenantId
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: userObjId
        permissions: {
          keys: [
            'get'
          ]
          secrets: [
            'list'
            'get'
            'set'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource githubPATToken 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = { 
  parent: keyVault
  name: githubPATSecretName
  properties: {
    value: githubPAT
  }
}
