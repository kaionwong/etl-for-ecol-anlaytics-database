# This script takes the extract that contains flag about whether a case has "upload pending" or "uploaded" status on the cut-off date. This is
# a more wholesome comparison than other eCollision Oracle vs. eCollision Analytics comparisons. The numbers should be close to 1:1
# between eCollision Oracle and eCollision Analytics. The discrepancies in either side present a potential problem that needs
# to be investigated.
# Caveat: there may be a small number of discrepancies that are expected due to slight variations of how cases are added/removed in
# practice.

import pandas as pd
from datetime import datetime
import numpy as np
import re
import helper_generic as helper
import os

# Helper function
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

# Main code
folder_path = './etl-for-ecol-anlaytics-database/output/'
# start_date_str = '2007-01-01'
# end_date_str = '2025-12-31' # make sure this end date is on or earlier than both oracle_filename and analytics_filename (shown by the date in filenames)
# buffer_days = 0 # WARNING: if buffer date is larger than 0, this number of days will be added to eCollision Analytics end date to give a buffer since it may have 1 to multiple day (over weekend) for eCollision Oracle changes to be updated in eCollision Analytics; can also use this as a more loose buffer to allow a gap for Analytics' updates
#                 # use buffer_days > 0 only if you are analyzing current year to accomodate for the gap in Oracle's updates to Analytics; for previous years, always set buffer_days = 0
data_file_suffix_date = '2025-02-21'
save_switch = True # WARNING: This will overwrite files with the same filename if the save_switch is True
date_var_used_for_df_oracle = 'OCCURENCE_TIMESTAMP' # options are: 'OCCURENCE_TIMESTAMP', 'REPORTED_TIMESTAMP', 'EFFECTIVE_DATE'
date_var_used_for_df_analytics = 'OCCURENCE_TIMESTAMP' # options are: 'OCCURENCE_TIMESTAMP', 'REPORTED_TIMESTAMP'

# get oracle information
oracle_filename = os.path.join(os.getcwd(), 'etl-for-ecol-anlaytics-database', 'data', 
                               f'extract_collision_oracle_with_uploaded_without_cutoff_date_{data_file_suffix_date}.csv')
# df_oracle = pd.read_csv(oracle_file_path, encoding='windows-1252')
df_oracle = pd.read_csv(oracle_filename, encoding='windows-1252')

# Clean and type-set CASE_NBR
df_oracle['CASE_NBR'] = df_oracle['CASE_NBR'].astype(str).str.replace(' ', '', regex=True)
df_oracle = df_oracle[df_oracle['VALID_AT_CUTOFF_FLAG']==1]
df_oracle_slice = df_oracle[df_oracle['CASE_NBR'] == '1446310']

# Impute OCCURENCE_TIMESTAMP with REPORTED_TIMESTAMP is OCCURENCE_TIMESTAMP is NaN
df_oracle['OCCURENCE_TIMESTAMP'].fillna(df_oracle['REPORTED_TIMESTAMP'], inplace=True)
df_oracle['CASE_YEAR'].fillna(df_oracle['CREATED_YEAR'], inplace=True)

df_oracle = df_oracle.replace([np.inf, -np.inf], np.nan).dropna(subset=['CASE_YEAR'])
df_oracle['CASE_YEAR'] = df_oracle['CASE_YEAR'].astype(int)

df_oracle['PFN_FILE_NBR_CLEANED'] = df_oracle['PFN_FILE_NBR'].apply(clean_pfn_file_nbr)

# Apply date filter if both dates are provided
# if start_date_str is not None and end_date_str is not None:
#     # Convert date_var_used_for_df_oracle into a date format that can be compared
#     # df_oracle[date_var_used_for_df_oracle] = pd.to_datetime(df_oracle[date_var_used_for_df_oracle], format='%y-%m-%d')
#     df_oracle[date_var_used_for_df_oracle] = pd.to_datetime(df_oracle[date_var_used_for_df_oracle], errors='coerce')
#     start_date = pd.to_datetime(start_date_str)
#     end_date = pd.to_datetime(end_date_str)
#     date_mask = (df_oracle[date_var_used_for_df_oracle] >= start_date) & (df_oracle[date_var_used_for_df_oracle] <= end_date)
#     df_oracle = df_oracle[date_mask]

# get eCollision Analytics information
analytics_filename = os.path.join(os.getcwd(), 'etl-for-ecol-anlaytics-database', 'data', 
                                  f'main_extract_ecollision_analytics_data_2000_onward_snapshot_from_{data_file_suffix_date}.csv')

df_analytics = pd.read_csv(analytics_filename)
df_analytics['CASE_NBR'] = df_analytics['CASE_NBR'].astype(str).str.replace(' ', '', regex=True)

df_analytics = df_analytics.replace([np.inf, -np.inf], np.nan).dropna(subset=['CASE_YEAR'])
df_analytics['CASE_YEAR'] = df_analytics['CASE_YEAR'].astype(int)

df_analytics['PFN_FILE_NBR_CLEANED'] = df_analytics['PFN_FILE_NBR'].apply(clean_pfn_file_nbr)

# Apply date filter if both dates are provided
# if start_date_str is not None and end_date_str is not None:
#     # Convert OCCURENCE_TIMESTAMP into a date format that can be compared
#     df_analytics[date_var_used_for_df_analytics] = pd.to_datetime(df_analytics[date_var_used_for_df_analytics], format='%Y-%m-%d %H:%M:%S')
#     start_date = pd.to_datetime(start_date_str)
    
#     if buffer_days > 0:
#         end_date = pd.to_datetime(end_date_str)
#         buffered_end_date = end_date + pd.Timedelta(days=buffer_days)
#         date_mask = (df_analytics[date_var_used_for_df_analytics] >= start_date) & (df_analytics[date_var_used_for_df_analytics] <= buffered_end_date)
#         df_analytics = df_analytics[date_mask]
    
#     else:
#         end_date = pd.to_datetime(end_date_str)
#         date_mask = (df_analytics[date_var_used_for_df_analytics] >= start_date) & (df_analytics[date_var_used_for_df_analytics] <= end_date)
#         df_analytics = df_analytics[date_mask]

# Output discrepancies - #1 this compares simply if there is a descrepancies of case_number between two dataframes
# .. caveat - sometimes a case_number exists in both dfs can still be missing. How? Here is an example:
# .. case_number = 136571 exists in eCollision Oracle, and it is a 2012 collision. The same case_number exists in eCollision Analytics, but
# .. it is a 2001 case, thus the supposed 2012 case from Oracle is still missing in eCollision Analytics.
# Generate the lists

unique_mask1 = ~df_oracle['CASE_NBR'].isin(df_analytics['CASE_NBR'])
unique_case_nbr_list1 = df_oracle.loc[unique_mask1, 'CASE_NBR'].tolist()
common_mask1 = df_oracle['CASE_NBR'].isin(df_analytics['CASE_NBR'])
common_case_nbr_list1 = df_oracle.loc[common_mask1, 'CASE_NBR'].tolist()
df_oracle_discrepancy1 = df_oracle[df_oracle['CASE_NBR'].isin(unique_case_nbr_list1)]

unique_mask11 = ~df_analytics['CASE_NBR'].isin(df_oracle['CASE_NBR'])
unique_case_nbr_list11 = df_analytics.loc[unique_mask11, 'CASE_NBR'].tolist()
df_analytics_discrepancy1 = df_analytics[df_analytics['CASE_NBR'].isin(unique_case_nbr_list11)]

# Output the lists
print(f"Method #1: Unique CASE_NBR in df_oracle (not in df_analytics), n={len(unique_case_nbr_list1)}:", unique_case_nbr_list1)
print(f"Method #1: Unique CASE_NBR in df_analytics (not in df_oracle), n={len(unique_case_nbr_list11)}:", unique_case_nbr_list11)
print(f"Method #1: Common CASE_NBR in both df_oracle and df_analytics, n={len(common_case_nbr_list1)}:", common_case_nbr_list1)
print('Method #1: Discrepancy (missing in Analytics) volume by year:', df_oracle_discrepancy1['CASE_YEAR'].value_counts().sort_index())
print('Method #1: Discrepancy (missing in Oracle) volume by year:', df_analytics_discrepancy1['CASE_YEAR'].value_counts().sort_index())

# Save the list
now = datetime.now()
timestamp_str = now.strftime('%Y-%m-%d_%H-%M-%S')

if save_switch:    
    # output_filename = f'method1_unique_case_number_from_oracle_not_in_ecol_analytics_{start_date_str}_{end_date_str}_at_{timestamp_str}.csv'
    output_filename = f'method1_unique_case_number_from_oracle_not_in_ecol_analytics_at_{timestamp_str}.csv'
    output_file_path = folder_path + output_filename
    df_oracle_discrepancy1.to_csv(output_file_path, index=False, header=True)

# Output discrepancies - #2 this compares both the case_number and collision_id in both dataframes
# .. missing is defined as the case not in eCollision Analytics if either case_number and/or collision_id is missing when
# .. comparing the two dataframes

# Create composite keys; options below
# Method #1 of 'CASE_KEY' definition with CASE_NBR and COLLISION_ID
df_oracle['CASE_KEY'] = df_oracle['CASE_NBR'].astype(str) + '_' + df_oracle['COLLISION_ID'].astype(str)
df_analytics['CASE_KEY'] = df_analytics['CASE_NBR'].astype(str) + '_' + df_analytics['COLLISION_ID'].astype(str)

# Method #2 of 'CASE_KEY' definition with CASE_NBR and CASE_YEAR (this returns the exact same result as Method #1)
# df_oracle['CASE_KEY'] = df_oracle['CASE_NBR'].astype(str) + '_' + df_oracle['CASE_YEAR'].astype(str)
# df_analytics['CASE_KEY'] = df_analytics['CASE_NBR'].astype(str) + '_' + df_analytics['CASE_YEAR'].astype(str)

# Method #3 of 'CASE_KEY' definition with CASE_NBR and PFN_FILE_NBR_CLEANED
# Don't use Method #3 since sometimes the police file numbers may have typos even though the same case_number and occurence time are the same between the two databases
# df_oracle['CASE_KEY'] = df_oracle['CASE_NBR'].astype(str) + '_' + df_oracle['PFN_FILE_NBR_CLEANED'].astype(str)
# df_analytics['CASE_KEY'] = df_analytics['CASE_NBR'].astype(str) + '_' + df_analytics['PFN_FILE_NBR_CLEANED'].astype(str)

# Find unique and common cases based on the composite key
unique_mask2 = ~df_oracle['CASE_KEY'].isin(df_analytics['CASE_KEY'])
unique_case_key_list2 = df_oracle.loc[unique_mask2, 'CASE_KEY'].tolist()
common_mask2 = df_oracle['CASE_KEY'].isin(df_analytics['CASE_KEY'])
common_case_key_list2 = df_oracle.loc[common_mask2, 'CASE_KEY'].tolist()
df_oracle_discrepancy2 = df_oracle[df_oracle['CASE_KEY'].isin(unique_case_key_list2)]

unique_mask22 = ~df_analytics['CASE_KEY'].isin(df_oracle['CASE_KEY'])
unique_case_key_list22 = df_analytics.loc[unique_mask22, 'CASE_KEY'].tolist()
df_analytics_discrepancy2 = df_analytics[df_analytics['CASE_KEY'].isin(unique_case_key_list22)]

# Output the lists
print(f"Method #2: Unique CASE_KEY in df_oracle (not in df_analytics), n={len(unique_case_key_list2)}:", unique_case_key_list2)
print(f"Method #2: Unique CASE_KEY in df_analytics (not in df_oracle), n={len(unique_case_key_list22)}:", unique_case_key_list22)
print(f"Method #2: Common CASE_KEY in both df_oracle and df_analytics, n={len(common_case_key_list2)}:", common_case_key_list2)
print('Method #2: Discrepancy (missing in Analytics) volume by year:', df_oracle_discrepancy2['CASE_YEAR'].value_counts().sort_index())
print('Method #2: Discrepancy (missing in Oracle) volume by year:', df_analytics_discrepancy2['CASE_YEAR'].value_counts().sort_index())

# Save the list if save_switch is True
if save_switch:    
    # output_filename = f'method2_unique_case_number_from_oracle_not_in_ecol_analytics_{start_date_str}_{end_date_str}_at_{timestamp_str}.csv'
    output_filename = f'method2_unique_case_number_from_oracle_not_in_ecol_analytics_at_{timestamp_str}.csv'
    output_file_path = folder_path + output_filename
    df_oracle_discrepancy2.to_csv(output_file_path, index=False, header=True)

# Warning output
# print(f'IMPORTANT WARNING!!! Caveat: The last year will be overestimation due to {end_date_str} used as when this end date is applied to both \
#       df_oracle and df_analytics, it includes this last date for checking, but since it takes a day or a weekend (if the changes occurs on \
#       Friday), so the "discrepancy" or missing cases in eCollision Analytics for the last day is simply due to time required to sync from eCollision \
#       Oracle to eCollision Analytics.')
print(f'IMPORTANT WARNING!!! "Missing" in eCollision Oracle db is typically not real missing, but due to how case_year is calculated, it may be \
    recorded as a different adjacent year as compared to eCollision Analytics. Or they may be missing some timestamp data (occurence and reported \
        timestamp). So they cannot be compared with eCollision Analytics with the compound key')