"""
Q3: Kafka Consumer - count trips with trip_distance > 5.0
Run: python consumer.py
"""

import json
from kafka import KafkaConsumer

TOPIC     = "green-trips"
BOOTSTRAP = "localhost:9092"

consumer = KafkaConsumer(
    TOPIC,
    bootstrap_servers=BOOTSTRAP,
    auto_offset_reset="earliest",          # read from the very beginning
    value_deserializer=lambda v: json.loads(v.decode("utf-8")),
    consumer_timeout_ms=10_000,            # stop after 10 s of silence
)

total = 0
count = 0

for msg in consumer:
    trip = msg.value
    total += 1
    if trip.get("trip_distance", 0) > 5.0:
        count += 1

print(f"Total trips consumed : {total:,}")
print(f"Trips with distance > 5 km : {count:,}")