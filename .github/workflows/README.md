# GitHub Actions Deployment Setup

The `deploy.yml` workflow builds the .NET app as a Docker container, pushes it to Azure Container Registry, and deploys it to App Service on every push to `main`.

## Required GitHub Secrets

| Secret | How to get it |
|--------|--------------|
| `AZURE_CREDENTIALS` | Output of the `az ad sp create-for-rbac` command below |

### Create the service principal

```bash
az ad sp create-for-rbac \
  --name "zava-storefront-github" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-l300-dev \
  --json-auth
```

Copy the full JSON output and save it as the `AZURE_CREDENTIALS` secret in **GitHub → Settings → Secrets and variables → Actions → New repository secret**.

The service principal also needs the **AcrPush** role to push images:

```bash
az role assignment create \
  --assignee <SERVICE_PRINCIPAL_CLIENT_ID> \
  --role AcrPush \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-l300-dev/providers/Microsoft.ContainerRegistry/registries/<ACR_NAME>
```

## Required GitHub Variables

| Variable | Value |
|----------|-------|
| `ACR_NAME` | Your ACR name, e.g. `acru3n3l76uekdnk` |
| `APP_SERVICE_NAME` | Your App Service name, e.g. `app-u3n3l76uekdnk` |

Add these in **GitHub → Settings → Secrets and variables → Actions → Variables tab → New repository variable**.

> **Tip:** Find both values in the Azure Portal under resource group `rg-l300-dev`, or from the `azd` output after provisioning.
