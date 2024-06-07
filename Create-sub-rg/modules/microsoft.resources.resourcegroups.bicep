targetScope = 'subscription'

@description('Name of the resourceGroup.')
param resourceGroupName string

@description('The location into which the resourceGroup should be deployed.')
param location string = deployment().location

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
}
