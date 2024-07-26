param projectcode string
param location string = resourceGroup().location
param deployAzureOpenAI bool = true

var projectCodeNoDashes = replace(projectcode, '-', '')

var keyVaultName = '${projectcode}-kv'
var searchName = '${projectcode}-ais'
var openAIName = '${projectcode}-oai'
var cosmosName = '${projectcode}-csdb'
var storageAccountName = '${projectCodeNoDashes}sa'
var appServicePlanName = '${projectcode}-asp'
var appServiceName = '${projectcode}-as'

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

resource open_ai 'Microsoft.CognitiveServices/accounts@2023-05-01' = if (deployAzureOpenAI) {
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

resource app_services_website 'Microsoft.Web/sites@2020-06-01' = {
  name: appServiceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: azure_app_service_plan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|sampleappaoaichatgpt.azurecr.io/sample-app-aoai-chatgpt:latest'
    }
  }
}
    
