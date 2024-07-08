targetScope = 'managementGroup'

@description('subscriptionId for the deployment')
param subscriptionId string

@description('Name of the resourceGroup, will be created in the same location as the deployment.')
param resourceGroupName string = 'demo'

@description('Location for the deployments and the resources')
param location string = deployment().location


// deploy to the subscription and create the resourceGroup
module rg 'resources.resourcegroups.bicep' = {
  scope: subscription(subscriptionId)
  name: 'create-${resourceGroupName}'
  params: {
    resourceGroupName: resourceGroupName
    location: location
  }
}

// deploy to the resourceGroup and create the storageAccount with a Static Website
module storage 'storage.storageaccounts.bicep' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'nested-createResourceGroup-${resourceGroupName}'
  params: {
    location: location
  }
}

@description('Outputs from resources.resourcegroups.bicep')
//var cdnOriginHostHeader = storage.outputs.storageAccountHostName


// deploy to the CDN and create an Endpoint to access the Static Website
module cdn 'cdn.endpoint.bicep' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'nested-createResourceGroup-${resourceGroupName}'
}



output storageWebsiteURL string = storage.outputs.staticWebsiteUrl

@description('Outputs from resources.resourcegroups.bicep')
output testOutputOriginHostHeader string = storage.outputs.storageAccountHostName
