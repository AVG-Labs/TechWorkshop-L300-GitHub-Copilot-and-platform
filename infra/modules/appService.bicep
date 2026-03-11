@description('The name of the App Service')
param name string

@description('The location of the App Service')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('The name of the App Service Plan')
param appServicePlanName string = '${name}-plan'

@description('The SKU of the App Service Plan')
param sku string = 'B1'

@description('The Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('The name of the Azure Container Registry')
param acrName string

@description('Azure AI Services endpoint')
param aiServicesEndpoint string = ''

@description('Azure AI Services resource name')
param aiServicesName string = ''

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// App Service
resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': 'web' })
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'AZURE_AI_SERVICES_ENDPOINT'
          value: aiServicesEndpoint
        }
        {
          name: 'AZURE_AI_SERVICES_NAME'
          value: aiServicesName
        }
        {
          name: 'AzureAI__Endpoint'
          value: aiServicesEndpoint
        }
        {
          name: 'AzureAI__DeploymentName'
          value: 'gpt-4o'
        }
      ]
    }
  }
}

// Get ACR reference for login server
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
}

var acrLoginServer = acr.properties.loginServer

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${name}-insights'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

// Diagnostic Settings for App Service
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'AppServiceDiagnostics'
  scope: appService
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Assign ACR Pull role to App Service managed identity
// Unconditional: the managed identity always needs pull access regardless of deployment caller
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, appService.id, 'acrpull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Get AI Services reference for role assignment
resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = if (!empty(aiServicesName)) {
  name: aiServicesName
}

// Assign Cognitive Services OpenAI User role to App Service managed identity
// Required for identity-only auth: allows calling the AI endpoint without an API key
resource aiUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(aiServicesName)) {
  name: guid(aiServices.id, appService.id, 'cognitiveservicesopenaiuser')
  scope: aiServices
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd') // Cognitive Services OpenAI User
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output id string = appService.id
output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'
output identityPrincipalId string = appService.identity.principalId
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
