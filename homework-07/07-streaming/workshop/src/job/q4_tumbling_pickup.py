"""
Q4: PyFlink – 5-minute tumbling window, trips per PULocationID.
Place in: workshop/src/job/q4_tumbling_pickup.py
Submit: docker exec -it workshop-jobmanager-1 flink run -py /opt/src/job/q4_tumbling_pickup.py
"""

from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import StreamTableEnvironment

# ── Environment ───────────────────────────────────────────────────────────────
env = StreamExecutionEnvironment.get_execution_environment()
env.set_parallelism(1)          # green-trips has 1 partition → must be 1
t_env = StreamTableEnvironment.create(env)

# ── Source DDL (Kafka / Redpanda) ─────────────────────────────────────────────
t_env.execute_sql("""
CREATE TABLE green_trips (
    lpep_pickup_datetime  VARCHAR,
    lpep_dropoff_datetime VARCHAR,
    PULocationID          INT,
    DOLocationID          INT,
    passenger_count       DOUBLE,
    trip_distance         DOUBLE,
    tip_amount            DOUBLE,
    total_amount          DOUBLE,
    event_timestamp AS TO_TIMESTAMP(lpep_pickup_datetime, 'yyyy-MM-dd HH:mm:ss'),
    WATERMARK FOR event_timestamp AS event_timestamp - INTERVAL '5' SECOND
) WITH (
    'connector'                    = 'kafka',
    'topic'                        = 'green-trips',
    'properties.bootstrap.servers' = 'redpanda:29092',
    'properties.group.id'          = 'flink-q4',
    'scan.startup.mode'            = 'earliest-offset',
    'format'                       = 'json'
)
""")

# ── Sink DDL (PostgreSQL) ─────────────────────────────────────────────────────
t_env.execute_sql("""
CREATE TABLE pickup_location_counts (
    window_start  TIMESTAMP(3),
    PULocationID  INT,
    num_trips     BIGINT,
    PRIMARY KEY (window_start, PULocationID) NOT ENFORCED
) WITH (
    'connector'  = 'jdbc',
    'url'        = 'jdbc:postgresql://postgres:5432/postgres',
    'table-name' = 'pickup_location_counts',
    'username'   = 'postgres',
    'password'   = 'postgres'
)
""")

# ── Query: 5-minute tumbling window ──────────────────────────────────────────
t_env.execute_sql("""
INSERT INTO pickup_location_counts
SELECT
    TUMBLE_START(event_timestamp, INTERVAL '5' MINUTE) AS window_start,
    PULocationID,
    COUNT(*)                                            AS num_trips
FROM green_trips
GROUP BY
    TUMBLE(event_timestamp, INTERVAL '5' MINUTE),
    PULocationID
""")