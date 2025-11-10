-- ============================================================================
-- SILVER LAYER: Transformations & Business Logic
-- Purpose: Apply transformations, enrich data, implement business rules
-- Pattern: Read from Bronze, transform, validate with expectations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Transformation Type 1: CASE WHEN (Conditional Logic)
-- R Pattern: if/else or case_when()
-- Example: Categorize complaints by age
-- ----------------------------------------------------------------------------
CREATE OR REFRESH LIVE TABLE silver_complaints_categorized
(
  -- Expectation 1: Age category must exist (business logic)
  CONSTRAINT valid_category EXPECT (age_category IS NOT NULL),
  
  -- Expectation 2: Days open must be non-negative (data quality)
  CONSTRAINT non_negative_days EXPECT (days_open >= 0)
)
COMMENT "Demonstrates CASE WHEN transformation (R: if/else, case_when)"
AS SELECT 
  TaskListItemID,
  CompanyName,
  TaskListItemCreated,
  AssignedUserName,  -- Needed for JOIN in next layer
  
  -- Calculate days old
  DATEDIFF(CURRENT_DATE(), CAST(TaskListItemCreated AS DATE)) as days_open,
  
  -- CASE WHEN: Categorize by age (replaces R if/else logic)
  CASE
    WHEN DATEDIFF(CURRENT_DATE(), CAST(TaskListItemCreated AS DATE)) <= 7 THEN 'New (0-7 days)'
    WHEN DATEDIFF(CURRENT_DATE(), CAST(TaskListItemCreated AS DATE)) <= 30 THEN 'Active (8-30 days)'
    WHEN DATEDIFF(CURRENT_DATE(), CAST(TaskListItemCreated AS DATE)) <= 60 THEN 'Aging (31-60 days)'
    ELSE 'Critical (60+ days)'
  END AS age_category,
  
  -- Simple flag (replaces R boolean logic)
  CASE 
    WHEN DATEDIFF(CURRENT_DATE(), CAST(TaskListItemCreated AS DATE)) > 60 
    THEN 1 ELSE 0 
  END AS is_critical

FROM LIVE.bronze_complaints
-- Note: LIVE tables cannot use STREAM() - they read from the table directly
-- Bronze is a STREAMING table, but Silver LIVE table does batch processing
;

-- ----------------------------------------------------------------------------
-- Transformation Type 2: String Manipulation
-- R Pattern: substr(), gsub(), paste()
-- Example: Extract email domain, clean names
-- ----------------------------------------------------------------------------
CREATE OR REFRESH LIVE TABLE silver_employees_enriched
(
  -- Expectation 3: Username extracted successfully (not empty)
  CONSTRAINT valid_username EXPECT (username IS NOT NULL AND username != '')
)
COMMENT "Demonstrates string functions (R: substr, gsub, paste)"
AS SELECT 
  EMP_ID,
  EMP_SORT_NAME,
  EMP_EMAIL_ADR,
  
  -- Extract username from email (R: substr, strsplit)
  SUBSTRING(EMP_EMAIL_ADR, 1, INSTR(EMP_EMAIL_ADR, '@') - 1) as username,
  
  -- Extract domain from email
  SUBSTRING(EMP_EMAIL_ADR, INSTR(EMP_EMAIL_ADR, '@') + 1) as email_domain,
  
  -- Concatenate fields (R: paste)
  CONCAT(EMP_SORT_NAME, ' (', EMP_CLASS_7, ')') as display_name,
  
  -- Clean/standardize (R: toupper, tolower)
  UPPER(EMP_CLASS_7) as department_standardized

FROM LIVE.bronze_employees
-- Note: No STREAM() - this is reading from a LIVE table
-- Reference data is small, full refresh is acceptable
;

-- ----------------------------------------------------------------------------
-- Transformation Type 3: JOIN (Enrichment)
-- R Pattern: merge() or left_join()
-- Example: Add employee details to complaints
-- ----------------------------------------------------------------------------
CREATE OR REFRESH LIVE TABLE silver_complaints_with_owners
COMMENT "Demonstrates JOIN/merge (R: merge, left_join)"
AS SELECT 
  -- Complaint fields
  c.TaskListItemID as complaint_id,
  c.CompanyName as customer,
  c.age_category,
  c.days_open,
  c.is_critical,
  
  -- Employee fields from JOIN (COALESCE to handle unmatched)
  COALESCE(e.EMP_SORT_NAME, 'Unassigned') as owner_name,
  COALESCE(e.department_standardized, 'UNASSIGNED') as owner_department,
  
  -- Derived field using both tables
  CONCAT(c.CompanyName, ' - Assigned to ', COALESCE(e.EMP_SORT_NAME, 'Unassigned')) as full_description

FROM LIVE.silver_complaints_categorized c
LEFT JOIN LIVE.silver_employees_enriched e
  ON SUBSTRING(c.AssignedUserName, 1, INSTR(c.AssignedUserName, '@') - 1) = e.username
-- Note: LEFT JOIN preserves all complaints even if no employee match
-- COALESCE handles NULLs from unmatched JOINs
;

-- ----------------------------------------------------------------------------
-- Transformation Type 4: Window Functions (Ranking/Analytics)
-- R Pattern: group_by() + rank(), row_number()
-- Example: Find most recent complaint per customer
-- ----------------------------------------------------------------------------
CREATE OR REFRESH LIVE TABLE silver_latest_complaint_per_customer
COMMENT "Demonstrates window functions (R: group_by + rank, row_number)"
AS
WITH ranked_complaints AS (
  SELECT 
    customer,
    complaint_id,
    days_open,
    age_category,
    owner_name,
    
    -- Window function: Rank by days_open within each customer
    -- R equivalent: group_by(customer) %>% mutate(rank = row_number(desc(days_open)))
    ROW_NUMBER() OVER (
      PARTITION BY customer 
      ORDER BY days_open DESC
    ) as recency_rank
  
  FROM LIVE.silver_complaints_with_owners
)
SELECT 
  customer,
  complaint_id as latest_complaint_id,
  days_open as days_since_oldest_complaint,
  age_category,
  owner_name
FROM ranked_complaints
WHERE recency_rank = 1  -- Only the most recent complaint per customer
-- Note: Window functions (ROW_NUMBER, RANK, etc.) require LIVE tables
-- Cannot be used in STREAMING tables
;

-- ----------------------------------------------------------------------------
-- Transformation Type 5: Date/Time Calculations
-- R Pattern: lubridate functions (ymd, dmy, interval)
-- Example: Calculate business metrics with dates
-- ----------------------------------------------------------------------------
CREATE OR REFRESH LIVE TABLE silver_complaint_time_metrics
COMMENT "Demonstrates date calculations (R: lubridate, difftime)"
AS SELECT 
  TaskListItemID,
  CompanyName,
  
  -- Parse dates (R: as.Date, ymd)
  CAST(TaskListItemCreated AS DATE) as created_date,
  CAST(LastUpdateDateTime AS DATE) as last_update_date,
  
  -- Date arithmetic (R: difftime, interval)
  DATEDIFF(CURRENT_DATE(), CAST(TaskListItemCreated AS DATE)) as days_since_created,
  DATEDIFF(CAST(LastUpdateDateTime AS DATE), CAST(TaskListItemCreated AS DATE)) as days_to_last_update,
  
  -- Date parts (R: year(), month(), weekday())
  YEAR(CAST(TaskListItemCreated AS DATE)) as created_year,
  MONTH(CAST(TaskListItemCreated AS DATE)) as created_month,
  DAYOFWEEK(CAST(TaskListItemCreated AS DATE)) as created_day_of_week,
  
  -- Date formatting (R: format())
  DATE_FORMAT(CAST(TaskListItemCreated AS DATE), 'yyyy-MM') as created_year_month

FROM LIVE.bronze_complaints
-- Note: LIVE tables read from tables directly (no STREAM wrapper)
-- Even though bronze_complaints is STREAMING, this LIVE table processes it in batch
;

-- ============================================================================
-- SILVER LAYER SUMMARY
-- ============================================================================
-- Tables Created: 5
--   - silver_complaints_categorized (CASE WHEN logic)
--   - silver_employees_enriched (String manipulation)
--   - silver_complaints_with_owners (JOIN enrichment)
--   - silver_latest_complaint_per_customer (Window functions)
--   - silver_complaint_time_metrics (Date calculations)
--
-- Key Characteristics:
--   ✓ Business logic and transformations applied
--   ✓ Data quality expectations enforced
--   ✓ Enrichment via JOINs
--   ✓ All tables are LIVE (for complex SQL support)
--   ✓ Read directly from Bronze (no STREAM wrapper for LIVE tables)
--   ✓ Note: LIVE tables cannot use STREAM() - only STREAMING tables can
-- ============================================================================

