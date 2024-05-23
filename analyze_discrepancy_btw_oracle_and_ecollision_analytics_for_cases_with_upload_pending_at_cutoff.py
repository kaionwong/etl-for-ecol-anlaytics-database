# This script takes the extract that contains flag about whether a case has "upload pending" status on the cut-off date. This is
# a more wholesome comparison than other eCollision Oracle vs. eCollision Analytics comparisons. The numbers should be close to 1:1
# between eCollision Oracle and eCollision Analytics. The discrepancies in either side present a potential problem that needs
# to be investigated.
# Caveat: there may be a small number of discrepancies that are expected due to slight variations of how cases are added/removed in
# practice.

import pandas as pd

folder_path = './output/'
start_date_str = '2016-01-01'
end_date_str = '2024-05-17'
save_switch = False # WARNING: This will overwrite files with the same filename if the save_switch is True

# get oracle information
oracle_filename = 'search_ecollision_oracle_with_upload_pending_on_cutoff_date_2024-05-25.csv'
oracle_file_path = folder_path + oracle_filename
df_oracle = pd.read_csv(oracle_file_path)

# Clean and type-set CASE_NBR
df_oracle['CASE_NBR'] = df_oracle['CASE_NBR'].astype(str).str.replace(' ', '', regex=True)
df_oracle = df_oracle[df_oracle['CUTOFF_UPLOAD_PENDING_FLAG']==1]

# Apply date filter if both dates are provided
if start_date_str is not None and end_date_str is not None:
    # Convert OCCURENCE_TIMESTAMP into a date format that can be compared
    df_oracle['OCCURENCE_TIMESTAMP'] = pd.to_datetime(df_oracle['OCCURENCE_TIMESTAMP'], format='%y-%m-%d')
    start_date = pd.to_datetime(start_date_str)
    end_date = pd.to_datetime(end_date_str)
    date_mask = (df_oracle['OCCURENCE_TIMESTAMP'] >= start_date) & (df_oracle['OCCURENCE_TIMESTAMP'] <= end_date)
    df_oracle = df_oracle[date_mask]

# get eCollision Analytics information
analytics_filename = 'main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-05-17.csv'
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

# Save the list
if save_switch:
    df_oracle_discrepancy = df_oracle[df_oracle['CASE_NBR'].isin(unique_case_nbr_list)]
    output_filename = f'unique_case_number_from_oracle_not_in_ecollision_analytics_{start_date_str}_{end_date_str}.csv'
    output_file_path = folder_path + output_filename
    df_oracle_discrepancy.to_csv(output_file_path, index=False, header=True)