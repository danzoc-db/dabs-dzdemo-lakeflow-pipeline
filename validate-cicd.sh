#!/bin/bash

# CI/CD Pipeline Validation Script
# This script validates that your GitHub Actions CI/CD pipeline is properly configured

echo "🔍 Validating GitHub Actions CI/CD Pipeline Setup"
echo "=================================================="

# Check if workflow file exists
if [ -f ".github/workflows/databricks-deploy.yml" ]; then
    echo "✅ GitHub Actions workflow file found"
else
    echo "❌ GitHub Actions workflow file not found"
    exit 1
fi

# Validate YAML syntax
echo "🔍 Validating YAML syntax..."
if command -v python3 &> /dev/null; then
    python3 -c "import yaml; yaml.safe_load(open('.github/workflows/databricks-deploy.yml')); print('✅ YAML syntax is valid')"
else
    echo "⚠️  Python not found - cannot validate YAML syntax"
fi

# Check bundle validation
echo "🔍 Validating Databricks bundles..."

echo "Validating dev environment..."
if databricks bundle validate --target dev > /dev/null 2>&1; then
    echo "✅ Dev bundle validation successful"
else
    echo "❌ Dev bundle validation failed"
    echo "Run: databricks bundle validate --target dev"
fi

echo "Validating prod environment..."
if databricks bundle validate --target prod > /dev/null 2>&1; then
    echo "✅ Prod bundle validation successful"
else
    echo "❌ Prod bundle validation failed"
    echo "Run: databricks bundle validate --target prod"
fi

# Check required files
echo "🔍 Checking required files..."
required_files=(
    "databricks.yml"
    "resources/pipelines.yml"
    "resources/customer_complaints_job.yml"
    "GITHUB_ACTIONS_SETUP.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

echo ""
echo "🚀 Next Steps:"
echo "1. Push this code to GitHub (git push origin main)"
echo "2. Go to GitHub repository → Settings → Secrets and variables → Actions"
echo "3. Add required secrets (see GITHUB_ACTIONS_SETUP.md)"
echo "4. Set up GitHub environments: development and production"
echo "5. Test the pipeline by pushing a commit to main branch"
echo ""
echo "📖 Full setup guide: GITHUB_ACTIONS_SETUP.md"