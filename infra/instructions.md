Login into Azure and set your working subscription

```
az login --tenant <tenant-id>
az account set -s "<subscription-name>"
```

Ensure you have a resource group created.

```
az deployment group create --resource-group <resource-group-name> --template-file deploy.bicep --parameters projectcode="hudua-dev-01" deployAzureOpenAI=False
```

Networking version

```
az deployment group create --resource-group <resource-group-name> --template-file deploy-network.bicep --parameters projectcode="hudua-dev-01" deployAzureOpenAI=False vnetName=vnet subnetPrivateEndpointsName=default
```
