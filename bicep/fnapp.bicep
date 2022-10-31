targetScope= 'resourceGroup'

param environment string = 'dev'  /// Use prod for production
param location string = resourceGroup().location
param storageAccountSku string = 'Standard_LRS'
@description('The github PAT secret name')
param githubPATSecretName string = 'GitHubPATSecret'

var name = 'commitfile'
var logicAppName = 'logic-app-${name}-${environment}'
var minimumElasticSize = 1
var maximumElasticSize = 3
@description('Name of KeyVault to Store SaS Token')
var keyVaultName  = 'kvadoautomate${environment}'

resource logicAppStorage 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: 'st4logicapp${name}${environment}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageAccountSku
  }
  properties: {
    allowBlobPublicAccess: false
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

 /// Dedicated app plan for the service ///
 resource servicePlanLogicApp 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: 'plan-${name}-logic-app-${environment}'
  location: location
  sku: {
    tier: 'WorkflowStandard'
    name: 'WS1'
  }
  properties: {
    targetWorkerCount: minimumElasticSize
    maximumElasticWorkerCount: maximumElasticSize
    elasticScaleEnabled: true
    isSpot: false
    zoneRedundant: ((environment == 'prod') ? true : false)
  }
}

 // Create log analytics workspace
 resource logAnalyticsWorkspacelogicApp 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${name}-logicapp-loganalytics-workspace-${environment}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018' // Standard
    }
  }
}

 /// Log analytics workspace insights ///
 resource applicationInsightsLogicApp 'Microsoft.Insights/components@2020-02-02' = {
  name: 'application-insights-${name}-logic-${environment}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    Request_Source: 'rest'
    RetentionInDays: 30
    WorkspaceResourceId: logAnalyticsWorkspacelogicApp.id
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

// App service containing the workflow runtime ///
resource siteLogicApp 'Microsoft.Web/sites@2021-02-01' = {
  name: logicAppName
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~12'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${logicAppStorage.name};AccountKey=${listKeys(logicAppStorage.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${logicAppStorage.name};AccountKey=${listKeys(logicAppStorage.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: 'app-${toLower(name)}-logicservice-${toLower(environment)}a6e9'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsightsLogicApp.properties.InstrumentationKey
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsLogicApp.properties.ConnectionString
        }        
        {
          name: 'api-ado-connectionRuntimeUrl'
          value: 'https://06b137eff4fe3023.01.common.logic-uksouth.azure-apihub.net/apim/visualstudioteamservices/36e660ba523f4793801d61ef1471f773'
        }
        {
          name: 'api-ado-auth-type'
          value: 'ManagedServiceIdentity'
        }
        {
          name: 'api-ado-auth-scheme'
          value: ''
        }
        {
          name: 'WORKFLOWS_SUBSCRIPTION_ID'
          value: subscription().subscriptionId
        }
        {
          name: 'WORKFLOWS_RESOURCE_GROUP_NAME'
          value: resourceGroup().name
        }
        {
          name: 'GitHubPATSecret'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${githubPATSecretName})'
        }
      ]
      use32BitWorkerProcess: true
    }
    serverFarmId: servicePlanLogicApp.id
    clientAffinityEnabled: false
  }
}

resource kvaccess 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        applicationId: siteLogicApp.identity.principalId
        objectId: siteLogicApp.identity.principalId
        permissions: {
          secrets: ['All']
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}

