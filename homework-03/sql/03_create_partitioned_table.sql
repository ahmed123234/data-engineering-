-- sql/03_create_partitioned_table.sql
CREATE OR REPLACE TABLE `de-zoomcamp-2026.taxi_data.yellow_taxi_optimized`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID AS
SELECT * 
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_materialized`;

-- View partition information
SELECT 
  partition_id,
  total_rows,
  total_logical_bytes / POW(10, 6) as size_mb
FROM `de-zoomcamp-2026.taxi_data.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'yellow_taxi_optimized'
ORDER BY partition_id;
