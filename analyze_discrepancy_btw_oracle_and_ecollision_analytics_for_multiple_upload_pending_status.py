# This script takes the extract that contains collision cases that 1) have multiple upload pending status and 2) upload pending as the latest status.
# and then check this against the eCollision Analytics. What we expect to see is all these should be in eCollision Analytics,
# if they are not, these are problematic discrepancies (likely due to invalid deletions).

# Currently I am comparing only 2024 because we know that anything exist with the latest "Upload Pending" status should be in eCollision Analytics.
# But the same logic may not apply to other years since if a case receives an "Upload Pending" status AFTER the cut-off date for that year,
# the sync process will not be triggered and it will not be added to eCollision Analytics (rightfully so).

# So in order to compare years prior to 2024, I need to extract a "valid" list of reportable collision cases from Oracle, and compare that to 
# eCollision Analytics.

# To be determined, I don't think I need to make any/much modification to this to repurpose the .py file, but I will make changes of SQL
# to change what to extract.

import pandas as pd

folder_path = './output/'
start_date_str = '2024-01-01'
end_date_str = '2024-04-29'

# get oracle information
oracle_filename = 'data_dump\search_ecollision_oracle_with_repeated_cl_status_v2_output_2024-04-30.csv'
oracle_file_path = folder_path + oracle_filename
df_oracle = pd.read_csv(oracle_file_path)

# Clean and type-set CASE_NBR
df_oracle['CASE_NBR'] = df_oracle['CASE_NBR'].astype(str).str.replace(' ', '', regex=True)

# Apply date filter if both dates are provided
if start_date_str is not None and end_date_str is not None:
    # Convert CREATED_TIMESTAMP into a date format that can be compared
    df_oracle['CREATED_TIMESTAMP'] = pd.to_datetime(df_oracle['CREATED_TIMESTAMP'], format='%y-%m-%d')
    start_date = pd.to_datetime(start_date_str)
    end_date = pd.to_datetime(end_date_str)
    date_mask = (df_oracle['CREATED_TIMESTAMP'] >= start_date) & (df_oracle['CREATED_TIMESTAMP'] <= end_date)
    df_oracle = df_oracle[date_mask]

# get eCollision Analytics information
analytics_filename = 'main_extract_ecollision_analytics_data_2000_onward_snapshot_from_2024-04-29.csv'
df_analytics = pd.read_csv(analytics_filename)
df_analytics['CASE_NBR'] = df_analytics['CASE_NBR'].astype(str).str.replace(' ', '', regex=True)

# Apply date filter if both dates are provided
if start_date_str is not None and end_date_str is not None:
    # Convert OCCURENCE_TIMESTAMP into a date format that can be compared
    df_analytics['OCCURENCE_TIMESTAMP'] = pd.to_datetime(df_analytics['OCCURENCE_TIMESTAMP'], format='%Y-%m-%d %H:%M:%S')
    
    start_date = pd.to_datetime(start_date_str)
    end_date = pd.to_datetime(end_date_str)
    date_mask = (df_analytics['OCCURENCE_TIMESTAMP'] >= start_date) & (df_analytics['OCCURENCE_TIMESTAMP'] <= end_date)
    df_analytics = df_analytics[date_mask]

# Output discrepancies
# Generate the lists
unique_mask = ~df_oracle['CASE_NBR'].isin(df_analytics['CASE_NBR'])
unique_case_nbr_list = df_oracle.loc[unique_mask, 'CASE_NBR'].tolist()
common_mask = df_oracle['CASE_NBR'].isin(df_analytics['CASE_NBR'])
common_case_nbr_list = df_oracle.loc[common_mask, 'CASE_NBR'].tolist()

# Output the lists
print(f"Unique CASE_NBR in df_oracle (not in df_analytics), n={len(unique_case_nbr_list)}:", unique_case_nbr_list)
print(f"Common CASE_NBR in both df_oracle and df_analytics, n={len(common_case_nbr_list)}:", common_case_nbr_list)