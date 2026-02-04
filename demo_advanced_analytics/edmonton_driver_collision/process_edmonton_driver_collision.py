import pandas as pd
import numpy as np

# Driver Action ID to Description Mapping
DRIVER_ACTION_MAPPING = {
    155: 'Driving Properly',
    156: 'Stop Sign Violation',
    157: 'Yield Sign Violation',
    158: 'Fail To Yield ROW Uncontrolled',
    159: 'Fail To Yield ROW Pedestrian',
    160: 'Followed Too Closely',
    161: 'Parked Vehicle',
    162: 'Backed Unsafely',
    163: 'Left Turn Across Path',
    164: 'Improper Lane Change',
    165: 'Disobey Traffic Signal',
    166: 'Ran Off Road',
    167: 'Improper Turn',
    168: 'Left of Centre',
    169: 'Improper Passing',
    -10: 'Blank',
    170: 'Other/Specify',
    171: 'Unknown'
}

print("=" * 80)
print("Processing Edmonton Driver Collision Data")
print("=" * 80)

# Step 1: Read edmonton_collision_2000-2026.csv
print("\n[Step 1] Reading edmonton_collision_2000-2026.csv...")
df_edmonton = pd.read_csv('edmonton_collision_2000-2026.csv', low_memory=False)
print(f"  - Loaded {len(df_edmonton):,} rows")
print(f"  - Unique CASE_NBR: {df_edmonton['CASE_NBR'].nunique():,}")

# Step 2: Deduplicate by CASE_NBR using aggregation
print("\n[Step 2] Deduplicating by CASE_NBR...")

# Define aggregation functions for each column
agg_funcs = {
    'CASE_YEAR': 'first',
    'COLLISION_SEVERITY': 'first',
    'LOC_GPS_LAT': 'first',
    'LOC_GPS_LONG': 'first',
    'Flag_ParkedVehicle': lambda x: 'Y' if 'Y' in x.values else 'N',
    'VEHICLES_NBR': 'first',
    'INJURED_NBR': 'first',
    'FATALITIES_NBR': 'first',
    'OCCURENCE_TIMESTRING': 'first'
}

df_edmonton = df_edmonton.groupby('CASE_NBR', as_index=False).agg(agg_funcs)
print(f"  - Deduplicated to {len(df_edmonton):,} unique CASE_NBR rows")

# Step 3: Rename Flag_ParkedVehicle to FLAG_PARKED_VEHICLE
df_edmonton.rename(columns={'Flag_ParkedVehicle': 'FLAG_PARKED_VEHICLE'}, inplace=True)

# Display summary
print("\n" + "=" * 80)
print("FINAL RESULT")
print("=" * 80)
print(f"Total rows: {len(df_edmonton):,}")
print(f"Columns: {list(df_edmonton.columns)}")
print(f"\nFirst 10 rows:")
print(df_edmonton.head(10))

# Save output
output_file = 'processed_edmonton_driver_collision.csv'
df_edmonton.to_csv(output_file, index=False)
print(f"\n✓ Saved to {output_file}")
