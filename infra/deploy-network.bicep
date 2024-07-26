param projectcode string
param location string = resourceGroup().location
param deployAzureOpenAI bool = true
param vnetName string
param subnetPrivateEndpointsName string

var projectcodenodashes = replace(projectcode, '-', '')

var keyVaultName = '${projectcode}-kv'
var searchName = '${projectcode}-ais'
var openAIName = '${projectcode}-oai'
var docIntelligenceName = '${projectcode}-aidoc'
var cosmosName = '${projectcode}-csdb'
var storageAccountName = '${projectcodenodashes}sa'
var appServicePlanName = '${projectcode}-asp'
var appServiceName = '${projectcode}-as'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing  = {
  name: vnetName
}

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
      defaultAction: 'Deny'
    }
  }
}

resource azure_key_vault_pe 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${azure_key_vault.name}-pe'
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/${subnetPrivateEndpointsName}'
    }
    privateLinkServiceConnections: [
      {
        name: 'MyConnection'
        properties: {
          privateLinkServiceId: azure_key_vault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
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
  properties: {
    publicNetworkAccess: 'disabled'
  }
}

resource azure_search_service_pe 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${azure_search_service.name}-endpoint'
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/${subnetPrivateEndpointsName}'
    }
    privateLinkServiceConnections: [
      {
        name: 'MyConnection'
        properties: {
          privateLinkServiceId: azure_search_service.id
          groupIds: [
            'searchService'
          ]
        }
      }
    ]
  }
}

resource open_ai 'Microsoft.CognitiveServices/accounts@2023-05-01' = if (deployAzureOpenAI) {
  name: openAIName
  location: 'canadaeast'
  kind: 'OpenAI'
  properties: {
    publicNetworkAccess: 'Disabled'
    customSubDomainName: 'aoai-${openAIName}'
  }
  sku: {
    name: 'S0'
  }
}

resource azure_openai_pe 'Microsoft.Network/privateEndpoints@2021-08-01' = if (deployAzureOpenAI) {
  name: '${open_ai.name}-endpoint'
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/${subnetPrivateEndpointsName}'
    }
    privateLinkServiceConnections: [
      {
        name: 'MyConnection'
        properties: {
          privateLinkServiceId: open_ai.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

resource doc_intelligence 'Microsoft.CognitiveServices/accounts@2023-05-01' = if (deployAzureOpenAI) {
  name: docIntelligenceName
  location: location
  kind: 'FormRecognizer'
  properties: {
    publicNetworkAccess: 'Disabled'
  }
  sku: {
    name: 'S0'
  }
}

resource doc_intelligence_pe 'Microsoft.Network/privateEndpoints@2021-08-01' = if (deployAzureOpenAI) {
  name: '${doc_intelligence.name}-endpoint'
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/${subnetPrivateEndpointsName}'
    }
    privateLinkServiceConnections: [
      {
        name: 'MyConnection'
        properties: {
          privateLinkServiceId: doc_intelligence.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
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
     publicNetworkAccess: 'Disabled'
  }
}

resource azure_cosmos_db_pe 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${cosmos_db_account.name}-endpoint'
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/${subnetPrivateEndpointsName}'
    }
    privateLinkServiceConnections: [
      {
        name: 'MyConnection'
        properties: {
          privateLinkServiceId: cosmos_db_account.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
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
      defaultAction: 'Deny'
      bypass: 'AzureServices, Logging, Metrics'
    }
  }
}

resource azure_storage_account_data_blob_pe 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  location: location
  name: '${azure_storage_account_data.name}-blob-endpoint'
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/${subnetPrivateEndpointsName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${azure_storage_account_data.name}-blob-endpoint'
        properties: {
          privateLinkServiceId: azure_storage_account_data.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
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
    publicNetworkAccess: 'Disabled'
  }
}

resource app_services_website_pe 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${app_services_website.name}-endpoint'
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/${subnetPrivateEndpointsName}'
    }
    privateLinkServiceConnections: [
      {
        name: 'MyConnection'
        properties: {
          privateLinkServiceId: app_services_website.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}
    
