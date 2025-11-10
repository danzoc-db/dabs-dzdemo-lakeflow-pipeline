# Setup Guide: GitHub Repository & CI/CD

This guide walks you through setting up the GitHub repository and CI/CD pipeline for the Databricks Asset Bundle project.

---

## 📋 **Table of Contents**

1. [Prerequisites](#prerequisites)
2. [Step 1: Create GitHub Repository](#step-1-create-github-repository)
3. [Step 2: Configure GitHub Secrets](#step-2-configure-github-secrets)
4. [Step 3: Configure Databricks Authentication](#step-3-configure-databricks-authentication)
5. [Step 4: Update Bundle Configuration](#step-4-update-bundle-configuration)
6. [Step 5: Initial Deployment](#step-5-initial-deployment)
7. [Step 6: Verify CI/CD Pipeline](#step-6-verify-cicd-pipeline)
8. [Troubleshooting](#troubleshooting)

---

## ✅ **Prerequisites**

### Required Tools
- **Git** (2.30+): `git --version`
- **Python** (3.10+): `python --version`
- **Databricks CLI**: `pip install databricks-cli`
- **GitHub Account**: With permissions to create repositories

### Databricks Requirements
- Databricks workspace (AWS, Azure, or GCP)
- Unity Catalog enabled
- Personal access token or service principal
- Permissions:
  - CREATE CATALOG / USE CATALOG
  - CREATE SCHEMA / USE SCHEMA
  - CREATE PIPELINE / MODIFY / VIEW

### Source Data
- Managed volume with source CSV files:
  - `/Volumes/<catalog>/<schema>/demo_source_data/tblComplaints/`
  - `/Volumes/<catalog>/<schema>/demo_source_data/rk_insight_hierarchy/`

---

## 🔨 **Step 1: Create GitHub Repository**

### Option A: Via GitHub UI

1. **Navigate to GitHub**
   - Go to https://github.com
   - Click **"New repository"** (or go to https://github.com/new)

2. **Repository Settings**
   - **Repository name**: `lakeflow-dab-pipeline`
   - **Description**: "Databricks Lakeflow Pipeline with Asset Bundles - Customer Complaints"
   - **Visibility**: Private (recommended for production) or Public (for demos)
   - **Initialize**: ❌ Do NOT initialize with README (we have our own files)

3. **Create Repository**
   - Click **"Create repository"**

### Option B: Via GitHub CLI

```bash
# Install GitHub CLI (if not already installed)
# macOS: brew install gh
# Windows: choco install gh
# Linux: See https://github.com/cli/cli#installation

# Authenticate
gh auth login

# Create repository
gh repo create lakeflow-dab-pipeline \
  --private \
  --description "Databricks Lakeflow Pipeline with Asset Bundles - Customer Complaints"

# Clone repository
gh repo clone <your-username>/lakeflow-dab-pipeline
```

### Push Local Project to GitHub

```bash
# Navigate to your local project
cd /path/to/lakeflow-dab-pipeline-project

# Initialize git (if not already initialized)
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: Databricks Asset Bundle for Lakeflow Pipeline"

# Add remote
git remote add origin https://github.com/<your-username>/lakeflow-dab-pipeline.git

# Push to GitHub
git branch -M main
git push -u origin main
```

---

## 🔐 **Step 2: Configure GitHub Secrets**

GitHub Actions needs secure access to your Databricks workspace. We'll store credentials as **GitHub Secrets**.

### 2.1: Generate Databricks Access Token

**Option A: Personal Access Token (for development/demo)**

1. Go to your Databricks workspace
2. Click **User Settings** (profile icon in top right)
3. Navigate to **Developer** → **Access tokens**
4. Click **"Generate new token"**
5. **Comment**: "GitHub Actions - Lakeflow Pipeline"
6. **Lifetime**: 90 days (or as per policy)
7. Click **"Generate"**
8. **Copy the token immediately** (you won't see it again!)

**Option B: Service Principal (for production)**

```bash
# Create service principal via Databricks CLI
databricks service-principals create \
  --display-name "github-actions-lakeflow-pipeline"

# Create OAuth secret
databricks service-principals create-secret \
  --service-principal-id <sp-id>

# Grant permissions
databricks permissions update \
  --resource-type clusters \
  --resource-id <cluster-id> \
  --service-principal <sp-id> \
  --permission-level CAN_MANAGE
```

### 2.2: Add Secrets to GitHub

1. **Navigate to Repository Settings**
   - Go to your repository on GitHub
   - Click **Settings** tab
   - In left sidebar, click **Secrets and variables** → **Actions**

2. **Add Secrets**
   - Click **"New repository secret"**
   
   **Secret 1: DATABRICKS_HOST**
   - Name: `DATABRICKS_HOST`
   - Value: `https://<your-workspace>.cloud.databricks.com`
   - Example: `https://adb-1234567890123456.7.azuredatabricks.net`
   - Click **"Add secret"**
   
   **Secret 2: DATABRICKS_TOKEN**
   - Name: `DATABRICKS_TOKEN`
   - Value: `<your-token-from-step-2.1>`
   - Click **"Add secret"**

3. **Verify Secrets**
   - You should see both secrets listed (values are hidden)
   - Secrets are now available to GitHub Actions workflows

### 2.3: Environment Configuration (Optional)

For better security, configure **Environments**:

1. **Create Environments**
   - Go to **Settings** → **Environments**
   - Click **"New environment"**
   - Name: `development`
   - Click **"Configure environment"**
   - (Optional) Add **Deployment protection rules**
   - Repeat for `production` environment

2. **Add Environment-Specific Secrets**
   - For each environment, add:
     - `DATABRICKS_HOST`
     - `DATABRICKS_TOKEN`
   - Production can have different credentials than development

---

## 🔧 **Step 3: Configure Databricks Authentication**

### Local Development Authentication

Set up Databricks CLI for local development:

```bash
# Option 1: Interactive configuration
databricks configure --token

# Enter when prompted:
# Databricks Host: https://<your-workspace>.cloud.databricks.com
# Token: <your-personal-access-token>

# Option 2: Profile-based configuration
databricks configure --token --profile dev
databricks configure --token --profile prod

# Verify authentication
databricks workspace ls /
```

### Authentication File Location

Credentials are stored in `~/.databrickscfg`:

```ini
[DEFAULT]
host = https://<your-workspace>.cloud.databricks.com
token = <your-token>

[dev]
host = https://<dev-workspace>.cloud.databricks.com
token = <dev-token>

[prod]
host = https://<prod-workspace>.cloud.databricks.com
token = <prod-token>
```

**⚠️ Security Note**: Never commit `.databrickscfg` to Git!

---

## ⚙️ **Step 4: Update Bundle Configuration**

### 4.1: Update `databricks.yml`

Edit the main bundle configuration:

```yaml
# databricks.yml
bundle:
  name: lakeflow_complaints_pipeline
  
workspace:
  root_path: "~/.bundle/${bundle.name}/${bundle.target}"

targets:
  dev:
    mode: development
    workspace:
      host: https://<YOUR-DEV-WORKSPACE>.cloud.databricks.com  # UPDATE THIS
    
    variables:
      catalog: dz_demos_dev              # UPDATE THIS
      schema: lakeflow_dec_pipe_r_scripts_dev
      volume_path: /Volumes/dz_demos_dev/lakeflow_dec_pipe_r_scripts/demo_source_data
    
  prod:
    mode: production
    workspace:
      host: https://<YOUR-PROD-WORKSPACE>.cloud.databricks.com  # UPDATE THIS
    
    run_as:
      service_principal_name: <YOUR-SERVICE-PRINCIPAL>  # UPDATE THIS (for prod)
    
    variables:
      catalog: dz_demos                  # UPDATE THIS
      schema: lakeflow_dec_pipe_r_scripts
      volume_path: /Volumes/dz_demos/lakeflow_dec_pipe_r_scripts/demo_source_data

include:
  - resources/*.yml
```

**What to Update:**
- ✏️ `host`: Your Databricks workspace URL
- ✏️ `catalog`: Your Unity Catalog catalog name
- ✏️ `schema`: Your target schema name
- ✏️ `volume_path`: Path to your source data volume
- ✏️ `service_principal_name`: Service principal for production (if using)

### 4.2: Update `resources/pipelines.yml`

Edit pipeline-specific configuration:

```yaml
# resources/pipelines.yml
resources:
  pipelines:
    customer_complaints_pipeline:
      name: "[${bundle.target}] Customer Complaints R Migration Pipeline"
      
      target: ${var.schema}
      catalog: ${var.catalog}
      
      # Email notifications (UPDATE THIS)
      notifications:
        - email_recipients:
            - your-email@company.com      # UPDATE THIS
            - team-email@company.com      # UPDATE THIS
          alerts:
            - on-update-failure
            - on-update-fatal-failure
      
      # Permissions (UPDATE THIS)
      permissions:
        - level: CAN_VIEW
          group_name: users               # UPDATE THIS
        - level: CAN_MANAGE
          group_name: data_engineers      # UPDATE THIS
```

**What to Update:**
- ✏️ `email_recipients`: Your notification emails
- ✏️ `group_name`: Databricks groups for permissions

### 4.3: Update SQL Files (If Needed)

If your source data paths are different, update SQL files:

```sql
-- src/pipelines/customer_complaints_bronze.sql

-- Update volume paths if different:
FROM STREAM(read_files(
  '/Volumes/YOUR_CATALOG/YOUR_SCHEMA/demo_source_data/tblComplaints/',  -- UPDATE THIS
  format => 'csv',
  header => true,
  mode => 'PERMISSIVE'
))
```

### 4.4: Commit Configuration Changes

```bash
# Add updated files
git add databricks.yml resources/pipelines.yml

# Commit changes
git commit -m "Configure bundle for workspace and Unity Catalog"

# Push to GitHub
git push origin main
```

---

## 🚀 **Step 5: Initial Deployment**

### 5.1: Validate Bundle Locally

```bash
# Validate development target
databricks bundle validate -t dev

# Expected output:
# ✓ Configuration is valid
# ✓ All resources are correctly configured
```

**Common Validation Errors:**
- ❌ `Invalid workspace host`: Check `databricks.yml` workspace URL
- ❌ `Catalog not found`: Verify catalog exists in Unity Catalog
- ❌ `File not found`: Check file paths in `resources/pipelines.yml`

### 5.2: Deploy to Development

```bash
# Deploy bundle to development
databricks bundle deploy -t dev

# Expected output:
# Uploading bundle files...
# ✓ Uploaded 3 files
# ✓ Deployed pipeline: customer_complaints_pipeline
# ✓ Pipeline ID: <pipeline-id>
```

### 5.3: Verify Deployment

```bash
# List deployed resources
databricks bundle resources -t dev

# Check pipeline status
databricks pipelines get <pipeline-id>
```

**Verify in Databricks UI:**
1. Go to **Workflows** → **Delta Live Tables**
2. Find pipeline: `[dev] Customer Complaints R Migration Pipeline`
3. Verify configuration:
   - Target catalog: `dz_demos_dev`
   - Target schema: `lakeflow_dec_pipe_r_scripts_dev`
   - Libraries: 3 SQL files

### 5.4: Run Pipeline

```bash
# Start pipeline run
databricks bundle run customer_complaints_pipeline -t dev

# Or via UI:
# 1. Go to pipeline in Databricks
# 2. Click "Start" button
# 3. Monitor progress in pipeline view
```

---

## ✅ **Step 6: Verify CI/CD Pipeline**

### 6.1: Test Development Deployment

1. **Make a Small Change**
   ```bash
   # Edit a SQL file (e.g., add a comment)
   echo "-- Test CI/CD deployment" >> src/pipelines/customer_complaints_bronze.sql
   
   # Commit and push
   git add .
   git commit -m "Test: Verify CI/CD pipeline"
   git push origin main
   ```

2. **Monitor GitHub Actions**
   - Go to GitHub repository
   - Click **Actions** tab
   - Find workflow: "Deploy to Development"
   - Monitor progress

3. **Expected Workflow Steps**
   - ✅ Checkout code
   - ✅ Setup Python
   - ✅ Install Databricks CLI
   - ✅ Validate Bundle
   - ✅ Deploy Bundle to Dev
   - ✅ Run Pipeline (Optional)

4. **Verify in Databricks**
   - Go to pipeline in Databricks UI
   - Verify update was deployed
   - Check pipeline run (if auto-run enabled)

### 6.2: Test Production Deployment

**Option A: Release-Based Deployment**

1. **Create a Release**
   ```bash
   # Tag a release
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

2. **Create Release on GitHub**
   - Go to **Releases** → **Create a new release**
   - Tag: `v1.0.0`
   - Title: "v1.0.0 - Initial Production Release"
   - Description: Release notes
   - Click **"Publish release"**

3. **Monitor Production Deployment**
   - Go to **Actions** tab
   - Find workflow: "Deploy to Production"
   - Verify manual approval (if configured)
   - Monitor deployment

**Option B: Manual Deployment**

1. **Trigger Workflow Manually**
   - Go to **Actions** → **Deploy to Production**
   - Click **"Run workflow"**
   - Enter confirmation: `deploy-to-production`
   - Click **"Run workflow"**

2. **Monitor Progress**
   - Wait for validation
   - Deployment proceeds after confirmation
   - Production deployment completes

3. **Verify in Databricks**
   - Check production pipeline: `[prod] Customer Complaints R Migration Pipeline`
   - Verify deployment tag created: `prod-deployment-YYYYMMDD-HHMMSS`

---

## 🐛 **Troubleshooting**

### Issue 1: Authentication Failed

**Error:**
```
Error: Authentication failed. Please check your credentials.
```

**Solutions:**
1. Verify GitHub secrets:
   ```bash
   # Secrets should be set:
   # DATABRICKS_HOST
   # DATABRICKS_TOKEN
   ```

2. Test token locally:
   ```bash
   export DATABRICKS_HOST="https://your-workspace.cloud.databricks.com"
   export DATABRICKS_TOKEN="your-token"
   databricks workspace ls /
   ```

3. Regenerate token if expired

### Issue 2: Bundle Validation Failed

**Error:**
```
Error: failed to load configuration: catalog 'dz_demos_dev' not found
```

**Solutions:**
1. Verify catalog exists:
   ```sql
   SHOW CATALOGS;
   ```

2. Create catalog if missing:
   ```sql
   CREATE CATALOG IF NOT EXISTS dz_demos_dev;
   CREATE SCHEMA IF NOT EXISTS dz_demos_dev.lakeflow_dec_pipe_r_scripts_dev;
   ```

3. Update `databricks.yml` with correct catalog name

### Issue 3: Pipeline Deployment Failed

**Error:**
```
Error: failed to create pipeline: permission denied
```

**Solutions:**
1. Verify permissions:
   ```sql
   SHOW GRANTS ON CATALOG dz_demos_dev;
   ```

2. Grant required permissions:
   ```sql
   GRANT CREATE ON CATALOG dz_demos_dev TO `your-user@company.com`;
   GRANT USE CATALOG ON CATALOG dz_demos_dev TO `your-user@company.com`;
   ```

3. For service principal:
   ```bash
   databricks service-principals list
   databricks permissions update --resource-type catalog ...
   ```

### Issue 4: Source Data Not Found

**Error:**
```
Error: Path does not exist: /Volumes/.../tblComplaints/
```

**Solutions:**
1. Verify volume exists:
   ```sql
   SHOW VOLUMES IN dz_demos_dev.lakeflow_dec_pipe_r_scripts;
   ```

2. Check file paths:
   ```bash
   databricks fs ls /Volumes/dz_demos_dev/.../
   ```

3. Upload source data if missing

### Issue 5: GitHub Actions Workflow Failed

**Error:**
```
Error: databricks command not found
```

**Solutions:**
1. Check workflow file `.github/workflows/deploy-dev.yml`
2. Verify Databricks CLI installation step:
   ```yaml
   - name: Install Databricks CLI
     run: pip install databricks-cli
   ```

3. Check Python version compatibility (3.10+)

---

## 📚 **Next Steps**

After successful setup:

1. **Read Deployment Guide**: See `DEPLOYMENT_GUIDE.md` for deployment workflows
2. **Configure Monitoring**: Set up pipeline monitoring and alerts
3. **Team Onboarding**: Share repository access with team members
4. **Documentation**: Update docs with team-specific configurations
5. **Production Deployment**: Plan production rollout

---

## 🎯 **Quick Reference**

### Essential Commands

```bash
# Validate bundle
databricks bundle validate -t dev

# Deploy to dev
databricks bundle deploy -t dev

# Run pipeline
databricks bundle run customer_complaints_pipeline -t dev

# Deploy to prod
databricks bundle deploy -t prod

# Check deployment status
databricks pipelines get <pipeline-id>

# View logs
databricks pipelines events <pipeline-id>
```

### GitHub Actions Triggers

| Event | Workflow | Environment |
|-------|----------|-------------|
| Push to main | deploy-dev.yml | development |
| Pull request | deploy-dev.yml (validate only) | - |
| Release published | deploy-prod.yml | production |
| Manual trigger | deploy-prod.yml | production |

---

**Need Help?**
- Review `README.md` for project overview
- Review `DEPLOYMENT_GUIDE.md` for deployment details
- Check Databricks documentation: https://docs.databricks.com/dev-tools/bundles/
- Open a GitHub issue for questions

---

**Last Updated**: January 2025  
**Version**: 1.0.0

