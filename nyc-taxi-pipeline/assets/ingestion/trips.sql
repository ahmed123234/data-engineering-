/* @bruin
name: ingestion.trips
type: duckdb.sql
materialization:
  type: table
  strategy: time_interval
  time_column: pickup_datetime
  interval: month
columns:
  - name: vendor_id
    type: integer
    description: Vendor ID
    checks:
      - name: not_null
  - name: pickup_datetime
    type: timestamp
    description: Pickup timestamp
    checks:
      - name: not_null
  - name: dropoff_datetime
    type: timestamp
    description: Dropoff timestamp
  - name: passenger_count
    type: integer
    description: Number of passengers
    checks:
      - name: positive
  - name: trip_distance
    type: float
    description: Trip distance in miles
    checks:
      - name: positive
  - name: fare_amount
    type: float
    description: Fare amount
    checks:
      - name: positive
  - name: payment_type
    type: integer
    description: Payment type (1=Credit, 2=Cash, etc.)
  - name: total_amount
    type: float
    description: Total amount including tips and tolls
@bruin */

-- Read from parquet files with partition filtering
-- This assumes parquet files are in data/raw/trips/ partitioned by month
SELECT 
    -- Core fields with explicit casting
    vendor_id::INTEGER as vendor_id,
    pickup_datetime::TIMESTAMP as pickup_datetime,
    dropoff_datetime::TIMESTAMP as dropoff_datetime,
    passenger_count::INTEGER as passenger_count,
    trip_distance::FLOAT as trip_distance,
    fare_amount::FLOAT as fare_amount,
    payment_type::INTEGER as payment_type,
    total_amount::FLOAT as total_amount,
    
    -- Location IDs
    PULocationID::INTEGER as pickup_location_id,
    DOLocationID::INTEGER as dropoff_location_id,
    
    -- Rate and extra fields
    RatecodeID::INTEGER as rate_code_id,
    extra::FLOAT as extra,
    mta_tax::FLOAT as mta_tax,
    tip_amount::FLOAT as tip_amount,
    tolls_amount::FLOAT as tolls_amount,
    improvement_surcharge::FLOAT as improvement_surcharge,
    congestion_surcharge::FLOAT as congestion_surcharge,
    
    -- Add audit columns
    CURRENT_TIMESTAMP as ingested_at,
    \{{
