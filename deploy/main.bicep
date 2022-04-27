param location string = resourceGroup().location
param appName string = uniqueString(resourceGroup().id)
param storageAccountName string = 'fn${uniqueString(resourceGroup().id)}'
param keyVaultName string = 'kv${uniqueString(resourceGroup().id)}'
param secretName string = 'MySecret'
param secretValue string = 'MySecretValue'

var vnetName = 'my-vnet'
var appServicePlanName = 'MyPlan'
var appServicePlanSkuName = 'EP1'
var storageAccountSkuName = 'Standard_LRS'

resource applicationManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'my-managed-identity'
  location: location
}

module keyVault 'modules/key-vault.bicep' = {
  name: 'key-vault'
  params: {
    keyVaultName: keyVaultName
    location: location
    roleAssignmentPrincipalObjectId: functionApp.identity.principalId
    secretName: secretName
    secretValue: secretValue
    virtualNetworkResourceId: vnet.outputs.virtualNetworkResourceId
    subnetResourceId: vnet.outputs.keyVaultSubnetResourceId
  }
}

module vnet 'modules/vnet.bicep' = {
  name: 'vnet'
  params: {
    vnetName: vnetName
    location: location
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
  }
  kind: 'elastic'
  properties: {
    reserved: true
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSkuName
  }
  kind: 'StorageV2'
}

resource functionApp 'Microsoft.Web/sites@2021-01-01' = {
  name: appName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: vnet.outputs.applicationSubnetResourceId
    httpsOnly: true
    siteConfig: {
      vnetRouteAllEnabled: true
      http20Enabled: true

      appSettings: [
        {
          name: 'SampleKeyVaultSecret'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${secretName})'
        }

        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix= ${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value};'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: appName
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~12'
        }
      ]
    }
  }
}
