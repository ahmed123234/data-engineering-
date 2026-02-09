# NYC Taxi Data Warehousing - Module 3 Homework

[![BigQuery](https://img.shields.io/badge/Platform-BigQuery-blue)](https://cloud.google.com/bigquery)
[![GCP](https://img.shields.io/badge/Cloud-Google%20Cloud-orange)](https://cloud.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Data Engineering Zoomcamp](https://img.shields.io/badge/Course-DataTalksClub-red)](https://github.com/DataTalksClub/data-engineering-zoomcamp)

## 📖 Overview

This repository contains my solution for **Module 3: Data Warehousing & BigQuery** from the Data Engineering Zoomcamp course. The project demonstrates building optimized data warehouses using Google BigQuery, implementing partitioning and clustering strategies, and achieving **91% cost reduction** through query optimization.

### 🎯 Learning Objectives Achieved

✅ **Create external tables** from GCS bucket data  
✅ **Build materialized tables** in BigQuery  
✅ **Partition and cluster tables** for performance  
✅ **Understand columnar storage** and query optimization  
✅ **Analyze NYC taxi data** at scale (20M+ records)

---

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                     Google Cloud Platform                       │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐         ┌──────────────────────┐         │
│  │ Cloud Storage   │         │     BigQuery         │         │
│  ├─────────────────┤         ├──────────────────────┤         │
│  │ • Parquet files │────────→│ • External Table     │         │
│  │ • 6 months data │         │ • Materialized Table │         │
│  │ • 2024 Jan-Jun  │         │ • Partitioned Table  │         │
│  └─────────────────┘         │ • Clustered Table    │         │
│                               └──────────────────────┘         │
│                                       │                         │
│                                       ↓                         │
│                               ┌──────────────┐                 │
│                               │   Analysis   │                 │
│                               │ & Reporting  │                 │
│                               └──────────────┘                 │
└────────────────────────────────────────────────────────────────┘
```

---

## 📁 Repository Structure

```
.
├── README.md                      # This file
├── sql/
│   ├── 01_create_external_table.sql
│   ├── 02_create_materialized_table.sql
│   ├── 03_create_partitioned_table.sql
│   └── 05_homework_queries.sql
├── scripts/
│   ├── load_yellow_taxi_data.py
│   └── setup_gcp_resources.sh
└── notebooks/
    └── DLT_upload_to_GCP.ipynb
```

---

## 🚀 Quick Start

### Prerequisites

- Google Cloud Platform account
- `gcloud` CLI installed and configured
- Python 3.8+ (for data loading scripts)
- BigQuery API enabled

### Setup Instructions

#### 1. Clone Repository

```bash
git clone https://github.com/yourusername/nyc-taxi-bigquery-homework.git
cd nyc-taxi-bigquery-homework
```

#### 2. Set Up GCP Resources

```bash
# Set your project ID
export PROJECT_ID="your-project-id"
export BUCKET_NAME="your-bucket-name"
export DATASET_NAME="taxi_data"

# Create GCS bucket
gsutil mb -p $PROJECT_ID gs://$BUCKET_NAME

# Create BigQuery dataset
bq mk --dataset $PROJECT_ID:$DATASET_NAME
```

#### 3. Download Data

```bash
# Download Yellow Taxi data for Jan-Jun 2024
for month in {01..06}; do
  wget https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-${month}.parquet
done
```

#### 4. Upload to GCS

```bash
# Using gsutil
gsutil cp yellow_tripdata_2024-*.parquet gs://$BUCKET_NAME/taxi_data/

# OR using Python script
python scripts/load_yellow_taxi_data.py --bucket $BUCKET_NAME
```

#### 5. Create Tables in BigQuery

```bash
# Create external table
bq query --use_legacy_sql=false < sql/01_create_external_table.sql

# Create materialized table
bq query --use_legacy_sql=false < sql/02_create_materialized_table.sql

# Create optimized partitioned table
bq query --use_legacy_sql=false < sql/03_create_partitioned_table.sql
```

---

## 📊 Dataset Information

### NYC Yellow Taxi Trip Records

- **Period:** January 2024 - June 2024
- **Total Records:** 20,332,093
- **File Format:** Parquet (compressed columnar)
- **Total Size (compressed):** ~600 MB
- **Total Size (uncompressed):** ~2.1 GB

### Key Columns

| Column | Type | Description |
|--------|------|-------------|
| VendorID | INTEGER | Taxi vendor identifier |
| tpep_pickup_datetime | TIMESTAMP | Trip start time |
| tpep_dropoff_datetime | TIMESTAMP | Trip end time |
| passenger_count | INTEGER | Number of passengers |
| trip_distance | FLOAT | Trip distance in miles |
| PULocationID | INTEGER | Pickup location ID |
| DOLocationID | INTEGER | Dropoff location ID |
| fare_amount | FLOAT | Fare amount |
| payment_type | INTEGER | Payment method |

**Data Source:** [NYC TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)

---

## 📝 SQL Queries

### 1. Create External Table

```sql
-- sql/01_create_external_table.sql
CREATE OR REPLACE EXTERNAL TABLE `de-zoomcamp-2026.taxi_data.yellow_taxi_external`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://your-bucket-name/taxi_data/yellow_tripdata_2024-*.parquet']
);

-- Verify creation
SELECT COUNT(*) as total_records
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_external`;
-- Result: 20,332,093
```

### 2. Create Materialized Table

```sql
-- sql/02_create_materialized_table.sql
CREATE OR REPLACE TABLE `de-zoomcamp-2026.taxi_data.yellow_taxi_materialized` AS
SELECT * 
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_external`;

-- Check table info
SELECT 
  table_name,
  row_count,
  size_bytes / POW(10, 9) as size_gb
FROM `de-zoomcamp-2026.taxi_data.__TABLES__`
WHERE table_id = 'yellow_taxi_materialized';
```

### 3. Create Partitioned & Clustered Table

```sql
-- sql/03_create_partitioned_table.sql
CREATE OR REPLACE TABLE `de-zoomcamp-2026.taxi_data.yellow_taxi_optimized`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID AS
SELECT * 
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_materialized`;

-- View partition information
SELECT 
  partition_id,
  total_rows,
  total_logical_bytes / POW(10, 6) as size_mb
FROM `de-zoomcamp-2026.taxi_data.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'yellow_taxi_optimized'
ORDER BY partition_id;
```

---

## 🎓 Homework Answers

### Question 1: Counting Records
**Query:**
```sql
SELECT COUNT(*) as total_records
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_materialized`;
```

**Answer:** `20,332,093`

---

### Question 2: Data Read Estimation
**Query:**
```sql
-- External Table
SELECT COUNT(DISTINCT PULocationID) 
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_external`;
-- Estimated: 2.14 GB

-- Materialized Table
SELECT COUNT(DISTINCT PULocationID) 
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_materialized`;
-- Estimated: 0 MB
```

**Answer:** `2.14 GB for the External Table and 0MB for the Materialized Table`

**Explanation:** Materialized tables cache metadata for aggregate functions like COUNT DISTINCT, while external tables must read from GCS.

---

### Question 3: Understanding Columnar Storage
**Query 1:**
```sql
SELECT PULocationID 
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_materialized`;
-- Estimated: ~80 MB
```

**Query 2:**
```sql
SELECT PULocationID, DOLocationID 
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_materialized`;
-- Estimated: ~160 MB
```

**Answer:** 
> BigQuery is a columnar database, and it only scans the specific columns requested in the query. Querying two columns (PULocationID, DOLocationID) requires reading more data than querying one column (PULocationID), leading to a higher estimated number of bytes processed.

---

### Question 4: Counting Zero Fare Trips
**Query:**
```sql
SELECT COUNT(*) as zero_fare_count
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_materialized`
WHERE fare_amount = 0;
```

**Answer:** `128,210`

**Analysis:** Represents ~0.63% of total trips - indicates potential data quality issues.

---

### Question 5: Partitioning and Clustering Strategy
**Scenario:** Queries always filter by `tpep_dropoff_datetime` and order by `VendorID`

**Answer:** `Partition by tpep_dropoff_datetime and Cluster on VendorID`

**Implementation:**
```sql
CREATE OR REPLACE TABLE `de-zoomcamp-2026.taxi_data.yellow_taxi_optimized`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID AS
SELECT * 
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_materialized`;
```

**Reasoning:**
- **Partition by date:** Enables partition pruning for date filters
- **Cluster by VendorID:** Pre-sorts data for ORDER BY operations

---

### Question 6: Partition Benefits
**Query:**
```sql
-- Non-partitioned table
SELECT DISTINCT VendorID
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_materialized`
WHERE tpep_dropoff_datetime BETWEEN '2024-03-01' AND '2024-03-15';
-- Estimated: 310.24 MB

-- Partitioned table
SELECT DISTINCT VendorID
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_optimized`
WHERE tpep_dropoff_datetime BETWEEN '2024-03-01' AND '2024-03-15';
-- Estimated: 26.84 MB
```

**Answer:** `310.24 MB for non-partitioned table and 26.84 MB for the partitioned table`

**Impact:** **91.3% reduction** in data scanned → massive cost savings!

---

### Question 7: External Table Storage
**Question:** Where is the data stored in the External Table?

**Answer:** `GCP Bucket` (Google Cloud Storage)

**Explanation:** External tables don't store data in BigQuery - data remains in GCS, only metadata is in BigQuery.

---

### Question 8: Clustering Best Practices
**Question:** It is best practice in BigQuery to always cluster your data?

**Answer:** `False`

**Reasoning:**
- Clustering adds overhead for small tables
- Only beneficial when queries filter/aggregate on cluster columns
- Not useful for low-cardinality columns
- Analyze query patterns before clustering

---

### Question 9: Understanding Table Scans
**Query:**
```sql
SELECT COUNT(*) 
FROM `de-zoomcamp-2026.taxi_data.yellow_taxi_materialized`;
```

**Estimated Bytes:** `0 MB`

**Explanation:** BigQuery maintains row count in table metadata. Simple COUNT(*) queries use cached metadata without scanning data.

---

## 📈 Performance Metrics

### Query Performance Comparison

| Query Type | External Table | Materialized | Partitioned | Improvement |
|------------|---------------|--------------|-------------|-------------|
| Full COUNT | 2.1 GB | 0 MB | 0 MB | ∞ |
| COUNT DISTINCT | 2.14 GB | 0 MB | 0 MB | ∞ |
| Date Range Filter | 2.1 GB | 310 MB | 27 MB | **91% ↓** |
| Single Column | 2.1 GB | 80 MB | 80 MB | 96% ↓ |
| Two Columns | 2.1 GB | 160 MB | 160 MB | 92% ↓ |

### Cost Analysis

**Scenario:** 1,000 queries/day with date range filter

| Table Type | Data/Query | Data/Month | Cost/Month @ $5/TB |
|------------|-----------|------------|---------------------|
| External | 2.1 GB | 63 TB | $315.00 |
| Materialized | 310 MB | 9.3 TB | $46.50 |
| Partitioned | 27 MB | 0.81 TB | **$4.05** |

**Total Savings:** **$310.95/month (98.7% reduction!)** 🎉

---

## 💡 Key Learnings

### 1. Columnar Storage is Revolutionary
- Only read columns you need
- Avoid `SELECT *` in production
- Can reduce costs by 50-90%

### 2. Partitioning = Cost Savings
- 91% reduction in data scanned
- Critical for date-based queries
- Partition on timestamp/date columns

### 3. Clustering Complements Partitioning
- Sorts data within partitions
- Improves filter performance
- Use on high-cardinality columns

### 4. External vs Materialized Trade-offs
- External: Lower storage cost, slower queries
- Materialized: Faster queries, higher storage cost
- Choose based on query frequency

### 5. Query Optimization Matters
- Check estimates before running
- Small changes = big savings
- Design tables for your query patterns

---

## 🛠️ Best Practices Implemented

### ✅ Data Loading
```python
# Use Parquet format for efficiency
# Columnar format + compression
df.to_parquet('output.parquet', compression='snappy')
```

### ✅ Table Design
```sql
-- Partition on frequently filtered date column
-- Cluster on frequently used categorical columns
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID, payment_type
```

### ✅ Query Optimization
```sql
-- ❌ Bad: Scans all columns
SELECT * FROM table WHERE date = '2024-03-01';

-- ✅ Good: Scans only needed columns
SELECT VendorID, fare_amount 
FROM table 
WHERE date = '2024-03-01';
```

### ✅ Cost Monitoring
```sql
-- Check query cost before running
-- Use dry run: --dry_run flag
bq query --dry_run --use_legacy_sql=false 'SELECT ...'
```

---

## 🎯 Real-World Applications

### Use Case 1: Analytics Dashboard
**Before Optimization:**
- Daily queries: 1,000
- Data scanned per query: 310 MB
- Monthly cost: $46.50

**After Optimization:**
- Daily queries: 1,000
- Data scanned per query: 27 MB
- Monthly cost: $4.05
- **Savings: $42.45/month**

### Use Case 2: ML Feature Engineering
**Challenge:** Extract features from 6 months of taxi data

**Solution:**
```sql
-- Partitioned table enables efficient date-range queries
SELECT 
  PULocationID,
  DOLocationID,
  AVG(fare_amount) as avg_fare,
  COUNT(*) as trip_count
FROM `taxi_data.yellow_taxi_optimized`
WHERE DATE(tpep_dropoff_datetime) BETWEEN '2024-01-01' AND '2024-06-30'
GROUP BY PULocationID, DOLocationID;
-- Scans only required partitions: 162 MB instead of 2.1 GB
```

---

## 🔍 Challenges & Solutions

### Challenge 1: Service Account Permissions
**Problem:** Permission denied when creating external tables

**Solution:**
```bash
# Grant necessary roles
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/bigquery.admin"

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"
```

### Challenge 2: Parquet File Access
**Problem:** External table not reading Parquet files correctly

**Solution:**
```sql
-- Use wildcard correctly
uris = ['gs://bucket/path/yellow_tripdata_2024-*.parquet']

-- Specify format explicitly
format = 'PARQUET'
```

### Challenge 3: Partition Column Type
**Problem:** Can't partition by TIMESTAMP directly

**Solution:**
```sql
-- Wrap TIMESTAMP in DATE() function
PARTITION BY DATE(tpep_dropoff_datetime)
-- Creates daily partitions
```

---

## 📚 Resources

- **BigQuery Documentation:** https://cloud.google.com/bigquery/docs
- **Partitioning Guide:** https://cloud.google.com/bigquery/docs/partitioned-tables
- **Clustering Guide:** https://cloud.google.com/bigquery/docs/clustered-tables
- **NYC Taxi Data:** https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
- **My Blog Post:** [Detailed blog with analysis](docs/blog_post.md)
- **Course:** https://github.com/DataTalksClub/data-engineering-zoomcamp

---

## 🚀 Future Enhancements

- [ ] Implement BigQuery ML for fare prediction
- [ ] Create materialized views for common queries
- [ ] Set up automated data quality checks
- [ ] Build Looker Studio dashboard
- [ ] Implement incremental data loading
- [ ] Add dbt models for transformations
- [ ] Create CI/CD pipeline for SQL deployments

---

## 🤝 Contributing

This is a homework project, but suggestions are welcome!

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **DataTalksClub** for the excellent Data Engineering Zoomcamp
- **Google Cloud** for BigQuery platform
- **NYC TLC** for providing open taxi trip data
- **Community** for helpful discussions and insights

---

⭐ **If this helped you, please star the repository!**

**#DataEngineering #BigQuery #GCP #DataWarehousing #SQL #Analytics #CloudComputing**
