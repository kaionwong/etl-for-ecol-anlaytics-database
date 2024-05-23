# This script takes the extract that contains collision cases that 1) have multiple upload pending status and 2) upload pending as the latest status.
# and then check this against the eCollision Analytics. What we expect to see is all these should be in eCollision Analytics,
# if they are not, these are problematic discrepancies (likely due to invalid deletions).

import pandas as pd

folder_path = './output/'
start_date = '2024-01-01'
end_date = '2024-04-29'

# get oracle information
oracle_filename = 'search_ecollision_oracle_with_repeated_cl_status_v2_output_2024-04-30.csv'
oracle_file_path = folder_path + oracle_filename
df_oracle = pd.read_csv(oracle_file_path)

# Clean and type-set CASE_NBR
df_oracle['CASE_NBR'] = df_oracle['CASE_NBR'].astype(str).str.replace(' ', '', regex=True)

# Apply date filter if both dates are provided
if start_date is not None and end_date is not None:
    # Convert CREATED_TIMESTAMP into a date format that can be compared
    df_oracle['CREATED_TIMESTAMP'] = pd.to_datetime(df_oracle['CREATED_TIMESTAMP'], format='%y-%m-%d')
    start_date = pd.to_datetime(start_date)
    end_date = pd.to_datetime(end_date)
    date_mask = (df_oracle['CREATED_TIMESTAMP'] >= start_date) & (df_oracle['CREATED_TIMESTAMP'] <= end_date)
    df_oracle = df_oracle[date_mask]

# get eCollision Analytics information
analytics_filename = 'main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-04-29.csv'
df_analytics = pd.read_csv(analytics_filename)
df_analytics['CASE_NBR'] = df_analytics['CASE_NBR'].astype(str).str.replace(' ', '', regex=True)

# Output discrepancies
# Generate the lists
unique_mask = ~df_oracle['CASE_NBR'].isin(df_analytics['CASE_NBR'])
unique_case_nbr_list = df_oracle.loc[unique_mask, 'CASE_NBR'].tolist()
common_mask = df_oracle['CASE_NBR'].isin(df_analytics['CASE_NBR'])
common_case_nbr_list = df_oracle.loc[common_mask, 'CASE_NBR'].tolist()

# Output the lists
print(f"Unique CASE_NBR in df_oracle (not in df_analytics), n={len(unique_case_nbr_list)}:", unique_case_nbr_list)
print(f"Common CASE_NBR in both df_oracle and df_analytics, n={len(common_case_nbr_list)}:", common_case_nbr_list)