"""
Q5: PyFlink – Session window (5-minute gap) per PULocationID.
Find the PULocationID with the longest session (most trips in one session).
Place in: workshop/src/job/q5_session_window.py
Submit: docker exec -it workshop-jobmanager-1 flink run -py /opt/src/job/q5_session_window.py
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
    'properties.group.id'          = 'flink-q5',
    'scan.startup.mode'            = 'earliest-offset',
    'format'                       = 'json'
)
""")

# ── Sink DDL ─────────────────────────────────────────────────────────────────
t_env.execute_sql("""
CREATE TABLE session_window_counts (
    window_start  TIMESTAMP(3),
    window_end    TIMESTAMP(3),
    PULocationID  INT,
    num_trips     BIGINT,
    PRIMARY KEY (window_start, PULocationID) NOT ENFORCED
) WITH (
    'connector'  = 'jdbc',
    'url'        = 'jdbc:postgresql://postgres:5432/postgres',
    'table-name' = 'session_window_counts',
    'username'   = 'postgres',
    'password'   = 'postgres'
)
""")

# ── Query: Session window with 5-minute inactivity gap ───────────────────────
t_env.execute_sql("""
INSERT INTO session_window_counts
SELECT
    SESSION_START(event_timestamp, INTERVAL '5' MINUTE) AS window_start,
    SESSION_END(event_timestamp,   INTERVAL '5' MINUTE) AS window_end,
    PULocationID,
    COUNT(*)                                             AS num_trips
FROM green_trips
GROUP BY
    SESSION(event_timestamp, INTERVAL '5' MINUTE),
    PULocationID
""")