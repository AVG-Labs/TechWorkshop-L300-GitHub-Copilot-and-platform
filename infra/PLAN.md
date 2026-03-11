# Azure Infrastructure Plan for ZavaStorefront
**GitHub Issue #1 Implementation**

## 📋 Overview

This document outlines the complete Azure infrastructure for deploying the ZavaStorefront web application using Azure Developer CLI (AZD) and Bicep.

## 🎯 Requirements (from GitHub Issue #1)

### Core Services
- ✅ **Linux App Service** - Container-based hosting
- ✅ **Azure Container Registry** - Docker image storage with RBAC (no passwords)
- ✅ **Application Insights** - Application monitoring and telemetry
- ✅ **Microsoft Foundry (Azure AI Services)** - GPT-4 and Phi-3 models
- ✅ **Log Analytics Workspace** - Centralized logging

### Configuration
- **Region**: `westus3` (for AI model availability)
- **Deployment Tool**: Azure Developer CLI (azd)
- **IaC**: Bicep templates
- **Resource Organization**: Single resource group
- **Authentication**: Azure RBAC (Managed Identity)

## 🏗️ Architecture

```
Resource Group: rg-{environmentName}
├── Azure Container Registry (acr-{token})
│   └── Stores Docker images for the web application
├── Log Analytics Workspace (log-{token})
│   └── Centralized logging for all services
├── Azure AI Services (ai-{token})
│   ├── GPT-4 deployment (10 capacity)
│   └── Phi-3 deployment (1 capacity)
├── App Service Plan (app-{token}-plan)
│   └── Linux B1 SKU with container support
└── App Service (app-{token})
    ├── Container: Linux Docker hosting
    ├── Managed Identity: SystemAssigned
    ├── RBAC: AcrPull role to ACR
    └── Application Insights: Monitoring
```

## 📁 File Structure

```
/
├── azure.yaml                          # AZD configuration
├── Dockerfile                          # App container definition
├── .dockerignore                       # Docker build exclusions
└── infra/
    ├── main.bicep                      # Root orchestration
    ├── main.parameters.json            # Deployment parameters
    └── modules/
        ├── acr.bicep                   # Container Registry
        ├── logAnalytics.bicep          # Log Analytics
        ├── appService.bicep            # App Service + App Insights
        └── foundry.bicep               # Azure AI Services + Models
```

## 🔧 Infrastructure Components

### 1. Azure Container Registry (ACR)
- **SKU**: Basic
- **Admin User**: Enabled (for azd)
- **Public Access**: Enabled
- **Integration**: RBAC with App Service Managed Identity

### 2. Log Analytics Workspace
- **SKU**: PerGB2018
- **Retention**: 30 days
- **Purpose**: Centralized logging for App Service and App Insights

### 3. Azure AI Services (Microsoft Foundry)
- **Type**: Multi-service (AIServices)
- **SKU**: S0
- **Deployments**:
  - **GPT-4** (version 0613, capacity 10)
  - **Phi-3** (version 1, capacity 1)
- **Authentication**: API Key (stored as app setting)
- **Managed Identity**: SystemAssigned

### 4. App Service Plan
- **SKU**: B1 (Basic)
- **OS**: Linux
- **Kind**: Linux container-based

### 5. App Service
- **Runtime**: Docker container from ACR
- **Identity**: SystemAssigned Managed Identity
- **HTTPS**: Enforced
- **TLS**: Minimum version 1.2
- **HTTP/2**: Enabled
- **Always On**: Enabled

#### Environment Variables
- `DOCKER_REGISTRY_SERVER_URL`: ACR login server
- `DOCKER_REGISTRY_SERVER_USERNAME`: ACR name
- `AZURE_AI_SERVICES_ENDPOINT`: AI Services endpoint
- `AZURE_AI_SERVICES_KEY`: AI Services access key (secure)
- `WEBSITES_ENABLE_APP_SERVICE_STORAGE`: false

### 6. Application Insights
- **Type**: Web
- **Workspace**: Connected to Log Analytics
- **Purpose**: APM, telemetry, and diagnostics

### 7. Diagnostic Settings
- **App Service Logs**:
  - HTTP logs
  - Console logs
  - Application logs
- **Metrics**: All metrics enabled

## 🔐 Security & RBAC

### Managed Identities
- **App Service**: SystemAssigned identity created automatically
- **Azure AI Services**: SystemAssigned identity for future RBAC

### Role Assignments
- **AcrPull**: App Service → ACR (allows pulling images without passwords)
- **Principal ID**: Can be assigned via parameters for additional roles

## 🚀 Deployment Process

### Prerequisites
```powershell
# Install Azure Developer CLI
winget install microsoft.azd

# Install Azure CLI
winget install microsoft.azurecli

# Install Docker (not required for AZD builds in cloud)
```

### Deployment Commands

```bash
# 1. Authenticate
azd auth login
az login

# 2. Initialize environment
azd init

# 3. Set target region (IMPORTANT: westus3 for AI models)
azd env set AZURE_LOCATION westus3

# 4. Preview infrastructure
azd provision --preview

# 5. Provision and deploy
azd up
```

### Alternative Step-by-Step
```bash
# Provision infrastructure only
azd provision

# Build and deploy application
azd deploy

# View logs
azd monitor --logs
```

## 📊 Expected Outputs

After successful deployment:

```
AZURE_LOCATION: westus3
AZURE_TENANT_ID: {your-tenant-id}
AZURE_RESOURCE_GROUP: rg-{env-name}
AZURE_CONTAINER_REGISTRY_ENDPOINT: acr{token}.azurecr.io
AZURE_CONTAINER_REGISTRY_NAME: acr{token}
AZURE_AI_SERVICES_ENDPOINT: https://ai-{token}.cognitiveservices.azure.com/
AZURE_AI_SERVICES_NAME: ai-{token}
SERVICE_WEB_NAME: app-{token}
SERVICE_WEB_URI: https://app-{token}.azurewebsites.net
```

## ✅ Validation Steps

1. **Infrastructure Validation**
   ```bash
   azd provision --preview
   ```

2. **Resource Group Check**
   ```bash
   az group show --name rg-{env-name}
   ```

3. **ACR Verification**
   ```bash
   az acr repository list --name acr{token}
   ```

4. **App Service Status**
   ```bash
   az webapp show --name app-{token} --resource-group rg-{env-name}
   ```

5. **AI Services Check**
   ```bash
   az cognitiveservices account list --resource-group rg-{env-name}
   ```

## 🧹 Cleanup

To remove all resources:
```bash
azd down
```

This will:
- Delete all Azure resources
- Purge the resource group
- Clean up local state files

## 📝 Cost Estimation

**Monthly estimates (approximate)**:
- App Service Plan (B1): ~$13
- Azure Container Registry (Basic): ~$5
- Log Analytics Workspace: Pay-as-you-go (~$2-5)
- Application Insights: First 5GB free, then pay-as-you-go
- Azure AI Services (S0): Pay-per-use
  - GPT-4: Per 1K tokens
  - Phi-3: Per 1K tokens

**Total**: ~$25-50/month (excluding AI usage)

## 🔍 Monitoring & Troubleshooting

### View Application Logs
```bash
az webapp log tail --name app-{token} --resource-group rg-{env-name}
```

### Application Insights Query
```bash
azd monitor --logs
```

### Container Logs
```bash
az webapp log show --name app-{token} --resource-group rg-{env-name}
```

## 🎓 Best Practices Implemented

- ✅ **Infrastructure as Code**: All resources defined in Bicep
- ✅ **Least Privilege**: RBAC instead of passwords
- ✅ **Managed Identities**: No credentials in code
- ✅ **Centralized Logging**: Log Analytics integration
- ✅ **Monitoring**: Application Insights for APM
- ✅ **Security**: HTTPS enforced, TLS 1.2 minimum
- ✅ **Tagging**: Environment tags for resource tracking
- ✅ **Modular Design**: Reusable Bicep modules
- ✅ **Region-Aware**: westus3 for AI model availability

## 📚 References

- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure App Service](https://learn.microsoft.com/azure/app-service/)
- [Azure AI Foundry](https://learn.microsoft.com/azure/ai-foundry/)
- [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)

---

**Status**: ✅ Infrastructure plan complete and ready for deployment
**Issue**: #1 - Provision Azure infrastructure for ZavaStorefront
**Last Updated**: March 10, 2026
