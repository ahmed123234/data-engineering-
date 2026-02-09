# Set your project ID
export PROJECT_ID="your-project-id"
export BUCKET_NAME="your-bucket-name"
export DATASET_NAME="taxi_data"

# Create GCS bucket
gsutil mb -p $PROJECT_ID gs://$BUCKET_NAME

# Create BigQuery dataset
bq mk --dataset $PROJECT_ID:$DATASET_NAME
