"""
Module 6 Homework — Batch Processing with Spark
Data Engineering Zoomcamp 2026
"""

import os
import urllib.request
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_date, unix_timestamp, max as spark_max

# ──────────────────────────────────────────────────────────
# Config
# ──────────────────────────────────────────────────────────
PARQUET_URL  = "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-11.parquet"
ZONES_URL    = "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"
PARQUET_FILE = "data/yellow_tripdata_2025-11.parquet"
ZONES_FILE   = "data/taxi_zone_lookup.csv"
OUTPUT_DIR   = "output/yellow_2025_11_repartitioned"


# ──────────────────────────────────────────────────────────
# Download helpers
# ──────────────────────────────────────────────────────────
def download_if_missing(url: str, dest: str) -> None:
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    if not os.path.exists(dest):
        print(f"Downloading {dest} ...")
        urllib.request.urlretrieve(url, dest)
        print(f"  Saved → {dest}")
    else:
        print(f"  Already exists: {dest}")


# ──────────────────────────────────────────────────────────
# Spark session
# ──────────────────────────────────────────────────────────
spark = SparkSession.builder \
    .master("local[*]") \
    .appName("de-zoomcamp-hw6") \
    .config("spark.sql.shuffle.partitions", "4") \
    .getOrCreate()

spark.sparkContext.setLogLevel("WARN")


# ──────────────────────────────────────────────────────────
# Q1 — Spark version
# ──────────────────────────────────────────────────────────
print("\n" + "="*55)
print(f"  Q1 | Spark version: {spark.version}")
print("="*55)


# ──────────────────────────────────────────────────────────
# Download data
# ──────────────────────────────────────────────────────────
download_if_missing(PARQUET_URL, PARQUET_FILE)
download_if_missing(ZONES_URL,   ZONES_FILE)


# ──────────────────────────────────────────────────────────
# Read raw data
# ──────────────────────────────────────────────────────────
df = spark.read.parquet(PARQUET_FILE)
print(f"\nTotal rows loaded: {df.count():,}")
df.printSchema()


# ──────────────────────────────────────────────────────────
# Q2 — Repartition to 4 and measure average file size
# ──────────────────────────────────────────────────────────
os.makedirs(OUTPUT_DIR, exist_ok=True)
df.repartition(4).write.mode("overwrite").parquet(OUTPUT_DIR)

parquet_files = [f for f in os.listdir(OUTPUT_DIR) if f.endswith(".parquet")]
sizes_mb      = [os.path.getsize(os.path.join(OUTPUT_DIR, f)) / (1024 ** 2)
                 for f in parquet_files]
avg_mb        = sum(sizes_mb) / len(sizes_mb)

print("\n" + "="*55)
print(f"  Q2 | Repartitioned into {len(parquet_files)} parquet files")
for name, size in zip(parquet_files, sizes_mb):
    print(f"       {name}: {size:.2f} MB")
print(f"  Q2 | Average size → {avg_mb:.2f} MB")
print("="*55)


# ──────────────────────────────────────────────────────────
# Q3 — Count trips on November 15, 2025
# ──────────────────────────────────────────────────────────
count_nov15 = (
    df.filter(to_date(col("tpep_pickup_datetime")) == "2025-11-15")
      .count()
)

print("\n" + "="*55)
print(f"  Q3 | Trips on 2025-11-15: {count_nov15:,}")
print("="*55)


# ──────────────────────────────────────────────────────────
# Q4 — Longest trip in hours
# ──────────────────────────────────────────────────────────
df_duration = df.withColumn(
    "trip_duration_hours",
    (unix_timestamp("tpep_dropoff_datetime") -
     unix_timestamp("tpep_pickup_datetime")) / 3600.0
)

max_hours = (
    df_duration
    .select(spark_max("trip_duration_hours"))
    .collect()[0][0]
)

print("\n" + "="*55)
print(f"  Q4 | Longest trip: {max_hours:.1f} hours")
print("="*55)


# ──────────────────────────────────────────────────────────
# Q5 — Spark UI port (informational, no code needed)
# ──────────────────────────────────────────────────────────
print("\n" + "="*55)
print("  Q5 | Spark UI port: 4040")
print("       Visit → http://localhost:4040")
print("="*55)


# ──────────────────────────────────────────────────────────
# Q6 — Least frequent pickup zone
# ──────────────────────────────────────────────────────────
zones = spark.read.option("header", "true").csv(ZONES_FILE)

df.createOrReplaceTempView("trips")
zones.createOrReplaceTempView("zones")

result = spark.sql("""
    SELECT
        z.Zone,
        COUNT(*) AS pickup_count
    FROM trips   t
    JOIN zones   z
      ON CAST(t.PULocationID AS INT) = CAST(z.LocationID AS INT)
    GROUP BY z.Zone
    ORDER BY pickup_count ASC
    LIMIT 10
""")

print("\n" + "="*55)
print("  Q6 | Least frequent pickup zones:")
result.show(truncate=False)
print("="*55)

spark.stop()
print("\nDone ✅")
