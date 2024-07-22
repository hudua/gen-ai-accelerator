
param location string = resourceGroup().location
var keyVaultName = '<projectcode>-hudua-dev-kv'
var searchName = '<projectcode>-hudua-dev-ais'
var openAIName = '<projectcode>-hudua-dev-oai'
var cosmosName = '<projectcode>-hudua-dev-csdb'
var storageAccountName = '<projectcode>huduadevsa'
var appServicePlanName = '<projectcode>-hudua-dev-asp'

resource azure_key_vault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'premium'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource azure_search_service 'Microsoft.Search/searchServices@2020-08-01' = {
  name: searchName
  location: location
  sku: {
    name: 'standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource open_ai 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAIName
  location: 'canadaeast'
  kind: 'OpenAI'
  properties: {
    publicNetworkAccess: 'Enabled'
    customSubDomainName: 'aoai-${openAIName}'
  }
  sku: {
  name: 'S0'
}
}

resource cosmos_db_account 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
name: cosmosName
location: location
kind: 'GlobalDocumentDB'
  properties: {
    locations: [
      {
        locationName: location
      }
     ]
     databaseAccountOfferType: 'Standard'
     publicNetworkAccess: 'Enabled'
  }
}

resource azure_storage_account_data 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    isHnsEnabled: true
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices, Logging, Metrics'
    }
  }
}

resource azure_app_service_plan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  kind: 'Linux'
  sku: {
    tier: 'PremiumV3'
    name: 'P1v3'
    family: 'Pv3'
    capacity: 1
    size: 'P1v3'
  }
  properties: {
    reserved: true
  }
}
