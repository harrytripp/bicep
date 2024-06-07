@description('The location into which the resources should be deployed.')
param location string = resourceGroup().location

// Generates endpoint name from resource group id.
var endpointName = 'endpoint-${uniqueString(resourceGroup().id)}'

// Generates CDN profile name from resource group id.
var profileName = 'cdn-${uniqueString(resourceGroup().id)}'

// Gets the web endpoint of the static website.
var storageAccountHostName = replace(replace(storageAccount.properties.primaryEndpoints.web, 'https://', ''), '/', '')


resource cdnProfile 'Microsoft.Cdn/profiles@2024-02-01' = {
  name: profileName
  location: 'global'
  tags: {
    displayName: profileName
  }
  sku: {
    name: 'Standard_Microsoft'
  }
}

resource endpoint 'Microsoft.Cdn/profiles/endpoints@2024-02-01' = {
  parent: cdnProfile
  name: endpointName
  location: 'global'
  tags: {
    displayName: endpointName
  }
  properties: {
    originHostHeader: storageAccountHostName
    isHttpAllowed: true
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    contentTypesToCompress: [
      'text/plain'
      'text/html'
      'text/css'
      'application/x-javascript'
      'text/javascript'
    ]
    isCompressionEnabled: true
    origins: [
      {
        name: 'origin1'
        properties: {
          hostName: storageAccountHostName
        }
      }
    ]
  }
}

output hostName string = endpoint.properties.hostName
output originHostHeader string = endpoint.properties.originHostHeader
output staticWebsiteUrl string = storageAccount.properties.primaryEndpoints.web
