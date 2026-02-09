-- sql/01_create_external_table.sql
CREATE OR REPLACE EXTERNAL TABLE `de-zoomcamp-2026.taxi_data.yellow_taxi_external`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://your-bucket-name/taxi_data/yellow_tripdata_2024-*.parquet']
);

-- Verify creation
SELECT COUNT(*) as total_records
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_external`;
-- Result: 20,332,093
