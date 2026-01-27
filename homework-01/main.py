import requests
import pandas as pd

url = 'https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet'
filename = url.split('/')[-1]

# Make a GET request to the URL
response = requests.get(url, stream=True)

# Check if the request was successful
if response.status_code == 200:
    # Open the file in binary write mode
    with open(filename, 'wb') as file:
        for chunk in response.iter_content(chunk_size=8192):
            file.write(chunk)
    print(f"'{filename}' downloaded successfully.")
else:
    print(f"Failed to download '{filename}'. Status code: {response.status_code}")



url = 'https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv'
filename = url.split('/')[-1]

# Make a GET request to the URL
response = requests.get(url, stream=True)

# Check if the request was successful
if response.status_code == 200:
    # Open the file in binary write mode
    with open(filename, 'wb') as file:
        for chunk in response.iter_content(chunk_size=8192):
            file.write(chunk)
    print(f"'{filename}' downloaded successfully.")
else:
    print(f"Failed to download '{filename}'. Status code: {response.status_code}")


# Question 3:

# Load the parquet file
df_green = pd.read_parquet('green_tripdata_2025-11.parquet')

# Convert lpep_pickup_datetime to datetime objects
df_green['lpep_pickup_datetime'] = pd.to_datetime(df_green['lpep_pickup_datetime'])

# Define the date range
start_date = '2025-11-01'
end_date = '2025-12-01'

# Filter for trips within the specified date range
df_filtered_date = df_green[(df_green['lpep_pickup_datetime'] >= start_date) & (df_green['lpep_pickup_datetime'] < end_date)]

# Filter for trips with trip_distance <= 1 mile
df_short_trips = df_filtered_date[df_filtered_date['trip_distance'] <= 1]

# Count the number of such trips
num_short_trips = len(df_short_trips)

print(f"Number of trips with trip_distance <= 1 mile in November 2025: {num_short_trips}")



# Question 4:

# Filter out trips with trip_distance >= 100 miles (potential data errors)
df_filtered_distance = df_green[df_green['trip_distance'] < 100]

# Extract the pickup date (without time) and store it in a new column
df_filtered_distance['pickup_date'] = df_filtered_distance['lpep_pickup_datetime'].dt.date

# Group by pickup_date and find the maximum trip_distance for each day
longest_trip_per_day = df_filtered_distance.groupby('pickup_date')['trip_distance'].max().reset_index()

# Find the day with the overall longest trip distance
day_with_longest_trip = longest_trip_per_day.loc[longest_trip_per_day['trip_distance'].idxmax()]

print(f"The pickup day with the longest trip distance (less than 100 miles) is: {day_with_longest_trip['pickup_date']}")
print(f"The longest trip distance on that day was: {day_with_longest_trip['trip_distance']} miles")



# Question 5:

# Load the taxi zone lookup data
df_zones = pd.read_csv('taxi_zone_lookup.csv')

# Define the target date
target_date = '2025-11-18'

# Filter df_green for trips on the target date
df_trips_on_target_date = df_green[
    (df_green['lpep_pickup_datetime'].dt.date == pd.to_datetime(target_date).date())
].copy()

# Merge with df_zones to get location names
df_merged = pd.merge(
    df_trips_on_target_date,
    df_zones,
    left_on='PULocationID',
    right_on='LocationID',
    how='left'
)

# Group by Zone and sum total_amount
total_amount_per_zone = df_merged.groupby('Zone')['total_amount'].sum().reset_index()

# Find the zone with the largest total_amount
largest_zone = total_amount_per_zone.loc[total_amount_per_zone['total_amount'].idxmax()]

print(f"The pickup zone with the largest total_amount on {target_date} is: {largest_zone['Zone']}")
print(f"Total amount: {largest_zone['total_amount']:.2f}")


# Qustion 6:

# Find the LocationID for 'East Harlem North'
eh_north_location_id = df_zones[df_zones['Zone'] == 'East Harlem North']['LocationID'].iloc[0]

# Define the date range for November 2025
start_date_nov = '2025-11-01'
end_date_nov = '2025-12-01'

# Filter df_green for trips from 'East Harlem North' in November 2025
df_eh_north_pickup_nov = df_green[
    (df_green['PULocationID'] == eh_north_location_id) &
    (df_green['lpep_pickup_datetime'] >= start_date_nov) &
    (df_green['lpep_pickup_datetime'] < end_date_nov)
].copy()

# Merge with df_zones to get drop-off zone names
df_merged_dropoff = pd.merge(
    df_eh_north_pickup_nov,
    df_zones[['LocationID', 'Zone']],
    left_on='DOLocationID',
    right_on='LocationID',
    how='left',
    suffixes=('_pickup', '_dropoff')
)

# Group by drop-off Zone and find the maximum tip_amount
# Corrected: Use 'Zone' instead of 'Zone_dropoff'
max_tip_per_dropoff_zone = df_merged_dropoff.groupby('Zone')['tip_amount'].max().reset_index()

# Find the drop-off zone with the largest tip
# Corrected: Use 'Zone' instead of 'Zone_dropoff'
largest_tip_dropoff_zone = max_tip_per_dropoff_zone.loc[max_tip_per_dropoff_zone['tip_amount'].idxmax()]

print(f"The drop-off zone with the largest tip from 'East Harlem North' pickups in November 2025 is: {largest_tip_dropoff_zone['Zone']}")
print(f"Largest tip amount: {largest_tip_dropoff_zone['tip_amount']:.2f}")
