// Params and Variables
@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('Prefix to use for VM names')
param vmNamePrefix string = 'BackendVM'

// Environment
param location string = 'southafrica'

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'doogle-dev-southafrica-storage'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}
