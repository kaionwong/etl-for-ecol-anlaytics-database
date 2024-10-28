import os
import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Control panel
select_year_list = [2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009,
                    2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019,
                    2020, 2021, 2022, 2023, 2024]
# full year list below
"""
[2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009,
                    2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019,
                    2020, 2021, 2022, 2023, 2024]
"""
case_number_standardization_switch = True
print_switch = True
example_n = 200

# >>> Input data and label setting #3
filename_date1 = '2024-05-07'
filename_date2 = '2024-09-23'
extract_sql_snapshot1 = f'data\main_extract_ecollision_oracle_data_2000-2024_snapshot_from_{filename_date1}.csv' 
extract_sql_snapshot2 = f'data\main_extract_ecollision_oracle_data_2000-2024_snapshot_from_{filename_date2}.csv'
data_label_1 = f'snapshot_{filename_date1}'
data_label_2 = f'snapshot_{filename_date2}'

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
    # df_copy[column_name] = df_copy[column_name].apply(lambda x: str(x).strip())
    df_copy[column_name] = df_copy[column_name].apply(lambda x: str(x).replace(" ", ""))

    # Convert the specified column to string
    df_copy[column_name] = df_copy[column_name].astype(str)

    # Function to add leading zeros to make it a 25-character string
    df_copy[column_name] = df_copy[column_name].apply(lambda x: x.zfill(25))
    
    return df_copy[column_name]

def remove_space(df, column_name):
    """
    Remove spaces from the specified column in the given DataFrame.
    
    Args:
        df (pandas.DataFrame): The DataFrame from which spaces are to be removed.
        column_name (str): The name of the column from which spaces are to be removed.
        
    Returns:
        pandas.DataFrame: The DataFrame with spaces removed from the specified column.
    """    
    df[column_name] = df[column_name].astype(str).str.replace(" ", "")
    return df[column_name]

# eCollision Analytics extracts from 2 different snapshots
# Note: even though the earlier snapshot was taken in 2022, since by 2022 the finalized year was 2020,
# so the following compatative analytics will only be done on 2020 or earlier year

# Read and concatenate mainframe CSV files
df_snapshot1 = pd.read_csv(extract_sql_snapshot1, low_memory=False)
df_snapshot2 = pd.read_csv(extract_sql_snapshot2, low_memory=False)

# Filter out rows that are not in the expected years
df_snapshot1 = df_snapshot1[(df_snapshot1['CASE_YEAR'] >= min(select_year_list)) & (df_snapshot1['CASE_YEAR'] <= max(select_year_list))]
df_snapshot2 = df_snapshot2[(df_snapshot2['CASE_YEAR'] >= min(select_year_list)) & (df_snapshot2['CASE_YEAR'] <= max(select_year_list))]

# Standardize columns
df_snapshot1['FORM_CASE_NBR'] = df_snapshot1['FORM_CASE_NBR'].apply(remove_non_alphanumeric)
df_snapshot2['FORM_CASE_NBR'] = df_snapshot2['FORM_CASE_NBR'].apply(remove_non_alphanumeric)

# This standardize the CASE_NBR; but in some cases, one may turn this off to see natively if the
# ... pre-standardized CASE_NBR match (they should between snapshots from the same db)
if case_number_standardization_switch:
    df_snapshot1['CASE_NBR'] = remove_space(df_snapshot1, 'CASE_NBR')
    df_snapshot2['CASE_NBR'] = remove_space(df_snapshot2, 'CASE_NBR')

def compare_snapshot(filter_year, df_snapshot1, df_snapshot2, all_year_switch=False):
    df_snapshot1 = df_snapshot1.copy()
    df_snapshot2 = df_snapshot2.copy()

    # All years together:
    if all_year_switch:
        if print_switch:
            print(f'df_snapshot1 refers to', data_label_1)
            print(f'df_snapshot2 refers to', data_label_2)
            print()
            print(f'df_snapshot1 filename:', extract_sql_snapshot1)
            print(f'df_snapshot2 filename:', extract_sql_snapshot2)
            print()
            print(f'Number of rows in df_snapshot1, n', len(df_snapshot1))
            print(f'Number of rows in df_snapshot2, n', len(df_snapshot2))
            print()

            # Comparing COLLISION_ID between two snapshots
            print('>>> Comparing COLLISION_ID between two snapshots:')
            collision_id_list_snapshot1 = df_snapshot1['COLLISION_ID'].to_list()
            collision_id_list_snapshot2 = df_snapshot2['COLLISION_ID'].to_list()

            assert len(collision_id_list_snapshot1) > 0 and len(collision_id_list_snapshot2) > 0

            collision_id_only_in_snapshot1 = list(set(collision_id_list_snapshot1) - set(collision_id_list_snapshot2))
            collision_id_only_in_snapshot2 = list(set(collision_id_list_snapshot2) - set(collision_id_list_snapshot1))

            print('Frequency by CASE_YEAR in df_snapshot1', df_snapshot1['CASE_YEAR'].value_counts())
            print('Frequency by CASE_YEAR in df_snapshot2', df_snapshot2['CASE_YEAR'].value_counts())
            # Compare the difference in value_counts()
            case_year_count_snapshot1 = df_snapshot1['CASE_YEAR'].value_counts()
            case_year_count_snapshot2 = df_snapshot2['CASE_YEAR'].value_counts()
            # Create DataFrames with the counts
            df_case_year_count_snapshot1 = pd.DataFrame({'Year': case_year_count_snapshot1.index, data_label_1: case_year_count_snapshot1.values})
            df_case_year_count_snapshot2 = pd.DataFrame({'Year': case_year_count_snapshot2.index, data_label_2: case_year_count_snapshot2.values})
            # Merge the counts based on 'Year'
            df_count_diff = df_case_year_count_snapshot1.set_index('Year').join(df_case_year_count_snapshot2.set_index('Year'), how='outer')
            # Fill NaN values with 0
            df_count_diff = df_count_diff.fillna(0)
            # Calculate the difference in counts
            df_count_diff['Count_Difference'] = df_count_diff[data_label_2] - df_count_diff[data_label_1]
            # Display the result sorted by year
            df_count_diff = df_count_diff.sort_index()
            print(df_count_diff)
            print()

            print(f'Number of COLLISION_ID in {data_label_1} but not in {data_label_2}, n:', len(collision_id_only_in_snapshot1))
            print(collision_id_only_in_snapshot1[0:example_n])
            print(df_snapshot1[df_snapshot1['COLLISION_ID'].isin(collision_id_only_in_snapshot1)].head())
            print(df_snapshot1[df_snapshot1['COLLISION_ID'].isin(collision_id_only_in_snapshot1)].tail())
            print()
        
            # print('>>> Further investigation - begin')
            # print('In {data_label_1}, COLLISION_ID=2211768 and CASE_NBR=5000873')
            # print(df_snapshot1[df_snapshot1['COLLISION_ID']==2211768])
            # print(f'In {data_label_1}, COLLISION_ID=2211768 and CASE_NBR=5000873 is in {data_label_1} but not in {data_label_2}')
            # print('To confirm, eCollision analytics does not have that CASE_NBR=5000873')
            # print(df_snapshot2[df_snapshot2['CASE_NBR']==5000873])
            # print()
            # print('However for earlier discrepancies')
            # print(f'In {data_label_1}, COLLISION_ID=-2275487 and CASE_NBR=1099039 is in {data_label_1} but not in {data_label_2}')
            # print('However, eCollision analytics does have CASE_NBR=1099039, where COLLISION_ID=1979035')
            # print(df_snapshot2[df_snapshot2['CASE_NBR']==1099039])
            # print('>>> Further investigation - end')
            # print()

            print(f'Number of COLLISION_ID in {data_label_2} but not in {data_label_1}, n:', len(collision_id_only_in_snapshot2))
            print(collision_id_only_in_snapshot2[0:example_n])
            print(df_snapshot2[df_snapshot2['COLLISION_ID'].isin(collision_id_only_in_snapshot2)].head())
            print(df_snapshot2[df_snapshot2['COLLISION_ID'].isin(collision_id_only_in_snapshot2)].tail())
            print()

            print('>>> Comparing CASE_NBR between two snapshots:')
            case_number_list_snapshot1 = df_snapshot1['CASE_NBR'].to_list()
            case_number_list_snapshot2 = df_snapshot2['CASE_NBR'].to_list()

            assert len(case_number_list_snapshot1) > 0 and len(case_number_list_snapshot2) > 0

            case_number_only_in_snapshot1 = list(set(case_number_list_snapshot1) - set(case_number_list_snapshot2))
            case_number_only_in_snapshot2 = list(set(case_number_list_snapshot2) - set(case_number_list_snapshot1))

            print(f'Number of CASE_NBR in {data_label_1} but not in {data_label_2}, n:', len(case_number_only_in_snapshot1))
            print(case_number_only_in_snapshot1[0:example_n])
            print(f'Number of CASE_NBR in {data_label_2} but not in {data_label_1}, n:', len(case_number_only_in_snapshot2))
            print(case_number_only_in_snapshot2[0:example_n])
            print()
        
            print('>>> Comparing FORM_CASE_NBR between two snapshots:')
            pfn_list_snapshot1 = df_snapshot1['FORM_CASE_NBR'].to_list()
            pfn_list_snapshot2 = df_snapshot2['FORM_CASE_NBR'].to_list()

            assert len(pfn_list_snapshot1) > 0 and len(pfn_list_snapshot2) > 0

            pfn_only_in_snapshot1 = list(set(pfn_list_snapshot1) - set(pfn_list_snapshot2))
            pfn_only_in_snapshot2 = list(set(pfn_list_snapshot2) - set(pfn_list_snapshot1))

            print(f'Number of FORM_CASE_NBR in {data_label_1} but not in {data_label_2}, n:', len(pfn_only_in_snapshot1))
            print(pfn_only_in_snapshot1[0:example_n])
            print(f'Number of FORM_CASE_NBR in {data_label_2} but not in {data_label_1}, n:', len(pfn_only_in_snapshot2))
            print(pfn_only_in_snapshot2[0:example_n])
            print()

    # Filter by year
    df_snapshot1_yr = df_snapshot1[df_snapshot1['CASE_YEAR'] == filter_year]
    df_snapshot2_yr = df_snapshot2[df_snapshot2['CASE_YEAR'] == filter_year]

    if print_switch:
        print(f'>>> Year {filter_year}')
        print(f'Number of rows in year {filter_year} of df_snapshot1_yr, n:', len(df_snapshot1_yr))
        print(f'Number of rows in year {filter_year} of df_snapshot2_yr, n:', len(df_snapshot2_yr))

        print('>>> Comparing COLLISION_ID between two snapshots:')
        collision_id_list_snapshot1_yr = df_snapshot1_yr['COLLISION_ID'].to_list()
        collision_id_list_snapshot2_yr = df_snapshot2_yr['COLLISION_ID'].to_list()

        if len(collision_id_list_snapshot1_yr) == 0 and len(collision_id_list_snapshot2_yr) == 0:
            print('CUSTOM WARNING: len(collision_id_list_snapshot1_yr) == 0 and len(collision_id_list_snapshot2_yr) == 0')

        collision_id_only_in_snapshot1_yr = list(set(collision_id_list_snapshot1_yr) - set(collision_id_list_snapshot2_yr))
        collision_id_only_in_snapshot2_yr = list(set(collision_id_list_snapshot2_yr) - set(collision_id_list_snapshot1_yr))

        print(f'Number of COLLISION_ID in year {filter_year} in {data_label_1} but not in {data_label_2}, n:', len(collision_id_only_in_snapshot1_yr))
        print(collision_id_only_in_snapshot1_yr[0:example_n])
        print(f'Number of COLLISION_ID in year {filter_year} in {data_label_2} but not in {data_label_1}, n:', len(collision_id_only_in_snapshot2_yr))
        print(collision_id_only_in_snapshot2_yr[0:example_n])
        print()

        print('>>> Comparing CASE_NBR between two snapshots')
        case_number_list_snapshot1_yr = df_snapshot1_yr['CASE_NBR'].to_list()
        case_number_list_snapshot2_yr = df_snapshot2_yr['CASE_NBR'].to_list()

        if len(case_number_list_snapshot1_yr) == 0 and len(case_number_list_snapshot2_yr) == 0:
            print('CUSTOM WARNING: len(case_number_list_snapshot1_yr) == 0 and len(case_number_list_snapshot2_yr)')

        case_number_only_in_snapshot1_yr = list(set(case_number_list_snapshot1_yr) - set(case_number_list_snapshot2_yr))
        case_number_only_in_snapshot2_yr = list(set(case_number_list_snapshot2_yr) - set(case_number_list_snapshot1_yr))

        print(f'Number of CASE_NBR in year {filter_year} in {data_label_1} but not in {data_label_2}, n:', len(case_number_only_in_snapshot1_yr))
        print(case_number_only_in_snapshot1_yr[0:example_n])
        print(f'Number of CASE_NBR in year {filter_year} in {data_label_2} but not in {data_label_1}, n:', len(case_number_only_in_snapshot2_yr))
        print(case_number_only_in_snapshot2_yr[0:example_n])
        print()

        print('>>> Comparing FORM_CASE_NBR between two snapshots')
        pfn_list_snapshot1_yr = df_snapshot1_yr['FORM_CASE_NBR'].to_list()
        pfn_list_snapshot2_yr = df_snapshot2_yr['FORM_CASE_NBR'].to_list()

        if len(pfn_list_snapshot1_yr) == 0 and len(case_number_list_snapshot2_yr) == 0:
            print('CUSTOM WARNING: len(pfn_list_snapshot1_yr) == 0 and len(case_number_list_snapshot2_yr) == 0')

        pfn_only_in_snapshot1_yr = list(set(pfn_list_snapshot1_yr) - set(pfn_list_snapshot2_yr))
        pfn_only_in_snapshot2_yr = list(set(pfn_list_snapshot2_yr) - set(pfn_list_snapshot1_yr))

        print(f'Number of FORM_CASE_NBR in year {filter_year} in {data_label_1} but not in {data_label_2}, n:', len(pfn_only_in_snapshot1_yr))
        print(pfn_only_in_snapshot1_yr[0:example_n])
        print(f'Number of FORM_CASE_NBR in year {filter_year} in {data_label_2} but not in {data_label_1}, n:', len(pfn_only_in_snapshot2_yr))
        print(pfn_only_in_snapshot2_yr[0:example_n])
        print()

if __name__ == '__main__':
    counter = 0
    for sp_year in select_year_list:
        if counter == 0:
            compare_snapshot(sp_year, df_snapshot1, df_snapshot2, all_year_switch=True)
            counter += 1
        else:
            compare_snapshot(sp_year, df_snapshot1, df_snapshot2, all_year_switch=False)
    print('Done!!!')
