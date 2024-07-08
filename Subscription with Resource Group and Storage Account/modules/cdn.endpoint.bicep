
var endpointName = 'endpoint-${uniqueString(resourceGroup().id)}'
var profileName = 'cdn-${uniqueString(resourceGroup().id)}'

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
    originHostHeader: 'demoOriginHostHeader' //storageAccountHostName
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
          hostName: 'demoOriginHostHeader' //storageAccountHostName
        }
      }
    ]
  }
}

output hostName string = endpoint.properties.hostName
output originHostHeader string = endpoint.properties.originHostHeader
