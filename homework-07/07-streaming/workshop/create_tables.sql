-- Run this against PostgreSQL before starting Flink jobs
-- psql -h localhost -U postgres -d postgres -f create_tables.sql

-- Q4 – 5-minute tumbling window: trips per PULocationID
CREATE TABLE IF NOT EXISTS pickup_location_counts (
    window_start  TIMESTAMP,
    PULocationID  INTEGER,
    num_trips     BIGINT,
    PRIMARY KEY (window_start, PULocationID)
);

-- Q5 – Session window (5-min gap): trips per PULocationID per session
CREATE TABLE IF NOT EXISTS session_window_counts (
    window_start  TIMESTAMP,
    window_end    TIMESTAMP,
    PULocationID  INTEGER,
    num_trips     BIGINT,
    PRIMARY KEY (window_start, PULocationID)
);

-- Q6 – 1-hour tumbling window: total tip_amount per hour
CREATE TABLE IF NOT EXISTS hourly_tips (
    window_start  TIMESTAMP PRIMARY KEY,
    total_tip     DOUBLE PRECISION
);