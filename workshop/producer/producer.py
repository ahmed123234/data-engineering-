import json
import pandas as pd
from kafka import KafkaProducer
from time import time

# ── Config ────────────────────────────────────────────
BOOTSTRAP_SERVER = 'localhost:9092'
TOPIC = 'green-trips'
PARQUET_FILE = 'green_tripdata_2019-10.parquet'

COLUMNS = [
    'lpep_pickup_datetime',
    'lpep_dropoff_datetime',
    'PULocationID',
    'DOLocationID',
    'passenger_count',
    'trip_distance',
    'tip_amount',
    'total_amount',
]

# ── Serializer ────────────────────────────────────────
def json_serializer(data: dict) -> bytes:
    return json.dumps(data).encode('utf-8')

# ── Producer ──────────────────────────────────────────
producer = KafkaProducer(
    bootstrap_servers=[BOOTSTRAP_SERVER],
    value_serializer=json_serializer,
    # Performance tuning
    linger_ms=20,           # wait up to 20ms to batch messages
    batch_size=64 * 1024,   # 64 KB batch size
    compression_type='gzip',
)

print(f"Connected: {producer.bootstrap_connected()}")

# ── Load & filter data ────────────────────────────────
print(f"Loading {PARQUET_FILE}...")
df = pd.read_parquet(PARQUET_FILE, columns=COLUMNS)
print(f"Rows to send: {len(df):,}")

# Convert datetime columns to strings (required for JSON serialization)
datetime_cols = ['lpep_pickup_datetime', 'lpep_dropoff_datetime']
for col in datetime_cols:
    df[col] = df[col].astype(str)

# ── Send ──────────────────────────────────────────────
t0 = time()

for _, row in df.iterrows():
    producer.send(TOPIC, value=row.to_dict())

producer.flush()

t1 = time()
print(f'took {(t1 - t0):.2f} seconds')
print(f'Sent {len(df):,} records to topic [{TOPIC}]')
