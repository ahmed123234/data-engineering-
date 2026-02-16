-- models/staging/stg_fhv_tripdata.sql

{{ config(materialized='table') }}

SELECT
    -- identifiers
    {{ dbt_utils.generate_surrogate_key(['dispatching_base_num', 'pickup_datetime']) }} as tripid,
    
    -- dispatch info
    dispatching_base_num,
    
    -- timestamps
    cast(pickup_datetime as timestamp) as pickup_datetime,
    cast(dropoff_datetime as timestamp) as dropoff_datetime,
    
    -- location IDs - renamed to match conventions
    cast(PUlocationID as integer) as pickup_location_id,
    cast(DOlocationID as integer) as dropoff_location_id,
    
    -- additional fields
    cast(SR_Flag as integer) as shared_ride_flag,
    affiliated_base_number

FROM {{ source('staging', 'fhv_tripdata_2019') }}

-- CRITICAL: Filter out NULL dispatching_base_num
WHERE dispatching_base_num IS NOT NULL

-- For development, limit rows
{% if var('is_test_run', default=true) %}
  LIMIT 100
{% endif %}