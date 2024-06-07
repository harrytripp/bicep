// Enabling static website hosting isn't possible directly in Bicep or an ARM template,
// so this uses a deployment script to enable the feature.

@description('The location into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The name of the storage account to use for site hosting.')
param storageAccountName string = 'stor${uniqueString(resourceGroup().id)}'

@description('The storage account sku name.')
param storageSku string = 'Standard_LRS'

@description('The path to the web index document.')
param indexDocumentPath string = 'index.html'

@description('The contents of the web index document.')
param indexDocumentContents string = '<h1>Static website</h1>'

@description('The path to the web error document.')
param errorDocument404Path string = 'error.html'

@description('The contents of the web error document.')
param errorDocument404Contents string = '<h1>404 error</h1>'

// Generates endpoint name from resource group id.
var endpointName = 'endpoint-${uniqueString(resourceGroup().id)}'

// Generates CDN profile name from resource group id.
var profileName = 'cdn-${uniqueString(resourceGroup().id)}'

// Gets the web endpoint of the static website.
var storageAccountHostName = replace(replace(storageAccount.properties.primaryEndpoints.web, 'https://', ''), '/', '')

resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  // This is the Storage Account Contributor role, which is the minimum role permission we can give. See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#:~:text=17d1049b-9a84-46fb-8f53-869881c3d3ab
  name: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  // Secure the storage account
  properties: { // Secure the storage account
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    accessTier: 'Hot'
  }
  sku: {
    name: storageSku
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: 'DeploymentScript'
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(resourceGroup().id, managedIdentity.id, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'deploymentScript'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  dependsOn: [
    // To ensure we wait for the role assignment to be deployed before trying to access the storage account
    roleAssignment
  ]
  properties: {
    azPowerShellVersion: '7.0'
    scriptContent: loadTextContent('./scripts/enable-static-website.ps1')
    retentionInterval: 'PT4H' // 4 hours script retention post termination
    environmentVariables: [
      {
        name: 'ResourceGroupName'
        value: resourceGroup().name
      }
      {
        name: 'StorageAccountName'
        value: storageAccount.name
      }
      {
        name: 'IndexDocumentPath'
        value: indexDocumentPath
      }
      {
        name: 'IndexDocumentContents'
        value: indexDocumentContents
      }
      {
        name: 'ErrorDocument404Path'
        value: errorDocument404Path
      }
      {
        name: 'ErrorDocument404Contents'
        value: errorDocument404Contents
      }
    ]
  }
}

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
