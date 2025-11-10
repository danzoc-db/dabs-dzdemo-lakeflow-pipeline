# Customer Complaints Pipeline

This folder defines all source code for the customer complaints lakeflow declarative pipeline:

- `explorations/`: Ad-hoc notebooks used to explore the data processed by this pipeline.
- `transformations/`: All dataset definitions and transformations.
- `utilities/` (optional): Utility functions and Python modules used in this pipeline.
- `data_sources/` (optional): View definitions describing the source data for this pipeline.

## Getting Started

To get started, go to the `transformations` folder -- most of the relevant source code lives there:

* By convention, every dataset under `transformations` is in a separate file.
* Take a look at the files to get familiar with the lakeflow declarative syntax.
* If you're using the workspace UI, use `Run file` to run and preview a single transformation.
* If you're using the CLI, use `databricks bundle run customer_complaints_pipeline` to run the entire pipeline.

## Pipeline Structure

### Bronze Layer (`customer_complaints_bronze.sql`)
- Raw data ingestion from managed volumes
- Minimal transformation with audit columns
- Mix of streaming and live tables based on data characteristics

### Silver Layer (`customer_complaints_silver.sql`)
- Business logic and transformations
- Data quality expectations
- String manipulations and categorizations

### Gold Layer (`customer_complaints_gold.sql`)
- Analytics-ready aggregations
- Reporting views and summaries
- Business metrics and KPIs

For more tutorials and reference material, see https://docs.databricks.com/dlt.