"""
Q1 & Q2: Kafka Producer - sends green taxi trip data to Redpanda
Run: python producer.py
"""

import pandas as pd
import json
from kafka import KafkaProducer
from time import time

# ── Config ──────────────────────────────────────────────────────────────────
TOPIC        = "green-trips"
BOOTSTRAP    = "localhost:9092"
PARQUET_FILE = "../data/green_tripdata_2025-10.parquet"

COLUMNS = [
    "lpep_pickup_datetime",
    "lpep_dropoff_datetime",
    "PULocationID",
    "DOLocationID",
    "passenger_count",
    "trip_distance",
    "tip_amount",
    "total_amount",
]

# ── Producer ─────────────────────────────────────────────────────────────────
producer = KafkaProducer(
    bootstrap_servers=BOOTSTRAP,
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
)

# ── Load data ────────────────────────────────────────────────────────────────
df = pd.read_parquet(PARQUET_FILE, columns=COLUMNS)

# Convert datetime columns to strings so they are JSON-serialisable
for col in ["lpep_pickup_datetime", "lpep_dropoff_datetime"]:
    df[col] = df[col].astype(str)

print(f"Loaded {len(df):,} rows. Sending to topic '{TOPIC}' ...")

# ── Send ─────────────────────────────────────────────────────────────────────
t0 = time()

for record in df.to_dict(orient="records"):
    producer.send(TOPIC, value=record)

producer.flush()

t1 = time()
print(f"took {(t1 - t0):.2f} seconds")