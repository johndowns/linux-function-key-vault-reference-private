param vnetName string
param location string

var vnetAddressPrefix = '10.0.0.0/16'
var applicationSubnetName = 'app'
var applicationSubnetAddressPrefix = '10.0.0.0/24'
var keyVaultSubnetName = 'key-vault'
var keyVaultSubnetAddressPrefix = '10.0.1.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: applicationSubnetName
        properties: {
          addressPrefix: applicationSubnetAddressPrefix
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: keyVaultSubnetName
        properties: {
          addressPrefix: keyVaultSubnetAddressPrefix
        }
      }
    ]
  }

  resource applicationSubnet 'subnets' existing = {
    name: applicationSubnetName
  }

  resource keyVaultSubnet 'subnets' existing = {
    name: keyVaultSubnetName
  }
}

output virtualNetworkResourceId string = vnet.id
output applicationSubnetResourceId string = vnet::applicationSubnet.id
output keyVaultSubnetResourceId string = vnet::keyVaultSubnet.id
