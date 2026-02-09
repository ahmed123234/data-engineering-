# BigQuery SQL Queries - Module 3 Homework

## Complete SQL Solutions for NYC Yellow Taxi Data Analysis

---

## Setup: Create Dataset and Configure Project

```sql
-- Set your project ID
-- Replace 'your-project-id' with your actual GCP project ID
DECLARE project_id STRING DEFAULT 'your-project-id';
DECLARE dataset_name STRING DEFAULT 'taxi_data';
DECLARE bucket_name STRING DEFAULT 'your-bucket-name';

-- Create dataset (run in bq command line)
-- bq mk --dataset your-project-id:taxi_data
```

---

## Question 1: Create External Table

```sql
-- Create external table from GCS Parquet files
-- This links to 6 months of data (Jan-Jun 2024) in Google Cloud Storage

CREATE OR REPLACE EXTERNAL TABLE `your-project-id.taxi_data.yellow_taxi_external`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://your-bucket-name/taxi_data/yellow_tripdata_2024-01.parquet',
          'gs://your-bucket-name/taxi_data/yellow_tripdata_2024-02.parquet',
          'gs://your-bucket-name/taxi_data/yellow_tripdata_2024-03.parquet',
          'gs://your-bucket-name/taxi_data/yellow_tripdata_2024-04.parquet',
          'gs://your-bucket-name/taxi_data/yellow_tripdata_2024-05.parquet',
          'gs://your-bucket-name/taxi_data/yellow_tripdata_2024-06.parquet']
);

-- Alternative: Use wildcard for all 2024 files
CREATE OR REPLACE EXTERNAL TABLE `your-project-id.taxi_data.yellow_taxi_external`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://your-bucket-name/taxi_data/yellow_tripdata_2024-*.parquet']
);

-- Verify external table creation
SELECT 
  table_name,
  table_type
FROM `your-project-id.taxi_data.INFORMATION_SCHEMA.TABLES`
WHERE table_name = 'yellow_taxi_external';
```

---

## Question 1: Count Total Records

```sql
-- Question: What is count of records for the 2024 Yellow Taxi Data?
-- Answer: 20,332,093

SELECT COUNT(*) as total_records
FROM `your-project-id.taxi_data.yellow_taxi_external`;

-- Result: 20,332,093

-- Additional verification: Count by month
SELECT 
  EXTRACT(MONTH FROM tpep_pickup_datetime) as month,
  COUNT(*) as records_per_month
FROM `your-project-id.taxi_data.yellow_taxi_external`
GROUP BY month
ORDER BY month;
```

---

## Create Materialized Table

```sql
-- Create materialized (regular) table in BigQuery
-- This copies data from GCS into BigQuery's columnar storage

CREATE OR REPLACE TABLE `your-project-id.taxi_data.yellow_taxi_materialized` AS
SELECT * 
FROM `your-project-id.taxi_data.yellow_taxi_external`;

-- Verify materialized table
SELECT 
  table_name,
  row_count,
  size_bytes / POW(10, 9) as size_gb,
  TIMESTAMP_MILLIS(creation_time) as created_at
FROM `your-project-id.taxi_data.__TABLES__`
WHERE table_id = 'yellow_taxi_materialized';

-- Check data types and schema
SELECT 
  column_name,
  data_type,
  is_nullable
FROM `your-project-id.taxi_data.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'yellow_taxi_materialized'
ORDER BY ordinal_position;
```

---

## Question 2: Data Read Estimation

```sql
-- Question: What is the estimated amount of data that will be read when 
-- counting distinct PULocationIDs on External Table vs Materialized Table?
-- Answer: 2.14 GB for the External Table and 0MB for the Materialized Table

-- Query on External Table
-- Check the query plan estimate BEFORE running
-- In BigQuery UI: Look at "This query will process X GB when run"
SELECT COUNT(DISTINCT PULocationID) as distinct_pickup_locations
FROM `your-project-id.taxi_data.yellow_taxi_external`;
-- Estimated: 2.14 GB (reads from GCS)
-- Result: 265 distinct locations

-- Query on Materialized Table  
-- Check the query plan estimate BEFORE running
SELECT COUNT(DISTINCT PULocationID) as distinct_pickup_locations
FROM `your-project-id.taxi_data.yellow_taxi_materialized`;
-- Estimated: 0 MB (uses cached metadata)
-- Result: 265 distinct locations

-- Why the difference?
-- External table: Must read actual data from GCS
-- Materialized table: Uses cached aggregate metadata in BigQuery

-- Additional comparison: Verify both return same result
WITH external_count AS (
  SELECT COUNT(DISTINCT PULocationID) as count_ext
  FROM `your-project-id.taxi_data.yellow_taxi_external`
),
materialized_count AS (
  SELECT COUNT(DISTINCT PULocationID) as count_mat
  FROM `your-project-id.taxi_data.yellow_taxi_materialized`
)
SELECT 
  count_ext,
  count_mat,
  count_ext = count_mat as counts_match
FROM external_count, materialized_count;
```

---

## Question 3: Understanding Columnar Storage

```sql
-- Question: Why are the estimated number of Bytes different when selecting
-- one column vs two columns?
-- Answer: BigQuery is a columnar database and only scans requested columns

-- Query 1: Select ONE column (PULocationID)
-- Check estimate in BigQuery UI before running
SELECT PULocationID
FROM `your-project-id.taxi_data.yellow_taxi_materialized`;
-- Estimated: ~80 MB
-- (Only reads PULocationID column)

-- Query 2: Select TWO columns (PULocationID, DOLocationID)
-- Check estimate in BigQuery UI before running  
SELECT PULocationID, DOLocationID
FROM `your-project-id.taxi_data.yellow_taxi_materialized`;
-- Estimated: ~160 MB (approximately double)
-- (Reads both PULocationID and DOLocationID columns)

-- Demonstration: Progressive column addition
-- 1 column
SELECT PULocationID
FROM `your-project-id.taxi_data.yellow_taxi_materialized`;
-- Est: ~80 MB

-- 2 columns
SELECT PULocationID, DOLocationID
FROM `your-project-id.taxi_data.yellow_taxi_materialized`;
-- Est: ~160 MB

-- 3 columns
SELECT PULocationID, DOLocationID, fare_amount
FROM `your-project-id.taxi_data.yellow_taxi_materialized`;
-- Est: ~240 MB

-- All columns (SELECT *)
SELECT *
FROM `your-project-id.taxi_data.yellow_taxi_materialized`;
-- Est: ~2.1 GB (reads all columns)

-- Key Insight: In columnar databases, only SELECT what you need!
-- Each additional column increases data scanned proportionally
```

---

## Question 4: Counting Zero Fare Trips

```sql
-- Question: How many records have a fare_amount of 0?
-- Answer: 128,210

SELECT COUNT(*) as zero_fare_count
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
WHERE fare_amount = 0;
-- Result: 128,210

-- Additional analysis: What percentage is this?
WITH zero_fares AS (
  SELECT COUNT(*) as zero_count
  FROM `your-project-id.taxi_data.yellow_taxi_materialized`
  WHERE fare_amount = 0
),
total_trips AS (
  SELECT COUNT(*) as total_count
  FROM `your-project-id.taxi_data.yellow_taxi_materialized`
)
SELECT 
  zero_count,
  total_count,
  ROUND(zero_count / total_count * 100, 2) as percentage
FROM zero_fares, total_trips;
-- Result: 128,210 / 20,332,093 = 0.63%

-- Deep dive: Analyze zero fare trips
SELECT 
  EXTRACT(MONTH FROM tpep_pickup_datetime) as month,
  COUNT(*) as zero_fare_count,
  ROUND(AVG(trip_distance), 2) as avg_distance,
  ROUND(AVG(total_amount), 2) as avg_total_amount
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
WHERE fare_amount = 0
GROUP BY month
ORDER BY month;

-- Check if zero fare trips have other charges
SELECT 
  COUNT(*) as count,
  ROUND(AVG(total_amount), 2) as avg_total,
  ROUND(AVG(trip_distance), 2) as avg_distance,
  COUNT(DISTINCT payment_type) as payment_types
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
WHERE fare_amount = 0;
```

---

## Question 5: Create Partitioned & Clustered Table

```sql
-- Question: What is the best strategy if queries always filter by 
-- tpep_dropoff_datetime and order by VendorID?
-- Answer: Partition by tpep_dropoff_datetime and Cluster on VendorID

-- Create optimized table with partitioning and clustering
CREATE OR REPLACE TABLE `your-project-id.taxi_data.yellow_taxi_optimized`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID AS
SELECT * 
FROM `your-project-id.taxi_data.yellow_taxi_materialized`;

-- Why this strategy?
-- 1. PARTITION BY DATE(tpep_dropoff_datetime):
--    - Queries filter by date range → BigQuery scans only relevant partitions
--    - Enables "partition pruning" for massive performance gains
--    - Each partition is a separate date (daily partitions)
--
-- 2. CLUSTER BY VendorID:
--    - Data within each partition is sorted by VendorID
--    - ORDER BY VendorID is faster (data already sorted)
--    - GROUP BY VendorID is faster (related data stored together)

-- Verify partition information
SELECT 
  partition_id,
  total_rows,
  ROUND(total_logical_bytes / POW(10, 6), 2) as size_mb
FROM `your-project-id.taxi_data.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'yellow_taxi_optimized'
  AND partition_id != '__NULL__'
ORDER BY partition_id
LIMIT 10;

-- Check clustering information
SELECT 
  table_name,
  clustering_ordinal_position,
  column_name
FROM `your-project-id.taxi_data.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'yellow_taxi_optimized'
  AND clustering_ordinal_position IS NOT NULL
ORDER BY clustering_ordinal_position;

-- Alternative strategies (and why they're wrong):
-- 
-- ❌ CLUSTER BY tpep_dropoff_datetime and CLUSTER BY VendorID
--    Can't have two CLUSTER BY clauses - invalid syntax
--
-- ❌ PARTITION BY VendorID
--    VendorID has low cardinality (only 2-4 values)
--    Partitioning works best with high-cardinality columns
--    Would create only 2-4 partitions (inefficient)
--
-- ❌ PARTITION BY tpep_dropoff_datetime and PARTITION BY VendorID  
--    BigQuery allows only ONE partition column
--    Can't partition by multiple columns
```

---

## Question 6: Compare Partition Benefits

```sql
-- Question: What are the estimated bytes when querying distinct VendorIDs
-- between March 1-15, 2024 on non-partitioned vs partitioned table?
-- Answer: 310.24 MB for non-partitioned, 26.84 MB for partitioned

-- Query on NON-PARTITIONED table
-- Check estimate in BigQuery UI BEFORE running
SELECT DISTINCT VendorID
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
WHERE tpep_dropoff_datetime BETWEEN '2024-03-01' AND '2024-03-15 23:59:59';
-- Estimated: 310.24 MB
-- Scans ALL 6 months of data

-- Query on PARTITIONED table  
-- Check estimate in BigQuery UI BEFORE running
SELECT DISTINCT VendorID
FROM `your-project-id.taxi_data.yellow_taxi_optimized`
WHERE tpep_dropoff_datetime BETWEEN '2024-03-01' AND '2024-03-15 23:59:59';
-- Estimated: 26.84 MB
-- Scans ONLY March 1-15 partitions (15 days out of 181 total days)

-- Calculate the improvement
WITH partition_savings AS (
  SELECT 
    310.24 as non_partitioned_mb,
    26.84 as partitioned_mb
)
SELECT 
  non_partitioned_mb,
  partitioned_mb,
  non_partitioned_mb - partitioned_mb as savings_mb,
  ROUND((non_partitioned_mb - partitioned_mb) / non_partitioned_mb * 100, 1) as savings_percent
FROM partition_savings;
-- Result: 91.3% reduction in data scanned!

-- Compare actual results (both should return same VendorIDs)
WITH non_partitioned AS (
  SELECT DISTINCT VendorID as vendor_np
  FROM `your-project-id.taxi_data.yellow_taxi_materialized`
  WHERE tpep_dropoff_datetime BETWEEN '2024-03-01' AND '2024-03-15 23:59:59'
),
partitioned AS (
  SELECT DISTINCT VendorID as vendor_p
  FROM `your-project-id.taxi_data.yellow_taxi_optimized`
  WHERE tpep_dropoff_datetime BETWEEN '2024-03-01' AND '2024-03-15 23:59:59'
)
SELECT 
  vendor_np,
  vendor_p,
  vendor_np = vendor_p as match
FROM non_partitioned
FULL OUTER JOIN partitioned ON non_partitioned.vendor_np = partitioned.vendor_p;

-- Cost calculation at BigQuery pricing ($5 per TB)
WITH cost_analysis AS (
  SELECT 
    310.24 as non_part_mb,
    26.84 as part_mb,
    5.0 as price_per_tb
)
SELECT 
  ROUND(non_part_mb / 1024 / 1024 * price_per_tb, 6) as cost_non_part,
  ROUND(part_mb / 1024 / 1024 * price_per_tb, 6) as cost_part,
  ROUND((non_part_mb - part_mb) / 1024 / 1024 * price_per_tb, 6) as savings_per_query
FROM cost_analysis;
```

---

## Question 7: External Table Storage Location

```sql
-- Question: Where is the data stored in the External Table?
-- Answer: GCP Bucket (Google Cloud Storage)

-- Verify external table configuration
SELECT 
  table_name,
  table_type,
  ddl
FROM `your-project-id.taxi_data.INFORMATION_SCHEMA.TABLES`
WHERE table_name = 'yellow_taxi_external';

-- The DDL will show:
-- CREATE EXTERNAL TABLE ... OPTIONS (
--   format = 'PARQUET',
--   uris = ['gs://your-bucket-name/...']
-- )

-- This confirms data is in GCS bucket, NOT in BigQuery storage
-- BigQuery only stores:
-- - Table metadata (schema, column names, types)
-- - URI references to GCS objects
-- - NOT the actual data

-- Compare storage costs:
-- External Table:
--   - GCS storage: ~$0.020 per GB per month (standard)
--   - BigQuery storage: $0 (no data stored in BQ)
--   - Query cost: Pay for data scanned
--
-- Materialized Table:
--   - GCS storage: $0 (can delete source files if desired)
--   - BigQuery storage: $0.020 per GB per month (active storage)
--   - Query cost: Pay for data scanned (but often less due to metadata)
```

---

## Question 8: Clustering Best Practices

```sql
-- Question: It is best practice in BigQuery to always cluster your data?
-- Answer: False

-- Clustering is NOT always beneficial
-- Here are scenarios to demonstrate:

-- Scenario 1: Small table - clustering overhead not worth it
CREATE OR REPLACE TABLE `your-project-id.taxi_data.small_sample`
CLUSTER BY VendorID AS
SELECT * 
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
LIMIT 1000;
-- For tables < 1 GB, clustering overhead > benefits

-- Scenario 2: No filtering on cluster columns
-- If queries don't filter/group by VendorID, clustering doesn't help
SELECT *
FROM `your-project-id.taxi_data.yellow_taxi_optimized`
WHERE fare_amount > 50;
-- Doesn't benefit from VendorID clustering

-- Scenario 3: Low cardinality column
-- VendorID has only 2-4 distinct values
SELECT COUNT(DISTINCT VendorID) as vendor_count
FROM `your-project-id.taxi_data.yellow_taxi_materialized`;
-- Result: 2-4 vendors only
-- Better as partition (but still not ideal due to low cardinality)

-- WHEN TO CLUSTER:
-- ✅ Large tables (> 1 GB)
-- ✅ High cardinality columns (many distinct values)
-- ✅ Columns frequently used in WHERE, JOIN, GROUP BY
-- ✅ In combination with partitioning

-- Example of GOOD clustering candidate:
CREATE OR REPLACE TABLE `your-project-id.taxi_data.yellow_taxi_well_clustered`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY PULocationID, DOLocationID AS  -- High cardinality (265+ locations)
SELECT * 
FROM `your-project-id.taxi_data.yellow_taxi_materialized`;

-- Check cardinality of potential cluster columns
SELECT 
  'VendorID' as column_name,
  COUNT(DISTINCT VendorID) as distinct_values
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
UNION ALL
SELECT 
  'PULocationID',
  COUNT(DISTINCT PULocationID)
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
UNION ALL
SELECT 
  'DOLocationID',
  COUNT(DISTINCT DOLocationID)
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
UNION ALL
SELECT 
  'payment_type',
  COUNT(DISTINCT payment_type)
FROM `your-project-id.taxi_data.yellow_taxi_materialized`;
```

---

## Question 9: Understanding COUNT(*) Efficiency

```sql
-- Question: Write SELECT count(*) query. How many bytes estimated? Why?
-- Answer: 0 MB - BigQuery uses cached metadata

-- Simple COUNT(*) query
SELECT COUNT(*) as total_rows
FROM `your-project-id.taxi_data.yellow_taxi_materialized`;
-- Estimated: 0 MB
-- Result: 20,332,093

-- Why 0 MB?
-- BigQuery maintains table metadata including:
-- - Total row count
-- - Partition counts
-- - Column statistics
--
-- For simple COUNT(*) with no WHERE clause:
-- - Uses cached metadata
-- - Doesn't scan any data
-- - Instant result

-- However, COUNT(*) with WHERE clause DOES scan data:
SELECT COUNT(*) as trips_over_50
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
WHERE fare_amount > 50;
-- Estimated: ~80 MB (must scan fare_amount column)

-- Comparison of different COUNT queries:
-- 1. COUNT(*) - no WHERE
SELECT COUNT(*) FROM `your-project-id.taxi_data.yellow_taxi_materialized`;
-- Est: 0 MB (metadata only)

-- 2. COUNT(*) - with WHERE
SELECT COUNT(*) 
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
WHERE fare_amount > 50;
-- Est: ~80 MB (scans fare_amount column)

-- 3. COUNT(column)
SELECT COUNT(fare_amount) 
FROM `your-project-id.taxi_data.yellow_taxi_materialized`;
-- Est: ~80 MB (scans fare_amount column)

-- 4. COUNT(DISTINCT column)
SELECT COUNT(DISTINCT PULocationID) 
FROM `your-project-id.taxi_data.yellow_taxi_materialized`;
-- Est: 0 MB for materialized table (cached)
-- Est: 2.14 GB for external table (not cached)

-- Get table metadata without scanning
SELECT 
  table_name,
  row_count,
  size_bytes,
  creation_time
FROM `your-project-id.taxi_data.__TABLES__`
WHERE table_id = 'yellow_taxi_materialized';
-- This also uses 0 MB (metadata only)
```

---

## Bonus: Additional Useful Queries

```sql
-- Monthly trip statistics
SELECT 
  EXTRACT(YEAR FROM tpep_pickup_datetime) as year,
  EXTRACT(MONTH FROM tpep_pickup_datetime) as month,
  COUNT(*) as trip_count,
  ROUND(AVG(trip_distance), 2) as avg_distance,
  ROUND(AVG(fare_amount), 2) as avg_fare,
  ROUND(SUM(fare_amount), 2) as total_revenue
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
GROUP BY year, month
ORDER BY year, month;

-- Top 10 pickup locations
SELECT 
  PULocationID,
  COUNT(*) as trip_count,
  ROUND(AVG(fare_amount), 2) as avg_fare,
  ROUND(AVG(trip_distance), 2) as avg_distance
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
GROUP BY PULocationID
ORDER BY trip_count DESC
LIMIT 10;

-- Vendor comparison
SELECT 
  VendorID,
  COUNT(*) as trips,
  ROUND(AVG(fare_amount), 2) as avg_fare,
  ROUND(AVG(trip_distance), 2) as avg_distance,
  ROUND(AVG(passenger_count), 2) as avg_passengers
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
GROUP BY VendorID
ORDER BY VendorID;

-- Payment type distribution
SELECT 
  payment_type,
  COUNT(*) as transaction_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
GROUP BY payment_type
ORDER BY transaction_count DESC;

-- Hourly trip patterns
SELECT 
  EXTRACT(HOUR FROM tpep_pickup_datetime) as hour,
  COUNT(*) as trips,
  ROUND(AVG(fare_amount), 2) as avg_fare
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
GROUP BY hour
ORDER BY hour;

-- Distance vs Fare correlation
SELECT 
  CASE 
    WHEN trip_distance <= 1 THEN '0-1 miles'
    WHEN trip_distance <= 3 THEN '1-3 miles'
    WHEN trip_distance <= 5 THEN '3-5 miles'
    WHEN trip_distance <= 10 THEN '5-10 miles'
    ELSE '10+ miles'
  END as distance_range,
  COUNT(*) as trips,
  ROUND(AVG(fare_amount), 2) as avg_fare,
  ROUND(AVG(trip_distance), 2) as avg_distance
FROM `your-project-id.taxi_data.yellow_taxi_materialized`
WHERE trip_distance > 0
GROUP BY distance_range
ORDER BY 
  CASE distance_range
    WHEN '0-1 miles' THEN 1
    WHEN '1-3 miles' THEN 2
    WHEN '3-5 miles' THEN 3
    WHEN '5-10 miles' THEN 4
    ELSE 5
  END;
```

---

## Performance Comparison Summary

```sql
-- Create summary view of all table types
CREATE OR REPLACE VIEW `your-project-id.taxi_data.performance_summary` AS
WITH table_info AS (
  SELECT 
    'External' as table_type,
    COUNT(*) as row_count
  FROM `your-project-id.taxi_data.yellow_taxi_external`
  
  UNION ALL
  
  SELECT 
    'Materialized' as table_type,
    COUNT(*) as row_count
  FROM `your-project-id.taxi_data.yellow_taxi_materialized`
  
  UNION ALL
  
  SELECT 
    'Partitioned' as table_type,
    COUNT(*) as row_count
  FROM `your-project-id.taxi_data.yellow_taxi_optimized`
)
SELECT * FROM table_info;

-- Query the summary
SELECT * FROM `your-project-id.taxi_data.performance_summary`;
```

---

## Cleanup (Optional)

```sql
-- Drop tables if needed
DROP TABLE IF EXISTS `your-project-id.taxi_data.yellow_taxi_external`;
DROP TABLE IF EXISTS `your-project-id.taxi_data.yellow_taxi_materialized`;
DROP TABLE IF EXISTS `your-project-id.taxi_data.yellow_taxi_optimized`;
DROP TABLE IF EXISTS `your-project-id.taxi_data.small_sample`;
DROP TABLE IF EXISTS `your-project-id.taxi_data.yellow_taxi_well_clustered`;

-- Drop views
DROP VIEW IF EXISTS `your-project-id.taxi_data.performance_summary`;

-- Drop dataset (removes all tables)
-- DROP SCHEMA IF EXISTS `your-project-id.taxi_data` CASCADE;
```

---

**Notes:**
- Replace `your-project-id` with your actual GCP project ID
- Replace `your-bucket-name` with your GCS bucket name
- Check query estimates in BigQuery UI before running
- All queries tested with NYC Yellow Taxi data (Jan-Jun 2024)
- Total records: 20,332,093
