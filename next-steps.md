# Next Steps - ZavaStorefront Azure Deployment

## Infrastructure Setup Complete! ✅

Your repository now has the standard AZD (Azure Developer CLI) structure:

```
/
├── azure.yaml              # AZD configuration file at repository root
├── Dockerfile              # Container definition for the web app
├── .dockerignore           # Docker build exclusions
├── infra/                  # Infrastructure as Code
│   ├── main.bicep          # Main orchestration template
│   ├── main.parameters.json # Parameter file
│   └── modules/
│       ├── acr.bicep       # Azure Container Registry
│       ├── logAnalytics.bicep # Log Analytics Workspace
│       └── appService.bicep   # App Service + App Insights
└── src/                    # Your application code
```

## What's Included

### Infrastructure Components
- **Azure Container Registry (ACR)**: Stores your Docker images
- **Log Analytics Workspace**: Centralized logging and monitoring
- **App Service Plan**: Linux-based hosting plan
- **App Service**: Container-based web app hosting
- **Application Insights**: APM and telemetry
- **Managed Identity**: Secure ACR integration
- **RBAC**: Automatic role assignment (AcrPull)

### Configuration
- Session-based cart storage (no database required)
- HTTPS enforcement
- Diagnostic logging enabled
- Container deployment ready

## Deploy to Azure

### Prerequisites
1. Install Azure Developer CLI: `winget install microsoft.azd`
2. Install Azure CLI: `winget install microsoft.azurecli`
3. Install Docker Desktop (for local builds)

### Deployment Steps

1. **Login to Azure**
   ```bash
   azd auth login
   az login
   ```

2. **Initialize the environment**
   ```bash
   azd init
   ```
   - Select your subscription
   - Choose a region (e.g., eastus, westus2)
   - Name your environment (e.g., dev, prod)

3. **Provision and deploy**
   ```bash
   azd up
   ```
   This single command will:
   - Create all Azure resources
   - Build the Docker image
   - Push to ACR
   - Deploy to App Service

### Alternative: Step-by-step deployment

```bash
# Provision infrastructure only
azd provision

# Build and deploy application only
azd deploy
```

## Verify Deployment

After `azd up` completes, you'll see output like:
```
SUCCESS: Your application was provisioned and deployed to Azure
You can view the resources created under the resource group rg-{env-name}

Web App: https://app-{unique-id}.azurewebsites.net
```

Visit the URL to see your deployed application!

## Monitoring

- **Application Insights**: View in Azure Portal → Resource Group → Application Insights
- **Logs**: `az webapp log tail --name <app-name> --resource-group <rg-name>`
- **Metrics**: Azure Portal → App Service → Monitoring

## Clean Up

To delete all resources:
```bash
azd down
```

## Troubleshooting

### Common Issues

1. **Docker not running**: Start Docker Desktop
2. **Authentication errors**: Run `azd auth login` and `az login`
3. **Port conflicts**: Ensure ports 80/443 are available
4. **Build failures**: Check Dockerfile paths are correct

### View Deployment Logs
```bash
azd monitor --logs
```

## Next Customizations

Consider adding:
- Azure SQL Database for persistent storage
- Azure Cache for Redis for session management
- Azure Key Vault for secrets
- Azure Front Door for CDN
- Application Gateway for WAF

## Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)

---

Ready to deploy? Run `azd up` to get started! 🚀
