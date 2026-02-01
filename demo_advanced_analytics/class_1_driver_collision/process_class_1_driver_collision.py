import pandas as pd
import numpy as np

print("=" * 80)
print("Processing Class 1 Driver Collision Data")
print("=" * 80)

# Step 1: Read alberta_collision_2024-2025.csv
print("\n[Step 1] Reading alberta_collision_2024-2025.csv...")
df_col_ab = pd.read_csv('alberta_collision_2024-2025.csv', low_memory=False)
print(f"  - Loaded {len(df_col_ab):,} rows")
print(f"  - Unique CASE_NBR: {df_col_ab['CASE_NBR'].nunique():,}")

# Step 2: Aggregate df_col_ab by CASE_NBR
print("\n[Step 2] Aggregating df_col_ab by CASE_NBR...")

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

df_col_ab = df_col_ab.groupby('CASE_NBR', as_index=False).agg(agg_funcs)
print(f"  - Aggregated to {len(df_col_ab):,} unique CASE_NBR rows")

# Step 3: Read output_collision_class_1_*.csv
print("\n[Step 3] Reading output_collision_class_1_20260129102331_2024-04-01_to_2025-09-30.csv...")
df_col_class1 = pd.read_csv('output_collision_class_1_20260129102331_2024-04-01_to_2025-09-30.csv', low_memory=False)
print(f"  - Loaded {len(df_col_class1):,} rows")
print(f"  - Unique CASE_NBR: {df_col_class1['CASE_NBR'].nunique():,}")

# Aggregate to unique CASE_NBR, keep only CASE_NBR and DRIVER_ACTION_ID
df_col_class1 = df_col_class1.groupby('CASE_NBR', as_index=False).agg({'DRIVER_ACTION_ID': 'first'})
print(f"  - Aggregated to {len(df_col_class1):,} unique CASE_NBR rows")

# Step 4: Merge df_col_class1 and df_col_ab, keeping only rows in df_col_class1
print("\n[Step 4] Merging df_col_class1 and df_col_ab on CASE_NBR...")
df_col_class1 = df_col_class1.merge(df_col_ab, on='CASE_NBR', how='inner')
print(f"  - Merged result: {len(df_col_class1):,} rows")

# Rename Flag_ParkedVehicle to FLAG_PARKED_VEHICLE
df_col_class1.rename(columns={'Flag_ParkedVehicle': 'FLAG_PARKED_VEHICLE'}, inplace=True)

# Display summary
print("\n" + "=" * 80)
print("FINAL RESULT")
print("=" * 80)
print(f"Total rows: {len(df_col_class1):,}")
print(f"Columns: {list(df_col_class1.columns)}")
print(f"\nFirst 10 rows:")
print(df_col_class1.head(10))

# Save output
output_file = 'processed_class_1_driver_collision.csv'
df_col_class1.to_csv(output_file, index=False)
print(f"\n✓ Saved to {output_file}")
