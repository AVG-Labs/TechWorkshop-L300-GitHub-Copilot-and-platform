targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment used to generate a short unique hash for resources')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Tags to apply to all resources
var tags = {
  'azd-env-name': environmentName
}

// Generate a unique token to be used in naming resources
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Define the resource group for the environment
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

// Log Analytics Workspace for monitoring
module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'log-analytics'
  scope: rg
  params: {
    name: 'log-${resourceToken}'
    location: location
    tags: tags
  }
}

// Azure Container Registry for Docker images
module acr './modules/acr.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    name: 'acr${resourceToken}'
    location: location
    tags: tags
  }
}

// Azure AI Foundry (AI Services with model deployments)
module foundry './modules/foundry.bicep' = {
  name: 'ai-foundry'
  scope: rg
  params: {
    name: 'ai-${resourceToken}'
    location: location
    tags: tags
  }
}

// App Service for hosting the web application
module appService './modules/appService.bicep' = {
  name: 'app-service'
  scope: rg
  params: {
    name: 'app-${resourceToken}'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    acrName: acr.outputs.name
    aiServicesEndpoint: foundry.outputs.endpoint
    aiServicesName: foundry.outputs.name
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.name

output AZURE_AI_SERVICES_ENDPOINT string = foundry.outputs.endpoint
output AZURE_AI_SERVICES_NAME string = foundry.outputs.name

output SERVICE_WEB_NAME string = appService.outputs.name
output SERVICE_WEB_URI string = appService.outputs.uri
