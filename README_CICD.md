# Databricks Bundle CI/CD with GitHub Actions

This project includes a simple CI/CD pipeline for Databricks Asset Bundles using GitHub Actions. The pipeline has two stages: **dev** and **prod** deployment.

## Workflow Overview

- **Trigger:**
  - On every push to `main`
  - Manual trigger via GitHub Actions UI
- **Stages:**
  1. **Deploy to Dev**
      - Validates and deploys the bundle to the dev environment
  2. **Deploy to Prod**
      - Runs only if dev deployment succeeds
      - Validates and deploys the bundle to the prod environment

## Requirements

### 1. Databricks CLI Authentication
- **Dev:** Requires a Databricks PAT (Personal Access Token) with access to the dev workspace
- **Prod:** Requires a Databricks PAT with access to the prod workspace and permissions for the service principal

### 2. GitHub Secrets
Set the following secrets in your GitHub repository:
- `DATABRICKS_HOST` — The Databricks workspace URL (e.g., `https://adb-xxxxxx.azuredatabricks.net`)
- `DATABRICKS_TOKEN` — PAT for dev deployment
- `DATABRICKS_TOKEN_PROD` — PAT for prod deployment (should be for the service principal or a user with prod permissions)

### 3. Bundle Structure
- The bundle must have valid `dev` and `prod` targets in `databricks.yml`
- All resource paths must be accessible to the deploying user/service principal

## How It Works

1. **Checkout code**
2. **Set up Python and Databricks CLI**
3. **Configure Databricks CLI** using secrets
4. **Validate and deploy** the bundle to dev
5. **If dev succeeds, validate and deploy** the bundle to prod

## Example Workflow File
See `.github/workflows/databricks-bundle-cicd.yml` for the full pipeline definition.

## Troubleshooting
- Ensure all secrets are set in GitHub
- Service principal must have workspace access and permissions to all referenced resources
- File paths in the bundle must be accessible to the deploying identity

---

For more details, see the [Databricks Asset Bundles documentation](https://docs.databricks.com/en/dev-tools/bundles/index.html).
