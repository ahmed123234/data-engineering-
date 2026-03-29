"""
Q6: PyFlink – 1-hour tumbling window, total tip_amount per hour.
Place in: workshop/src/job/q6_hourly_tips.py
Submit: docker exec -it workshop-jobmanager-1 flink run -py /opt/src/job/q6_hourly_tips.py
"""

from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import StreamTableEnvironment

# ── Environment ───────────────────────────────────────────────────────────────
env = StreamExecutionEnvironment.get_execution_environment()
env.set_parallelism(1)
t_env = StreamTableEnvironment.create(env)

# ── Source DDL ────────────────────────────────────────────────────────────────
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
    'properties.group.id'          = 'flink-q6',
    'scan.startup.mode'            = 'earliest-offset',
    'format'                       = 'json'
)
""")

# ── Sink DDL ─────────────────────────────────────────────────────────────────
t_env.execute_sql("""
CREATE TABLE hourly_tips (
    window_start  TIMESTAMP(3),
    total_tip     DOUBLE,
    PRIMARY KEY (window_start) NOT ENFORCED
) WITH (
    'connector'  = 'jdbc',
    'url'        = 'jdbc:postgresql://postgres:5432/postgres',
    'table-name' = 'hourly_tips',
    'username'   = 'postgres',
    'password'   = 'postgres'
)
""")

# ── Query: 1-hour tumbling window ─────────────────────────────────────────────
t_env.execute_sql("""
INSERT INTO hourly_tips
SELECT
    TUMBLE_START(event_timestamp, INTERVAL '1' HOUR) AS window_start,
    SUM(tip_amount)                                  AS total_tip
FROM green_trips
GROUP BY
    TUMBLE(event_timestamp, INTERVAL '1' HOUR)
""")