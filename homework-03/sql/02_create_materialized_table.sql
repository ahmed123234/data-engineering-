-- sql/02_create_materialized_table.sql
CREATE OR REPLACE TABLE `de-zoomcamp-2026.taxi_data.yellow_taxi_materialized` AS
SELECT * 
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_external`;

-- Check table info
SELECT 
  table_name,
  row_count,
  size_bytes / POW(10, 9) as size_gb
FROM `de-zoomcamp-2026.taxi_data.__TABLES__`
WHERE table_id = 'yellow_taxi_materialized';
