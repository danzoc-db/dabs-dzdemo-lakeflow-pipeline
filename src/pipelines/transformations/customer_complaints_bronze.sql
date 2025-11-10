-- ============================================================================
-- BRONZE LAYER: Raw Data Ingestion
-- Purpose: Ingest raw data from files with minimal transformation
-- Pattern: Read files, add audit columns (ingestion timestamp, source file)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STREAMING vs LIVE TABLES - When to Use Which?
-- ----------------------------------------------------------------------------
-- 
-- STREAMING TABLE (incremental processing):
--   - Processes new/changed files incrementally
--   - Lower latency for real-time data
--   - Use for: Fact tables, event streams, transaction data
--   - Example: Orders, events, logs, sensor data
--   - Limitations: Cannot use window functions, complex aggregations
--
-- LIVE TABLE (full refresh or incremental):
--   - Can do full refresh or incremental based on content
--   - More flexible - supports all SQL operations
--   - Use for: Dimension tables, reference data, complex transformations
--   - Example: Customer master, product catalog, lookup tables
--   - No limitations on SQL operations
--
-- Best Practice: Use STREAMING for large fact tables, LIVE for dimensions
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- STREAMING TABLE: Complaints (Fact Data)
-- R Pattern: read.csv() for transactional data
-- Why Streaming: Complaints are event-driven data that arrive continuously
-- ----------------------------------------------------------------------------
CREATE OR REFRESH STREAMING TABLE bronze_complaints
COMMENT "Raw complaints data from managed volume - STREAMING for incremental ingestion"
AS SELECT 
  *,
  current_timestamp() as ingestion_time,
  _metadata.file_path as source_file
FROM STREAM(read_files(
  '/Volumes/dz_demos/lakeflow_dec_pipe_r_scripts/demo_source_data/tblComplaints/',
  format => 'csv',
  header => true,
  mode => 'PERMISSIVE'
))
-- Note: STREAM() wrapper enables incremental processing
-- New files or appended rows are automatically detected and processed
-- Existing processed data is not re-read (cost & performance optimization)
;

-- ----------------------------------------------------------------------------
-- LIVE TABLE: Employees (Reference Data)
-- R Pattern: read.csv() for lookup tables
-- Why Live: Employee data is relatively static reference data
-- ----------------------------------------------------------------------------
CREATE OR REFRESH LIVE TABLE bronze_employees
COMMENT "Employee reference data - LIVE TABLE for dimension/lookup data"
AS SELECT 
  *,
  current_timestamp() as ingestion_time
FROM read_files(
  '/Volumes/dz_demos/lakeflow_dec_pipe_r_scripts/demo_source_data/rk_insight_hierarchy/',
  format => 'csv',
  header => true,
  mode => 'PERMISSIVE'
)
-- Note: No STREAM() wrapper - this is a LIVE table
-- Reference data like employees changes infrequently
-- Full refresh is acceptable for small dimension tables
-- Allows more complex SQL if needed later
;

-- ============================================================================
-- BRONZE LAYER SUMMARY
-- ============================================================================
-- Tables Created: 2
--   - bronze_complaints (STREAMING) - 100 rows
--   - bronze_employees (LIVE) - 25 rows
--
-- Key Characteristics:
--   ✓ Raw data preservation (SELECT *)
--   ✓ Audit columns added (ingestion_time, source_file)
--   ✓ No business logic or transformations
--   ✓ No filtering (all data loaded)
--   ✓ Mixed streaming/live based on data characteristics
-- ============================================================================

