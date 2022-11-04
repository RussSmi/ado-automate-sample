targetScope= 'resourceGroup'
param location string = resourceGroup().location
param connName string = 'visualstudioteamservices'

var resourceType  = 'Microsoft.Web/locations/managedApis'

resource devopsconn 'Microsoft.Web/connections@2016-06-01' = {
  name: connName
  location: location
  kind: 'V2'
  properties: {
    api: {
      brandColor: 'string'
      description: 'Azure DevOps provides services for teams to share code, track work, and ship software - for any language, all in a single package. It\'s the perfect complement to your IDE.'
      displayName: 'Azure DevOps'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1588/1.0.1588.2938/vsts/icon.png'
      name: connName
      type: resourceType
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/uksouth/managedApis/${connName}'
    }
  }
}

var validityTimeSpan ={
  validityTimeSpan:'30'
}

var key = devopsconn.listConnectionKeys('2018-07-01-preview',validityTimeSpan).connectionKey
output apiKey string = key

var url = devopsconn.properties.connectionRuntimeUrl
output connRuntimeUrl string = any(url)


