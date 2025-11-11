# GitHub Actions CI/CD Setup for Databricks Asset Bundle

This guide will help you set up a complete CI/CD pipeline for your Databricks Asset Bundle using GitHub Actions.

## 🚀 Pipeline Overview

The CI/CD pipeline includes the following stages:

1. **Validate** - Validates both dev and prod bundle configurations
2. **Deploy Dev** - Deploys to development environment (triggered on main branch push)
3. **Test** - Runs optional tests against dev environment
4. **Deploy Prod** - Deploys to production environment (requires manual approval)

## 📋 Prerequisites

### 1. Databricks Workspace Setup

- ✅ Databricks workspace with Unity Catalog enabled
- ✅ Service principal created: `dz_demos_service_principal` (ID: `45d38527-d29d-4e63-8cbb-0608e7472025`)
- ✅ Catalogs configured: `dz_demos_dev` and `dz_demos`
- ✅ Workspace permissions configured for service principal

### 2. GitHub Repository Setup

- ✅ Repository: `danzoc-db/dabs-dzdemo-lakeflow-pipeline`
- ✅ Actions workflow file: `.github/workflows/databricks-deploy.yml`

## 🔐 Required GitHub Secrets

### Repository Secrets (Settings → Secrets and variables → Actions → Repository secrets)

| Secret Name | Description | Value |
|-------------|-------------|-------|
| `DATABRICKS_HOST` | Your Databricks workspace URL | `https://adb-984752964297111.11.azuredatabricks.net` |
| `DATABRICKS_TOKEN` | Personal access token for dev deployments | `dapi-xxxxxxxxxxxxx` |
| `DATABRICKS_CLIENT_ID` | Service principal application ID for prod | `45d38527-d29d-4e63-8cbb-0608e7472025` |
| `DATABRICKS_CLIENT_SECRET` | Service principal secret for prod | `your-service-principal-secret` |

## 🔧 Step-by-Step Setup

### Step 1: Create GitHub Environments

1. Go to your repository → **Settings** → **Environments**
2. Create two environments:
   - **development** (automatic deployment)
   - **production** (requires manual approval)

#### Development Environment Configuration:
- **Protection rules**: None (auto-deploy on main push)
- **Environment secrets**: Use repository secrets

#### Production Environment Configuration:
- **Protection rules**: 
  - ✅ Required reviewers (add yourself: `daniel.zoccali@databricks.com`)
  - ✅ Wait timer: 0 minutes
- **Environment secrets**: Use repository secrets

### Step 2: Generate Databricks Personal Access Token

1. Log into your Databricks workspace
2. Go to **User Settings** → **Developer** → **Access tokens**
3. Click **Generate new token**
4. **Comment**: `GitHub Actions Dev Deployment`
5. **Lifetime**: 90 days (or as per your security policy)
6. Copy the token and add it as `DATABRICKS_TOKEN` secret in GitHub

### Step 3: Create Service Principal Secret

1. In Databricks workspace, go to **Admin Settings** → **Service principals**
2. Find service principal: `dz_demos_service_principal`
3. Go to **OAuth secrets** tab
4. Generate a new client secret
5. Copy the secret and add it as `DATABRICKS_CLIENT_SECRET` in GitHub

### Step 4: Verify Service Principal Permissions

**Important**: Service principals have two different IDs:
- **Numeric ID** (`147401867297466`) - Used for `databricks service-principals get` commands
- **Application ID** (`45d38527-d29d-4e63-8cbb-0608e7472025`) - Used for authentication and grants

Run these commands to ensure proper permissions:

```bash
# Verify service principal exists (use numeric ID for get command)
databricks service-principals get "147401867297466"

# List service principals to find yours
databricks service-principals list | grep -i "dz_demos_service_principal"

# Grant catalog permissions using application ID
databricks grants update CATALOG dz_demos \
  --principal "45d38527-d29d-4e63-8cbb-0608e7472025" --privileges USE_CATALOG

# Grant schema permissions using application ID
databricks grants update SCHEMA dz_demos.lakeflow_dec_pipe_r_scripts \
  --principal "45d38527-d29d-4e63-8cbb-0608e7472025" --privileges USE_SCHEMA,CREATE_TABLE

# Verify grants on catalog
databricks grants get CATALOG dz_demos

# Verify grants on schema  
databricks grants get SCHEMA dz_demos.lakeflow_dec_pipe_r_scripts
```

## 🔄 Workflow Triggers

### Automatic Triggers:
- **Push to main branch** → Validates, deploys to dev, runs tests, awaits prod approval
- **Pull request to main** → Validates bundle configurations only

### Manual Triggers:
- **workflow_dispatch** → Can be triggered manually from GitHub Actions tab

## 🧪 Testing the Pipeline

### 1. Test Validation Only (Pull Request)
```bash
# Create a feature branch
git checkout -b feature/test-cicd
git push -u origin feature/test-cicd

# Create a pull request → Should trigger validation only
```

### 2. Test Full Pipeline (Main Branch)
```bash
# Make a small change and push to main
echo "# CI/CD Pipeline Test" >> README.md
git add README.md
git commit -m "test: Trigger CI/CD pipeline"
git push origin main
```

### 3. Monitor Pipeline Execution
1. Go to **GitHub repository** → **Actions** tab
2. Click on the running workflow
3. Monitor each job:
   - ✅ Validate Bundle
   - ✅ Deploy to Development
   - ✅ Run Tests
   - ⏳ Deploy to Production (awaiting approval)

## 📊 Pipeline Status Badges

Add this badge to your README to show pipeline status:

```markdown
[![Databricks DAB CI/CD](https://github.com/danzoc-db/dabs-dzdemo-lakeflow-pipeline/actions/workflows/databricks-deploy.yml/badge.svg)](https://github.com/danzoc-db/dabs-dzdemo-lakeflow-pipeline/actions/workflows/databricks-deploy.yml)
```

## 🔍 Troubleshooting

### Common Issues:

#### 1. Authentication Errors
```
Error: Invalid authentication credentials
```
**Solution**: Verify `DATABRICKS_TOKEN` and `DATABRICKS_CLIENT_SECRET` are correct

#### 2. Service Principal ID Errors
```
Error: invalidValue Invalid request. Id '45d38527-d29d-4e63-8cbb-0608e7472025' is invalid.
```
**Solution**: Use the numeric ID (`147401867297466`) for CLI get commands, not the application ID

#### 3. Permission Errors
```
Error: User does not have USE CATALOG on Catalog 'dz_demos'
```
**Solution**: Grant service principal proper catalog/schema permissions

#### 4. Bundle Validation Errors
```
Error: cannot create pipeline: You cannot provide cluster settings when using serverless compute
```
**Solution**: Ensure cluster configuration is only in dev target, not shared pipeline config

#### 5. File Access Errors
```
File was not found or the run_as user does not have permissions to access it
```
**Solution**: Ensure service principal has workspace access to bundle files

### Debug Commands:

```bash
# Local validation
databricks bundle validate --target dev
databricks bundle validate --target prod

# Check service principal (use numeric ID)
databricks service-principals get "147401867297466"

# List all service principals (to find the correct IDs)
databricks service-principals list | grep -i "dz_demos_service_principal"

# Check current authentication
databricks auth describe

# Test service principal authentication (replace with actual client secret)
export DATABRICKS_CLIENT_ID="45d38527-d29d-4e63-8cbb-0608e7472025"
export DATABRICKS_CLIENT_SECRET="your-client-secret"
export DATABRICKS_HOST="https://adb-984752964297111.11.azuredatabricks.net"
databricks auth describe
```

## 🏗️ Advanced Configuration

### Custom Test Stage
Add custom tests in the test job:

```yaml
- name: Run custom pipeline tests
  run: |
    # Check if pipeline exists
    databricks pipelines list --filter name=customer_complaints_r_migration_pipeline
    
    # Validate data quality
    databricks sql execute --warehouse-id ${{ secrets.WAREHOUSE_ID }} \
      --query "SELECT COUNT(*) FROM dz_demos_dev.lakeflow_dec_pipe_r_scripts.bronze_complaints"
```

### Slack Notifications
Add Slack notifications for deployment status:

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    channel: '#data-engineering'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## ✅ Checklist for Production Readiness

- [ ] GitHub secrets configured correctly
- [ ] Environment protection rules set up
- [ ] Service principal has all required permissions
- [ ] Bundle validates successfully for both targets
- [ ] Dev deployment works without errors
- [ ] Production deployment requires approval
- [ ] Pipeline monitoring and alerting configured
- [ ] Documentation updated with pipeline status

---

## 🎯 Quick Start Commands

```bash
# Test the pipeline locally first
databricks bundle validate --target dev
databricks bundle deploy --target dev
databricks bundle validate --target prod

# Push to trigger CI/CD
git add .
git commit -m "feat: Enable GitHub Actions CI/CD pipeline"
git push origin main
```

Your CI/CD pipeline is now ready! 🚀