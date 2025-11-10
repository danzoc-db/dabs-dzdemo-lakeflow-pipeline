-- ============================================================================
-- GOLD LAYER: Analytics & Aggregations
-- Purpose: Create business-ready analytics tables and reports
-- Pattern: Aggregate, summarize, create reporting views
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Aggregation Type 1: GROUP BY with Summary Stats
-- R Pattern: group_by() + summarize()
-- Example: Complaint counts by category and department
-- ----------------------------------------------------------------------------
CREATE OR REFRESH LIVE TABLE gold_complaint_summary_by_department
(
  -- Expectation 4: Aggregated counts must be positive (data quality)
  CONSTRAINT positive_counts EXPECT (total_complaints > 0),
  
  -- Expectation 5: Average days should be reasonable (business rule)
  CONSTRAINT reasonable_avg_days EXPECT (avg_days_open >= 0 AND avg_days_open <= 365)
)
COMMENT "Demonstrates aggregation (R: group_by + summarize)"
AS SELECT 
  owner_department,
  age_category,
  
  -- Aggregation functions (R: n(), sum(), mean())
  COUNT(*) as total_complaints,
  COUNT(DISTINCT customer) as unique_customers,
  SUM(is_critical) as critical_count,
  
  -- Calculated percentages
  ROUND(AVG(days_open), 1) as avg_days_open,
  ROUND(SUM(is_critical) * 100.0 / COUNT(*), 1) as critical_pct

FROM LIVE.silver_complaints_with_owners
GROUP BY owner_department, age_category
ORDER BY owner_department, age_category
-- Note: All Gold tables are LIVE tables
-- Aggregations require full dataset visibility
-- GROUP BY creates summary statistics for reporting
;

-- ----------------------------------------------------------------------------
-- Aggregation Type 2: Daily Snapshot (Time Series)
-- R Pattern: group_by(date) + summarize()
-- Example: Daily complaint volumes
-- ----------------------------------------------------------------------------
CREATE OR REFRESH LIVE TABLE gold_daily_complaint_trend
COMMENT "Demonstrates time-series aggregation (R: group_by date + summarize)"
AS SELECT 
  created_date,
  created_year_month,
  
  -- Daily counts
  COUNT(*) as complaints_opened,
  COUNT(DISTINCT CompanyName) as unique_customers,
  
  -- Metrics by category
  SUM(CASE WHEN days_since_created > 60 THEN 1 ELSE 0 END) as critical_aged_count,
  ROUND(AVG(days_since_created), 1) as avg_age_days,
  
  -- Date of snapshot
  CURRENT_DATE() as snapshot_date

FROM LIVE.silver_complaint_time_metrics
GROUP BY created_date, created_year_month
ORDER BY created_date DESC
-- Note: Time-series analysis groups by date
-- Creates one row per date for trend visualization
-- Suitable for dashboards and reporting tools
;

-- ----------------------------------------------------------------------------
-- Aggregation Type 3: Top N Analysis
-- R Pattern: group_by() + summarize() + arrange() + top_n()
-- Example: Top customers by complaint volume
-- ----------------------------------------------------------------------------
CREATE OR REFRESH LIVE TABLE gold_top_customers_by_complaints
COMMENT "Demonstrates top-N analysis (R: top_n, arrange)"
AS 
WITH customer_stats AS (
  SELECT 
    customer,
    COUNT(*) as total_complaints,
    AVG(days_open) as avg_days_open,
    SUM(is_critical) as critical_complaints,
    MAX(days_open) as oldest_complaint_days
  
  FROM LIVE.silver_complaints_with_owners
  GROUP BY customer
)
SELECT 
  ROW_NUMBER() OVER (ORDER BY total_complaints DESC) as rank,
  customer,
  total_complaints,
  ROUND(avg_days_open, 1) as avg_days_open,
  critical_complaints,
  oldest_complaint_days

FROM customer_stats
ORDER BY total_complaints DESC
LIMIT 20
-- Note: LIMIT clause restricts to top 20 customers
-- ROW_NUMBER() assigns ranking
-- Useful for executive dashboards and KPI tracking
;

-- ----------------------------------------------------------------------------
-- Final Reporting Table: Combined Metrics
-- R Pattern: Multiple subqueries + summarize
-- Example: Executive dashboard view
-- ----------------------------------------------------------------------------
CREATE OR REFRESH LIVE TABLE gold_executive_dashboard
COMMENT "Final reporting view - combines multiple dimensions"
AS SELECT 
  'Overall Metrics' as metric_category,
  
  -- Volume metrics
  (SELECT COUNT(*) FROM LIVE.bronze_complaints) as total_open_complaints,
  (SELECT COUNT(DISTINCT CompanyName) FROM LIVE.bronze_complaints) as unique_customers,
  (SELECT COUNT(DISTINCT EMP_ID) FROM LIVE.bronze_employees) as total_employees,
  
  -- Quality metrics
  (SELECT COUNT(*) FROM LIVE.silver_complaints_categorized WHERE age_category = 'Critical (60+ days)') as critical_aged_complaints,
  (SELECT COUNT(*) FROM LIVE.silver_complaints_categorized WHERE age_category = 'New (0-7 days)') as new_complaints,
  
  -- Performance metrics
  (SELECT ROUND(AVG(days_open), 1) FROM LIVE.silver_complaints_categorized) as avg_age_days,
  (SELECT COUNT(DISTINCT owner_department) FROM LIVE.silver_complaints_with_owners) as departments_handling_complaints,
  
  -- Snapshot metadata
  CURRENT_TIMESTAMP() as report_generated_at
-- Note: Subqueries pull metrics from multiple tables
-- Creates single-row summary for executive reporting
-- Refreshes with each pipeline run to show latest metrics
;

-- ============================================================================
-- GOLD LAYER SUMMARY
-- ============================================================================
-- Tables Created: 4
--   - gold_complaint_summary_by_department (GROUP BY aggregation)
--   - gold_daily_complaint_trend (Time-series)
--   - gold_top_customers_by_complaints (Top-N analysis)
--   - gold_executive_dashboard (Combined metrics)
--
-- Key Characteristics:
--   ✓ Business-ready reporting tables
--   ✓ Aggregated and summarized data
--   ✓ Optimized for BI tools and dashboards
--   ✓ All tables are LIVE (aggregations require full data)
--   ✓ Data quality expectations on key metrics
-- ============================================================================

-- ============================================================================
-- OVERALL PIPELINE SUMMARY
-- ============================================================================
-- Total Tables: 11
--   Bronze: 2 (1 streaming, 1 live)
--   Silver: 5 (all live, some read from STREAM)
--   Gold: 4 (all live)
--
-- Transformation Patterns Demonstrated:
--   1. CASE WHEN (conditional logic)
--   2. String manipulation
--   3. JOIN (enrichment)
--   4. Window functions
--   5. Date calculations
--   6. GROUP BY aggregations
--   7. Time-series analysis
--   8. Top-N analysis
--
-- Key Design Decisions:
--   ✓ STREAMING for high-volume fact data (complaints)
--   ✓ LIVE for dimensions and reference data (employees)
--   ✓ LIVE for complex transformations (window functions, aggregations)
--   ✓ STREAM() reads from Bronze where possible for efficiency
--   ✓ Data quality expectations at Silver and Gold layers
-- ============================================================================

