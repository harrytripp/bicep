targetScope = 'managementGroup'

@description('Provide the full resource ID of billing scope to use for subscription creation.')
param billingScope string

@description('Alias to assign to the subscription')
param subscriptionAlias string

@description('Display name for the subscription')
param subscriptionDisplayName string

@description('Workload type for the subscription')
param subscriptionWorkload string

resource alias 'Microsoft.Subscription/aliases@2021-10-01' = {
  scope: tenant()
  name: subscriptionAlias
  properties: {
    workload: subscriptionWorkload
    displayName: subscriptionDisplayName
    billingScope: billingScope
  }
}

output subscriptionId string = alias.properties.subscriptionId
