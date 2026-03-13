# Module 6 — Batch Processing with Spark

## Setup
```bash
# Install Java (required for Spark)
sudo apt-get install default-jdk -y   # Linux
brew install openjdk                  # macOS

# Install PySpark
pip install -r requirements.txt

# Run homework
python homework.py
```

## Answers

| # | Question                             | Answer                                          |
|---|--------------------------------------|-------------------------------------------------|
| 1 | Spark version                        | `3.5.3`                                         |
| 2 | Avg parquet file size (4 partitions) | `~25 MB`                                        |
| 3 | Trips on November 15, 2025           | `62,610`                                        |
| 4 | Longest trip (hours)                 | `90.6`                                          |
| 5 | Spark UI port                        | `4040`                                          |
| 6 | Least frequent pickup zone           | `Governor's Island/Ellis Island/Liberty Island` |

## Notes

- Data is downloaded automatically on first run into `data/`
- Repartitioned output lands in `output/yellow_2025_11_repartitioned/`
- Spark UI is live at http://localhost:4040 while the script runs
- `data/` and `output/` are gitignored — do not commit raw parquet files
