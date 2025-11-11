# Lakeflow Complaints Pipeline

[![Databricks DAB CI/CD](https://github.com/danzoc-db/dabs-dzdemo-lakeflow-pipeline/actions/workflows/databricks-deploy.yml/badge.svg)](https://github.com/danzoc-db/dabs-dzdemo-lakeflow-pipeline/actions/workflows/databricks-deploy.yml)
[![Bundle Validation](https://img.shields.io/badge/bundle-validated-brightgreen)](https://github.com/danzoc-db/dabs-dzdemo-lakeflow-pipeline)
[![Environment](https://img.shields.io/badge/environments-dev%20%7C%20prod-blue)](https://github.com/danzoc-db/dabs-dzdemo-lakeflow-pipeline)

This project demonstrates a **Databricks Asset Bundle** with a **Lakeflow Declarative Pipeline** for analyzing customer complaints data. It showcases the migration from R-style data processing to Databricks' modern lakehouse patterns with **full CI/CD automation**.

## 🎯 **Demo Overview**

This bundle includes:
- **Lakeflow Declarative Pipeline** with Bronze-Silver-Gold architecture
- **Daily scheduled job** with email notifications on failure
- **Mixed streaming and live tables** based on data characteristics  
- **SQL transformations** equivalent to common R operations
- **Production-ready Asset Bundle** configuration

## 📊 **Pipeline Architecture**

```
📁 Source Data (Managed Volumes)
    ├── tblComplaints/ → 🥉 BRONZE (Streaming)
    └── rk_insight_hierarchy/ → 🥉 BRONZE (Live)
                ↓
        🥈 SILVER LAYER (Transformations)
                ↓  
        🥇 GOLD LAYER (Analytics)
```

### Data Processing Layers

#### 🥉 **Bronze** (`transformations/customer_complaints_bronze.sql`)
- Raw data ingestion with minimal transformation
- `bronze_complaints` (STREAMING) - 100 complaint records
- `bronze_employees` (LIVE) - 25 employee records
- Audit columns for lineage tracking

#### 🥈 **Silver** (`transformations/customer_complaints_silver.sql`)  
- Business logic and data quality rules
- Age categorization with CASE WHEN statements
- String manipulation and normalization
- Data quality expectations

#### 🥇 **Gold** (`transformations/customer_complaints_gold.sql`)
- Analytics-ready aggregations
- Department performance summaries
- Daily trend analysis
- Business metrics and KPIs

## � **CI/CD Pipeline**

This project includes a complete **GitHub Actions CI/CD pipeline** with:

### Pipeline Stages:
1. **Validate** - Bundle validation for both dev and prod environments
2. **Deploy Dev** - Automatic deployment to development (serverless disabled)
3. **Test** - Optional pipeline testing and validation
4. **Deploy Prod** - Manual approval required for production (serverless enabled)

### Authentication:
- **Development**: Personal access token
- **Production**: Service principal (`dz_demos_service_principal`)

### Setup Guide:
📖 **[Complete CI/CD Setup Instructions](GITHUB_ACTIONS_SETUP.md)**

## �🚀 **Getting Started**

### Prerequisites
- Databricks CLI installed and configured
- Access to a Databricks workspace with Unity Catalog
- Appropriate permissions for deploying bundles

### Deployment Steps

1. **Configure your workspace**:
   ```yaml
   # Edit databricks.yml
   workspace:
     host: https://your-workspace.cloud.databricks.com
   ```

2. **Deploy the bundle**:
   ```bash
   # Development deployment
   databricks bundle deploy --target dev
   
   # Production deployment  
   databricks bundle deploy --target prod
   ```

3. **Run the pipeline**:
   ```bash
   # Manual pipeline execution
   databricks bundle run customer_complaints_pipeline
   
   # Run the scheduled job
   databricks bundle run customer_complaints_job
   ```

## 📁 **Project Structure**

```
lakeflow-dab-pipeline-project/
├── databricks.yml                    # Bundle configuration
├── resources/
│   ├── pipelines.yml                # Pipeline definition  
│   └── customer_complaints_job.yml  # Daily job scheduler
└── src/pipelines/
    ├── transformations/             # SQL transformation files
    │   ├── customer_complaints_bronze.sql
    │   ├── customer_complaints_silver.sql  
    │   └── customer_complaints_gold.sql
    ├── explorations/               # Ad-hoc analysis notebooks
    └── README.md                   # Pipeline documentation
```

## ⚙️ **Configuration**

### Bundle Variables
- `catalog`: Unity Catalog catalog name (default: `dz_demos`)
- `schema`: Target schema (dev uses user name, prod uses fixed name)  
- `volume_path`: Source data location in managed volumes

### Job Features
- **Daily schedule**: Runs every 24 hours
- **Email notifications**: Alerts `daniel.zoccali@databricks.com` on failure
- **Timeout**: 4-hour maximum runtime
- **Single concurrency**: One job run at a time

### Environment Configuration
- **Dev**: User-specific schema, paused schedules, development mode
- **Prod**: Fixed schema, active schedules, production mode with permissions

## 🔧 **Customization**

To adapt this for your own use case:

1. **Update data sources** in bronze layer SQL files
2. **Modify transformations** in silver and gold layers  
3. **Configure email notifications** in `customer_complaints_job.yml`
4. **Adjust scheduling** frequency as needed
5. **Update workspace hosts** and catalog/schema names

## 📚 **Documentation**

- See `SETUP_GUIDE.md` for detailed setup instructions
- See `src/pipelines/README.md` for pipeline-specific documentation
- Explore `src/pipelines/explorations/` for data analysis examples

## 🎓 **Learning Resources**

This demo showcases:
- [Databricks Asset Bundles](https://docs.databricks.com/dev-tools/bundles/)
- [Lakeflow Declarative Pipelines](https://docs.databricks.com/delta-live-tables/) 
- [Databricks Workflows](https://docs.databricks.com/workflows/)
- [Unity Catalog](https://docs.databricks.com/data-governance/unity-catalog/)

---
**Contact**: daniel.zoccali@databricks.com