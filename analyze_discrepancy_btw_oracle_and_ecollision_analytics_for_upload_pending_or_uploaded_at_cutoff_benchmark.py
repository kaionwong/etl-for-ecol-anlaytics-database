import pandas as pd
from datetime import datetime
import numpy as np
import re
import time  # Import time for timing operations
import helper as helper

# Helper function to clean PFN file number
def clean_pfn_file_nbr(value):
    if pd.isna(value):  # Handle NaN or None values
        return np.nan
    
    # Ensure the value is a string
    value = str(value)
    # Remove any non-alphanumeric characters
    value = re.sub(r'[^a-zA-Z0-9]', '', value)
    # Remove leading zeros
    value = value.lstrip('0')
    
    # Convert to int if it's a numeric value, otherwise keep as string
    if value.isdigit():
        return int(value)
    return value

helper.pandas_output_setting()

# Start measuring total script execution time
overall_start_time = time.time()

folder_path = './output/'
start_date_str = '2011-01-01'
end_date_str = '2011-12-31'
buffer_days = 0
save_switch = False
date_var_used_for_df_oracle = 'OCCURENCE_TIMESTAMP'
date_var_used_for_df_analytics = 'OCCURENCE_TIMESTAMP'

# Time the reading of Oracle CSV file
start_time = time.time()
oracle_filename = 'data\extract_collision_oracle_with_upload_pending_or_uploaded_on_cutoff_date_2024-08-22.csv'
df_oracle = pd.read_csv(oracle_filename, encoding='windows-1252')
elapsed_time = time.time() - start_time
print(f"Reading Oracle CSV took: {elapsed_time:.4f} seconds")

# Cleaning and processing Oracle DataFrame
start_time = time.time()
df_oracle['CASE_NBR'] = df_oracle['CASE_NBR'].astype(str).str.replace(' ', '', regex=True)
df_oracle = df_oracle[df_oracle['VALID_AT_CUTOFF_FLAG'] == 1]

df_oracle['OCCURENCE_TIMESTAMP'].fillna(df_oracle['REPORTED_TIMESTAMP'], inplace=True)
df_oracle['CASE_YEAR'].fillna(df_oracle['CREATED_YEAR'], inplace=True)
df_oracle = df_oracle.replace([np.inf, -np.inf], np.nan).dropna(subset=['CASE_YEAR'])
df_oracle['CASE_YEAR'] = df_oracle['CASE_YEAR'].astype(int)

df_oracle['PFN_FILE_NBR_CLEANED'] = df_oracle['PFN_FILE_NBR'].apply(clean_pfn_file_nbr)

# Apply date filter if both dates are provided
if start_date_str and end_date_str:
    df_oracle[date_var_used_for_df_oracle] = pd.to_datetime(df_oracle[date_var_used_for_df_oracle], format='%y-%m-%d')
    start_date = pd.to_datetime(start_date_str)
    end_date = pd.to_datetime(end_date_str)
    date_mask = (df_oracle[date_var_used_for_df_oracle] >= start_date) & (df_oracle[date_var_used_for_df_oracle] <= end_date)
    df_oracle = df_oracle[date_mask]
elapsed_time = time.time() - start_time
print(f"Processing Oracle data took: {elapsed_time:.4f} seconds")

# Time the reading of Analytics CSV file
start_time = time.time()
analytics_filename = 'data\main_extract_ecollision_analytics_data_2000_onward_snapshot_from_2024-08-22.csv'
df_analytics = pd.read_csv(analytics_filename)
elapsed_time = time.time() - start_time
print(f"Reading Analytics CSV took: {elapsed_time:.4f} seconds")

# Cleaning and processing Analytics DataFrame
start_time = time.time()
df_analytics['CASE_NBR'] = df_analytics['CASE_NBR'].astype(str).str.replace(' ', '', regex=True)
df_analytics = df_analytics.replace([np.inf, -np.inf], np.nan).dropna(subset=['CASE_YEAR'])
df_analytics['CASE_YEAR'] = df_analytics['CASE_YEAR'].astype(int)
df_analytics['PFN_FILE_NBR_CLEANED'] = df_analytics['PFN_FILE_NBR'].apply(clean_pfn_file_nbr)

# Apply date filter if both dates are provided
if start_date_str and end_date_str:
    df_analytics[date_var_used_for_df_analytics] = pd.to_datetime(df_analytics[date_var_used_for_df_analytics], format='%Y-%m-%d %H:%M:%S')
    start_date = pd.to_datetime(start_date_str)
    if buffer_days > 0:
        buffered_end_date = end_date + pd.Timedelta(days=buffer_days)
        date_mask = (df_analytics[date_var_used_for_df_analytics] >= start_date) & (df_analytics[date_var_used_for_df_analytics] <= buffered_end_date)
    else:
        date_mask = (df_analytics[date_var_used_for_df_analytics] >= start_date) & (df_analytics[date_var_used_for_df_analytics] <= end_date)
    df_analytics = df_analytics[date_mask]
elapsed_time = time.time() - start_time
print(f"Processing Analytics data took: {elapsed_time:.4f} seconds")

# Time the discrepancy analysis
start_time = time.time()

# Method #1 - CASE_NBR comparison
unique_mask1 = ~df_oracle['CASE_NBR'].isin(df_analytics['CASE_NBR'])
unique_case_nbr_list1 = df_oracle.loc[unique_mask1, 'CASE_NBR'].tolist()
common_mask1 = df_oracle['CASE_NBR'].isin(df_analytics['CASE_NBR'])
common_case_nbr_list1 = df_oracle.loc[common_mask1, 'CASE_NBR'].tolist()

unique_mask11 = ~df_analytics['CASE_NBR'].isin(df_oracle['CASE_NBR'])
unique_case_nbr_list11 = df_analytics.loc[unique_mask11, 'CASE_NBR'].tolist()

# Method #2 - CASE_KEY comparison
df_oracle['CASE_KEY'] = df_oracle['CASE_NBR'].astype(str) + '_' + df_oracle['CASE_YEAR'].astype(str)
df_analytics['CASE_KEY'] = df_analytics['CASE_NBR'].astype(str) + '_' + df_analytics['CASE_YEAR'].astype(str)

unique_mask2 = ~df_oracle['CASE_KEY'].isin(df_analytics['CASE_KEY'])
unique_case_key_list2 = df_oracle.loc[unique_mask2, 'CASE_KEY'].tolist()

common_mask2 = df_oracle['CASE_KEY'].isin(df_analytics['CASE_KEY'])
common_case_key_list2 = df_oracle.loc[common_mask2, 'CASE_KEY'].tolist()

unique_mask22 = ~df_analytics['CASE_KEY'].isin(df_oracle['CASE_KEY'])
unique_case_key_list22 = df_analytics.loc[unique_mask22, 'CASE_KEY'].tolist()

elapsed_time = time.time() - start_time
print(f"Discrepancy analysis took: {elapsed_time:.4f} seconds")

# End total execution time
overall_elapsed_time = time.time() - overall_start_time
print(f"Total script execution time: {overall_elapsed_time:.4f} seconds")