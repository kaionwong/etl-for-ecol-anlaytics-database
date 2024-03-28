import os
import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Control panel
select_year = 2022
select_year_list = [2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009,
                    2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019,
                    2020] # 2021 could be used as a negative test case where they are supposed to be different
case_number_standardization_switch = True
print_switch = True
example_n = 15

# Helper functions
def pandas_output_setting():
    """Set pandas output display setting"""
    pd.set_option('display.max_rows', 500)
    pd.set_option('display.max_columns', None)
    ##pd.set_option('display.max_columns', 500)
    pd.set_option('display.width', 120)
    pd.set_option('display.max_colwidth', None)
    pd.options.mode.chained_assignment = None  # default='warn'

pandas_output_setting()

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

# eCollision Analytics extracts from 2 different snapshots
# Note: even though the earlier snapshot was taken in 2022, since by 2022 the finalized year was 2020,
# so the following compatative analytics will only be done on 2020 or earlier year
extract_sql_snapshot_2022 = 'main_extract_ecollision_analytics_data_2000-2021_snapshot_from_2022.csv'
extract_sql_snapshot_2024 = 'main_extract_ecollision_analytics_data_2000-2021_snapshot_from_2024.csv' 

# Read and concatenate mainframe CSV files
df_snapshot_2022 = pd.read_csv(extract_sql_snapshot_2022)
df_snapshot_2024 = pd.read_csv(extract_sql_snapshot_2024)

# Also include the discrepancy list (that case_nbr exists in MainFrame but not in Analytics (2000-2016))
csv_file_name_discrepancy_between_mainframe_and_ecollision_analytics = "df_mainframe_case_number_not_in_df_sql.csv"
current_directory = os.getcwd()
output_folder = "output"
csv_file_path_discrepancy = os.path.join(current_directory, output_folder, csv_file_name_discrepancy_between_mainframe_and_ecollision_analytics)
df_discrepancy = pd.read_csv(csv_file_path_discrepancy)

if case_number_standardization_switch:
    df_discrepancy['case_number'] = add_leading_zero(df_discrepancy, 'case_number')

# Filter out rows that are not in the expected years
df_snapshot_2022 = df_snapshot_2022[(df_snapshot_2022['CASE_YEAR'] >= min(select_year_list)) & (df_snapshot_2022['CASE_YEAR'] <= select_year_list.max())]
df_snapshot_2024 = df_snapshot_2024[(df_snapshot_2024['CASE_YEAR'] >= min(select_year_list)) & (df_snapshot_2024['CASE_YEAR'] <= select_year_list.max())]

# Standardize columns
df_snapshot_2022['PFN_FILE_NBR'] = df_snapshot_2022['PFN_FILE_NBR'].apply(remove_non_alphanumeric)
df_snapshot_2024['PFN_FILE_NBR'] = df_snapshot_2024['PFN_FILE_NBR'].apply(remove_non_alphanumeric)

# This standardize the CASE_NBR; but in some cases, one may turn this off to see natively if the
# ... pre-standardized CASE_NBR match (they should between snapshots from the same db)
if case_number_standardization_switch:
    df_snapshot_2022['CASE_NBR'] = add_leading_zero(df_snapshot_2022, 'CASE_NBR')
    df_snapshot_2024['CASE_NBR'] = add_leading_zero(df_snapshot_2024, 'CASE_NBR')

def compare_snapshot(filter_year, df_snapshot_2022, df_snapshot_2024, all_year_switch=False):
    df_snapshot_2022 = df_snapshot_2022.copy()
    df_snapshot_2024 = df_snapshot_2024.copy()

    # All years together:
    if all_year_switch:
        if print_switch:
            print(f'Number of rows in df_snapshot_2022, n', len(df_snapshot_2022))
            print(f'Number of rows in df_snapshot_2024, n', len(df_snapshot_2024))

            # Comparing COLLISION_ID between two snapshots
            print('>>> Comparing COLLISION_ID between two snapshots:')
            collision_id_list_snapshot_2022 = df_snapshot_2022['COLLISION_ID'].to_list()
            collision_id_list_snapshot_2024 = df_snapshot_2024['COLLISION_ID'].to_list()

            assert len(collision_id_list_snapshot_2022) > 0 and len(collision_id_list_snapshot_2024) > 0

            collision_id_only_in_snapshot_2022 = list(set(collision_id_list_snapshot_2022) - set(collision_id_list_snapshot_2024))
            collision_id_only_in_snapshot_2024 = list(set(collision_id_list_snapshot_2024) - set(collision_id_list_snapshot_2022))

            print('Frequency by CASE_YEAR in df_snapshot_2022', df_snapshot_2022['CASE_YEAR'].value_counts())
            print('Frequency by CASE_YEAR in df_snapshot_2024', df_snapshot_2024['CASE_YEAR'].value_counts())
            # Compare the difference in value_counts()
            case_year_count_2022 = df_snapshot_2022['CASE_YEAR'].value_counts()
            case_year_count_2024 = df_snapshot_2024['CASE_YEAR'].value_counts()
            # Create DataFrames with the counts
            df_case_year_count_2022 = pd.DataFrame({'Year': case_year_count_2022.index, 'Count_2022': case_year_count_2022.values})
            df_case_year_count_2024 = pd.DataFrame({'Year': case_year_count_2024.index, 'Count_2024': case_year_count_2024.values})
            # Merge the counts based on 'Year'
            df_count_diff = df_case_year_count_2022.set_index('Year').join(df_case_year_count_2024.set_index('Year'), how='outer')
            # Fill NaN values with 0
            df_count_diff = df_count_diff.fillna(0)
            # Calculate the difference in counts
            df_count_diff['Count_Difference'] = df_count_diff['Count_2024'] - df_count_diff['Count_2022']
            # Display the result sorted by year
            df_count_diff = df_count_diff.sort_index()
            print(df_count_diff)
            print()

            print(f'Number of COLLISION_ID in 2022 snapshot but not in 2024 snapshot, n:', len(collision_id_only_in_snapshot_2022))
            print(collision_id_only_in_snapshot_2022[0:example_n])
            print(df_snapshot_2022[df_snapshot_2022['COLLISION_ID'].isin(collision_id_only_in_snapshot_2022)].head())
            print(df_snapshot_2022[df_snapshot_2022['COLLISION_ID'].isin(collision_id_only_in_snapshot_2022)].tail())
            print()
        
            print('>>> Further investigation - begin')
            print('In 2022 snapshot, COLLISION_ID=2211768 and CASE_NBR=5000873')
            print(df_snapshot_2022[df_snapshot_2022['COLLISION_ID']==2211768])
            print('In 2022 snapshot, COLLISION_ID=2211768 and CASE_NBR=5000873 is in 2022 snapshot but not in 2024 snapshot')
            print('To confirm, eCollision analytics does not have that CASE_NBR=5000873')
            print(df_snapshot_2024[df_snapshot_2024['CASE_NBR']==5000873])
            print()
            print('However for earlier discrepancies')
            print('In 2022 snapshot, COLLISION_ID=-2275487 and CASE_NBR=1099039 is in 2022 snapshot but not in 2024 snapshot')
            print('However, eCollision analytics does have CASE_NBR=1099039, where COLLISION_ID=1979035')
            print(df_snapshot_2024[df_snapshot_2024['CASE_NBR']==1099039])
            print('>>> Further investigation - end')
            print()

            print(f'Number of COLLISION_ID in 2024 snapshot but not in 2022 snapshot, n:', len(collision_id_only_in_snapshot_2024))
            print(collision_id_only_in_snapshot_2024[0:example_n])
            print(df_snapshot_2024[df_snapshot_2024['COLLISION_ID'].isin(collision_id_only_in_snapshot_2024)].head())
            print(df_snapshot_2024[df_snapshot_2024['COLLISION_ID'].isin(collision_id_only_in_snapshot_2024)].tail())
            print()

            print('>>> Comparing CASE_NBR between two snapshots:')
            case_number_list_snapshot_2022 = df_snapshot_2022['CASE_NBR'].to_list()
            case_number_list_snapshot_2024 = df_snapshot_2024['CASE_NBR'].to_list()

            assert len(case_number_list_snapshot_2022) > 0 and len(case_number_list_snapshot_2024) > 0

            case_number_only_in_snapshot_2022 = list(set(case_number_list_snapshot_2022) - set(case_number_list_snapshot_2024))
            case_number_only_in_snapshot_2024 = list(set(case_number_list_snapshot_2024) - set(case_number_list_snapshot_2022))

            print(f'Number of CASE_NBR in 2022 snapshot but not in 2024 snapshot, n:', len(case_number_only_in_snapshot_2022))
            print(case_number_only_in_snapshot_2022[0:example_n])
            print(f'Number of CASE_NBR in 2024 snapshot but not in 2022 snapshot, n:', len(case_number_only_in_snapshot_2024))
            print(case_number_only_in_snapshot_2024[0:example_n])
            print()
            
            print('>>> Further investigation - begin')
            case_number_only_in_mainframe = df_discrepancy['case_number'].tolist()
            print(f'len of case_number_only_in_snapshot_2022: {len(case_number_only_in_snapshot_2022)}')
            print(f'len of case_number_only_in_mainframe: {len(case_number_only_in_mainframe)}')
            print(f'len only in case_number_only_in_snapshot_2022 but not in case_number_only_in_mainframe: {len(set(case_number_only_in_snapshot_2022) - set(case_number_only_in_mainframe))}')
            print(f'len only in case_number_only_in_mainframe but not in case_number_only_in_snapshot_2022: {len(set(case_number_only_in_mainframe) - set(case_number_only_in_snapshot_2022))}')
            print(f'len in both case_number_only_in_mainframe and case_number_only_in_snapshot_2022: {len(set(case_number_only_in_mainframe) & set(case_number_only_in_snapshot_2022))}')
            print('>>> Further investigation - end')
            print()
        
            print('>>> Comparing PFN_FILE_NBR between two snapshots:')
            pfn_list_snapshot_2022 = df_snapshot_2022['PFN_FILE_NBR'].to_list()
            pfn_list_snapshot_2024 = df_snapshot_2024['PFN_FILE_NBR'].to_list()

            assert len(pfn_list_snapshot_2022) > 0 and len(pfn_list_snapshot_2024) > 0

            pfn_only_in_snapshot_2022 = list(set(pfn_list_snapshot_2022) - set(pfn_list_snapshot_2024))
            pfn_only_in_snapshot_2024 = list(set(pfn_list_snapshot_2024) - set(pfn_list_snapshot_2022))

            print(f'Number of PFN_FILE_NBR in 2022 snapshot but not in 2024 snapshot, n:', len(pfn_only_in_snapshot_2022))
            print(pfn_only_in_snapshot_2022[0:example_n])
            print(f'Number of PFN_FILE_NBR in 2024 snapshot but not in 2022 snapshot, n:', len(pfn_only_in_snapshot_2024))
            print(pfn_only_in_snapshot_2024[0:example_n])
            print()

    # Filter by year
    df_snapshot_2022_yr = df_snapshot_2022[df_snapshot_2022['CASE_YEAR'] == filter_year]
    df_snapshot_2024_yr = df_snapshot_2024[df_snapshot_2024['CASE_YEAR'] == filter_year]

    if print_switch:
        print(f'>>> Year {filter_year}')
        print(f'Number of rows in year {filter_year} of df_snapshot_2022_yr, n:', len(df_snapshot_2022_yr))
        print(f'Number of rows in year {filter_year} of df_snapshot_2024_yr, n:', len(df_snapshot_2024_yr))

        print('>>> Comparing COLLISION_ID between two snapshots:')
        collision_id_list_snapshot_2022_yr = df_snapshot_2022_yr['COLLISION_ID'].to_list()
        collision_id_list_snapshot_2024_yr = df_snapshot_2024_yr['COLLISION_ID'].to_list()

        assert len(collision_id_list_snapshot_2022_yr) > 0 and len(collision_id_list_snapshot_2024_yr) > 0

        collision_id_only_in_snapshot_2022_yr = list(set(collision_id_list_snapshot_2022_yr) - set(collision_id_list_snapshot_2024_yr))
        collision_id_only_in_snapshot_2024_yr = list(set(collision_id_list_snapshot_2024_yr) - set(collision_id_list_snapshot_2022_yr))

        print(f'Number of COLLISION_ID in year {filter_year} in 2022 snapshot but not in 2024 snapshot, n:', len(collision_id_only_in_snapshot_2022_yr))
        print(collision_id_only_in_snapshot_2022_yr[0:example_n])
        print(f'Number of COLLISION_ID in year {filter_year} in 2024 snapshot but not in 2022 snapshot, n:', len(collision_id_only_in_snapshot_2024_yr))
        print(collision_id_only_in_snapshot_2024_yr[0:example_n])
        print()

        print('>>> Comparing CASE_NBR between two snapshots')
        case_number_list_snapshot_2022_yr = df_snapshot_2022_yr['CASE_NBR'].to_list()
        case_number_list_snapshot_2024_yr = df_snapshot_2024_yr['CASE_NBR'].to_list()

        assert len(case_number_list_snapshot_2022_yr) > 0 and len(case_number_list_snapshot_2024_yr) > 0

        case_number_only_in_snapshot_2022_yr = list(set(case_number_list_snapshot_2022_yr) - set(case_number_list_snapshot_2024_yr))
        case_number_only_in_snapshot_2024_yr = list(set(case_number_list_snapshot_2024_yr) - set(case_number_list_snapshot_2022_yr))

        print(f'Number of CASE_NBR in year {filter_year} in 2022 snapshot but not in 2024 snapshot, n:', len(case_number_only_in_snapshot_2022_yr))
        print(case_number_only_in_snapshot_2022_yr[0:example_n])
        print(f'Number of CASE_NBR in year {filter_year} in 2024 snapshot but not in 2022 snapshot, n:', len(case_number_only_in_snapshot_2024_yr))
        print(case_number_only_in_snapshot_2024_yr[0:example_n])
        print()

        print('>>> Comparing PFN_FILE_NBR between two snapshots')
        pfn_list_snapshot_2022_yr = df_snapshot_2022_yr['PFN_FILE_NBR'].to_list()
        pfn_list_snapshot_2024_yr = df_snapshot_2024_yr['PFN_FILE_NBR'].to_list()

        assert len(pfn_list_snapshot_2022_yr) > 0 and len(case_number_list_snapshot_2024_yr) > 0

        pfn_only_in_snapshot_2022_yr = list(set(pfn_list_snapshot_2022_yr) - set(pfn_list_snapshot_2024_yr))
        pfn_only_in_snapshot_2024_yr = list(set(pfn_list_snapshot_2024_yr) - set(pfn_list_snapshot_2022_yr))

        print(f'Number of PFN_FILE_NBR in year {filter_year} in 2022 snapshot but not in 2024 snapshot, n:', len(pfn_only_in_snapshot_2022_yr))
        print(pfn_only_in_snapshot_2022_yr[0:example_n])
        print(f'Number of PFN_FILE_NBR in year {filter_year} in 2024 snapshot but not in 2022 snapshot, n:', len(pfn_only_in_snapshot_2024_yr))
        print(pfn_only_in_snapshot_2024_yr[0:example_n])
        print()

if __name__ == '__main__':
    counter = 0
    for sp_year in select_year_list:
        if counter == 0:
            compare_snapshot(sp_year, df_snapshot_2022, df_snapshot_2024, all_year_switch=True)
            counter += 1
        else:
            compare_snapshot(sp_year, df_snapshot_2022, df_snapshot_2024, all_year_switch=False)
