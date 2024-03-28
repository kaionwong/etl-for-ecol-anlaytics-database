import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

import helper

# Helper functions
def value_count_as_percent(df, col):
    print(df[col].value_counts(normalize=True).mul(100).round(1).astype(str) + '%')

helper.pandas_output_setting(max_rows=500)

def remove_non_alphanumeric(value):
    if pd.notna(value):
        return ''.join(char for char in str(value) if char.isalnum())
    else:
        return np.nan

def add_leading_zero(df, column_name):
    """
    Fill the string with leading zeros to make it a 25-character string.

    Parameters:
    - df (pandas.DataFrame): Input DataFrame.
    - column_name (str): Name of the column to check and modify.

    Returns:
    pandas.DataFrame: DataFrame with values modified in the specified column.
    """
    df_copy = df.copy()

    # Remove leading and trailing spaces from the specified column
    df_copy[column_name] = df_copy[column_name].apply(lambda x: str(x).strip())

    # Convert the specified column to string
    df_copy[column_name] = df_copy[column_name].astype(str)

    # Function to add leading zeros to make it a 25-character string
    df_copy[column_name] = df_copy[column_name].apply(lambda x: x.zfill(25))
    
    return df_copy[column_name]

# Control panel
print_switch = True
graph_switch = True
save_switch = False

# Specify the output folder and CSV file name
output_folder = "output"
csv_file_name_discrepancy_between_mainframe_and_ecollision_analytics = "df_mainframe_case_number_not_in_df_sql.csv"
csv_file_name_discrepancy_between_mainframe_and_ecollision_analytics_overlay_ecollision_oracle = 'data_discrepancy_by_ccn2.csv'

# Get the current working directory
current_directory = os.getcwd()

# Create the full path to the CSV file by joining the current directory, output folder, and file name
csv_file_path_discrepancy = os.path.join(current_directory, output_folder, csv_file_name_discrepancy_between_mainframe_and_ecollision_analytics)
csv_file_path_oracle = os.path.join(current_directory, output_folder, csv_file_name_discrepancy_between_mainframe_and_ecollision_analytics_overlay_ecollision_oracle)

# Read the CSV file into a DataFrame
df_discrepancy = pd.read_csv(csv_file_path_discrepancy)
df_oracle = pd.read_csv(csv_file_path_oracle)

# Data processing
df_discrepancy['occurrence_date'] = pd.to_datetime(df_discrepancy['occurrence_date'], errors='coerce')
df_discrepancy['year_month'] = df_discrepancy['occurrence_date'].dt.to_period('M')
df_discrepancy['police_file_number'] = df_discrepancy['police_file_number'].apply(remove_non_alphanumeric)
df_discrepancy['case_number'] = add_leading_zero(df_discrepancy, 'case_number')

df_oracle['PFN_FILE_NBR'] = df_oracle['PFN_FILE_NBR'].apply(remove_non_alphanumeric)
df_oracle['CASE_NBR'] = add_leading_zero(df_oracle, 'CASE_NBR')

# Create unique lists
list_case_number_from_df_discrepancy = list(set(df_discrepancy['case_number'].to_list()))
list_case_number_from_df_oracle = list(set(df_oracle['CASE_NBR'].to_list()))

list_pfn_from_df_discrepancy = list(set(df_discrepancy['police_file_number'].to_list()))
list_pfn_from_df_oracle = list(set(df_oracle['PFN_FILE_NBR'].to_list()))

case_number_in_df_discrepancy_but_not_in_df_oracle = list(set(list_case_number_from_df_discrepancy) - set(list_case_number_from_df_oracle))
case_number_in_df_oracle_but_not_in_df_discrepancy = list(set(list_case_number_from_df_oracle) - set(list_case_number_from_df_discrepancy))

pfn_in_df_discrepancy_but_not_in_df_oracle = list(set(list_pfn_from_df_discrepancy) - set(list_pfn_from_df_oracle))
pfn_in_df_oracle_but_not_in_df_discrepancy = list(set(list_pfn_from_df_oracle) - set(list_pfn_from_df_discrepancy))

if print_switch:
    print('>>> In df_discrepancy')
    print('Number of rows:', len(df_discrepancy))
    print('Number of unique Case numbers:', len(list_case_number_from_df_discrepancy))
    print('Number of unique Police file numbers:', len(list_pfn_from_df_discrepancy))
    print('Distribution of Case year:', df_discrepancy['case_year'].value_counts())
    print()
    
    print('>>> In df_oracle')
    print('Number of rows:', len(df_oracle))
    print('Number of unique Case numbers:', len(list_case_number_from_df_oracle))
    print('Number of unique Police file numbers:', len(list_pfn_from_df_oracle))
    print('Distribution of Case year:', df_oracle['CASE_YEAR'].value_counts())
    print()
    
    print('>>> Comparing df_discrepancy and df_oracle')
    print('N row - Case numbers that exist in df_discrepancy but not in df_oracle', len(case_number_in_df_discrepancy_but_not_in_df_oracle))
    print('Examples - Case numbers that exist in df_discrepancy but not in df_oracle', case_number_in_df_discrepancy_but_not_in_df_oracle[0:5])
    
    print('N row - PFNs that exist in df_discrepancy but not in df_oracle', len(pfn_in_df_discrepancy_but_not_in_df_oracle))
    print('Examples - PFNs that exist in df_discrepancy but not in df_oracle', pfn_in_df_discrepancy_but_not_in_df_oracle[0:5])
    
    print('N row - Case numbers that exist in df_oracle but not in df_discrepancy', len(case_number_in_df_oracle_but_not_in_df_discrepancy))
    print('Examples - Case numbers that exist in df_oracle but not in df_discrepancy', case_number_in_df_oracle_but_not_in_df_discrepancy[0:5])
    
    print('N row - PFNs that exist in df_oracle but not in df_discrepancy', len(pfn_in_df_oracle_but_not_in_df_discrepancy))
    print('Examples - PFNs that exist in df_oracle but not in df_discrepancy', pfn_in_df_oracle_but_not_in_df_discrepancy[0:5])
    
# Merging the two dfs by case_number; need outer join
df_discrepancy_slim = df_discrepancy[['case_year', 'case_number', 'police_service_code', 'police_file_number', 'occurrence_date', 'municipality']]
df_merged = df_discrepancy_slim.merge(df_oracle, left_on='case_number', right_on='CASE_NBR', how='outer')

# Create the frequency table with missing combinations filled
frequency_table = df_merged.groupby(['case_year', 'CASE_YEAR']).size().unstack(fill_value=0)

if print_switch:
    print('Frequency table of Case year between two sets of data')
    print(frequency_table)
    
if save_switch:
    output_folder = "output"
    os.makedirs(output_folder, exist_ok=True)
    csv_file_path = os.path.join(output_folder, 'outer_join_df_discrepancy_df_oracle.csv')
    df_merged.to_csv(csv_file_path, index=False, header=True)