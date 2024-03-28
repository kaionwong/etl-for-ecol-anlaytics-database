import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Control panel
select_year = '2002' # make sure this is string type since I will standardize case_year columns as string in the dfs
print_switch = True
all_year_switch = True # whether to run all the available years of Mainframe or just some of them
save_all_year_output_switch = True # whether to save the "all year" df outputs
save_select_year_output_switch = False # whether to save select year df outputs
graph_switch = False

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

def count_duplicate(df, column_name):
    """
    Count the number of duplicate values in a DataFrame column.

    Parameters:
    - df: pandas DataFrame
    - column_name: str, the column for which to count duplicates

    Returns:
    - int, the number of duplicate values in the specified column
    """
    return df.duplicated(subset=column_name).sum()

import pandas as pd

def get_sorted_duplicates(df, column_name, strip_nonalphanumeric_char=False):
    """
    Get a DataFrame containing only rows with duplicate values in a specified column, sorted by that column.

    Parameters:
    - df (pandas.DataFrame): Input DataFrame.
    - column_name (str): Name of the column to check for duplicates.

    Returns:
    pandas.DataFrame: DataFrame containing only rows with duplicate values, sorted by the specified column.
    """
    # Create a copy to avoid SettingWithCopyWarning
    df_copy = df.copy()

    # Convert the column to string to ensure consistent data type for sorting
    df_copy[column_name] = df_copy[column_name].astype(str)

    if strip_nonalphanumeric_char:
        # Clean the specified column by removing non-alphanumeric characters
        df_copy[column_name] = df_copy[column_name].replace('[^A-Za-z0-9]', '', regex=True)

    # Find rows with duplicate values in the specified column
    duplicates_df = df_copy[df_copy.duplicated(subset=column_name, keep=False)]

    # Sort the DataFrame by the cleaned column
    sorted_duplicates_df = duplicates_df.sort_values(by=column_name)

    return sorted_duplicates_df

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

if all_year_switch:
    mainframe_year_file = [
        'mainframe_extract_collisions_2000.csv',
        'mainframe_extract_collisions_2001.csv',
        'mainframe_extract_collisions_2002.csv',
        'mainframe_extract_collisions_2003.csv',
        'mainframe_extract_collisions_2004.csv',
        'mainframe_extract_collisions_2005.csv',
        'mainframe_extract_collisions_2006.csv',
        'mainframe_extract_collisions_2007.csv',
        'mainframe_extract_collisions_2008.csv',
        'mainframe_extract_collisions_2009.csv',
        'mainframe_extract_collisions_2010.csv',
        'mainframe_extract_collisions_2011.csv',
        'mainframe_extract_collisions_2012.csv',
        'mainframe_extract_collisions_2013.csv',   
        'mainframe_extract_collisions_2014.csv',
        'mainframe_extract_collisions_2015.csv',
        'mainframe_extract_collisions_2016.csv',
    ]
    ecollision_analytics_sql_file = 'main_extract_ecollision_analytics_data_2000-2016.csv'

else:
    mainframe_year_file = [
        'mainframe_extract_collisions_2000.csv',
        'mainframe_extract_collisions_2001.csv',
        'mainframe_extract_collisions_2002.csv',
        'mainframe_extract_collisions_2014.csv',
        'mainframe_extract_collisions_2015.csv',
        'mainframe_extract_collisions_2016.csv',
    ]
    ecollision_analytics_sql_file = 'main_extract_ecollision_analytics_data_2000-2002_2014-2016.csv'

# Read and concatenate mainframe CSV files
df_mainframe = pd.concat([pd.read_csv(file) for file in mainframe_year_file], ignore_index=True)
df_mainframe_full = df_mainframe.copy()
df_mainframe_full['case_number'] = add_leading_zero(df_mainframe_full, 'case_number')
df_mainframe = df_mainframe[['case_number', 'case_year', 'police_file_number', 'police_service_code', 'on_highway', 'occurrence_date', 'occurrence_time']]

# Read SQL CSV file
df_sql = pd.read_csv(ecollision_analytics_sql_file)

# Col manipulation
df_mainframe['police_file_number'] = df_mainframe['police_file_number'].apply(remove_non_alphanumeric)
df_sql['PFN_FILE_NBR'] = df_sql['PFN_FILE_NBR'].apply(remove_non_alphanumeric)
df_mainframe['case_number'] = add_leading_zero(df_mainframe, 'case_number')
df_sql['CASE_NBR'] = add_leading_zero(df_sql, 'CASE_NBR')
df_sql['CASE_NBR'] = add_leading_zero(df_sql, 'CASE_NBR')

# Var type declaration
df_mainframe['case_year'] = df_mainframe['case_year'].astype(int).astype(str)
df_sql['CASE_YEAR'] = df_sql['CASE_YEAR'].astype(int).astype(str)

# Slice both dfs based on select_year so we can make further comparison
df_mainframe_c = df_mainframe.copy()
df_sql_c = df_sql.copy()
df_mainframe_yr = df_mainframe_c[df_mainframe_c['case_year']==select_year]
df_sql_yr = df_sql_c[df_sql_c['CASE_YEAR']==select_year]

# Create dfs that contains only duplicates by specified col name
df_mainframe_dup_case_number = get_sorted_duplicates(df_mainframe, 'case_number')
df_mainframe_dup_police_file_number = get_sorted_duplicates(df_mainframe, 'police_file_number')
df_sql_dup_collision_id = get_sorted_duplicates(df_sql, 'COLLISION_ID')
df_sql_dup_case_nbr = get_sorted_duplicates(df_sql, 'CASE_NBR')
df_sql_dup_pfn_file_nbr = get_sorted_duplicates(df_sql, 'PFN_FILE_NBR')

if graph_switch:
    # Plotting the histogram
    df_mainframe_dup_case_number['case_year_int'] = df_mainframe_dup_case_number['case_year'].astype(int)
    value_counts = df_mainframe_dup_case_number['case_year_int'].value_counts()
    plt.figure(figsize=(8, 6))
    plt.bar(value_counts.index, value_counts.values, color='skyblue', edgecolor='black')
    plt.xlabel('Case Year')
    plt.ylabel('Frequency')
    plt.title('Frequency histogram of case year from duplicated case number in Mainframe')
    plt.grid(axis='y', alpha=0.75)
    plt.show()
    plt.clf()
    
    df_sql_dup_case_nbr['CASE_YEAR_INT'] = df_sql_dup_case_nbr['CASE_YEAR'].astype(int)
    value_counts = df_sql_dup_case_nbr['CASE_YEAR_INT'].value_counts()
    plt.figure(figsize=(8, 6))
    plt.bar(value_counts.index, value_counts.values, color='skyblue', edgecolor='black')
    plt.xlabel('Case Year')
    plt.ylabel('Frequency')
    plt.title('Frequency histogram of case year from duplicated case number in eCollision Analytics SQL')
    plt.grid(axis='y', alpha=0.75)
    plt.show()
    plt.clf()

# Create unique case_number lists from dfs
# All years
unique_case_number_from_mainframe = df_mainframe['case_number'].unique().tolist()
unique_case_number_from_sql = df_sql['CASE_NBR'].unique().tolist()
unique_case_number_from_mainframe_not_in_sql = list(set(unique_case_number_from_mainframe) - set(unique_case_number_from_sql))
unique_case_number_from_sql_not_in_mainframe = list(set(unique_case_number_from_sql) - set(unique_case_number_from_mainframe))

df_mainframe_df_sql_inner_join_on_case_number_year = df_mainframe.merge(df_sql, left_on=['case_number', 'case_year'], right_on=['CASE_NBR', 'CASE_YEAR'], how='inner')
unique_case_number_from_inner_join = df_mainframe_df_sql_inner_join_on_case_number_year['case_number'].unique().tolist()

# Target year
unique_case_number_from_mainframe_yr = df_mainframe_yr['case_number'].unique().tolist()
unique_case_number_from_sql_yr =  df_sql_yr['CASE_NBR'].unique().tolist()
unique_case_number_from_mainframe_not_in_sql_yr = list(set(unique_case_number_from_mainframe_yr) - set(unique_case_number_from_sql_yr))
unique_case_number_from_sql_not_in_mainframe_yr = list(set(unique_case_number_from_sql_yr) - set(unique_case_number_from_mainframe_yr))

df_mainframe_yr_df_sql_yr_inner_join_on_case_number_year = df_mainframe_yr.merge(df_sql_yr, left_on=['case_number', 'case_year'], right_on=['CASE_NBR', 'CASE_YEAR'], how='inner')
unique_case_number_from_inner_join_yr = df_mainframe_yr_df_sql_yr_inner_join_on_case_number_year['case_number'].unique().tolist()

# Describe entire dfs (including all the years, i.e., 2000, 2001, 2002, 2014, 2015, 2016)
if print_switch:
    print('/////')
    print('// Control panel setting //')
    print('/////')
    pandas_output_setting()
    print(
        'select_year =', select_year, '\n'
        'all_year_switch =', all_year_switch, '\n',
    )
    print('/////')
    print('// Multiple years //')
    print('/////')
    print('// Mainframe //')
    print(df_mainframe.head())
    print(df_mainframe.tail())
    print(f"No. of row in {'df_mainframe'}: {len(df_mainframe)}")
    print(f"No. of duplicate in {'case_number'}: {count_duplicate(df_mainframe, 'case_number')}")
    print(f"No. of duplicate in {'police_file_number'}: {count_duplicate(df_mainframe, 'police_file_number')}")
    print(f"No. of duplicate in {'case_number and case_year'}: {count_duplicate(df_mainframe, ['case_number', 'case_year'])}")
    print(f"No. of duplicate in {'case_number and police_file_number'}: {count_duplicate(df_mainframe, ['case_number', 'police_file_number'])}")
    
    print('/////')
    print('// Analytics SQL //')
    print(df_sql.head())
    print(df_sql.tail())
    print(f"No. of row in {'df_sql'}: {len(df_sql)}")
    print(f"No. of duplicate in {'COLLISION_ID'}: {count_duplicate(df_sql, 'COLLISION_ID')}")
    print(f"No. of duplicate in {'CASE_NBR'}: {count_duplicate(df_sql, 'CASE_NBR')}")
    print(f"No. of duplicate in {'PFN_FILE_NBR'}: {count_duplicate(df_sql, 'PFN_FILE_NBR')}")
    print(f"No. of duplicate in {'CASE_NBR and CASE_YEAR'}: {count_duplicate(df_sql, ['CASE_NBR', 'CASE_YEAR'])}")
    print(f"No. of duplicate in {'CASE_NBR and PFN_FILE_NBR'}: {count_duplicate(df_sql, ['CASE_NBR', 'PFN_FILE_NBR'])}")
    print(f"No. of duplicate in {'CASE_NBR and FORM_CASE_NBR'}: {count_duplicate(df_sql, ['CASE_NBR', 'FORM_CASE_NBR'])}")

# Describe the duplicates
    show_dup_row_n = 14
    print('/////')
    print('// Duplicates //')
    print('/////')
    print('// Mainframe - duplicated case_number //')
    print(df_mainframe_dup_case_number.head(show_dup_row_n))
    print('//')
    
    print('// Mainframe - duplicated police_file_number //')
    print(df_mainframe_dup_police_file_number.head(show_dup_row_n))
    print('//')
    
    print('// Analytics SQL - duplicated COLLISION_ID //')
    print(df_sql_dup_collision_id.head(show_dup_row_n))
    print('//')
    
    print('// Analytics SQL - duplicated CASE_NBR //')
    print(df_sql_dup_case_nbr.head(show_dup_row_n))
    print('//')
    
    print('// Analytics SQL - duplicated PFN_FILE_NBR //')
    print(df_sql_dup_pfn_file_nbr.head(show_dup_row_n))
    print('//')

# Describe filtered dfs by specified year
if print_switch:
    print('/////')
    print(f'// Target year {select_year} //')
    print('/////')
    print('// Mainframe //')
    print(df_mainframe_yr.head())
    print(df_mainframe_yr.tail())
    print(f"No. of row in {'df_mainframe_yr'}: {len(df_mainframe_yr)}")
    print(f"No. of duplicate in {'case_number'}: {count_duplicate(df_mainframe_yr, 'case_number')}")
    print(f"No. of duplicate in {'police_file_number'}: {count_duplicate(df_mainframe_yr, 'police_file_number')}")
    print(f"No. of duplicate in {'case_number and case_year'}: {count_duplicate(df_mainframe_yr, ['case_number', 'case_year'])}")
    print(f"No. of duplicate in {'case_number and police_file_number'}: {count_duplicate(df_mainframe_yr, ['case_number', 'police_file_number'])}")

    print('/////')
    print('// Analytics SQL //')
    print(df_sql_yr.head())
    print(df_sql_yr.tail())
    print(f"No. of row in {'df_sql_yr'}: {len(df_sql_yr)}")
    print(f"No. of duplicate in {'COLLISION_ID'}: {count_duplicate(df_sql_yr, 'COLLISION_ID')}")
    print(f"No. of duplicate in {'CASE_NBR'}: {count_duplicate(df_sql_yr, 'CASE_NBR')}")
    print(f"No. of duplicate in {'PFN_FILE_NBR'}: {count_duplicate(df_sql_yr, 'PFN_FILE_NBR')}")
    print(f"No. of duplicate in {'CASE_NBR and CASE_YEAR'}: {count_duplicate(df_sql_yr, ['CASE_NBR', 'CASE_YEAR'])}")
    print(f"No. of duplicate in {'CASE_NBR and PFN_FILE_NBR'}: {count_duplicate(df_sql_yr, ['CASE_NBR', 'PFN_FILE_NBR'])}")
    print(f"No. of duplicate in {'CASE_NBR and FORM_CASE_NBR'}: {count_duplicate(df_sql_yr, ['CASE_NBR', 'FORM_CASE_NBR'])}")

# Compare between two dfs
if print_switch:
    print('/////')
    print('// Multiple years //')
    print('// Based on matching case_number and case_year')
    print('// Inner join //')
    print('No. of rows of inner joined df, n=', len(df_mainframe_df_sql_inner_join_on_case_number_year))
    print(df_mainframe_df_sql_inner_join_on_case_number_year.head())
    print('Unique case_number - from inner join, n=', len(unique_case_number_from_inner_join))
    print('//')
    print('Unique case_number - from df_mainframe, n=', len(unique_case_number_from_mainframe))
    print('Unique case_number - from df_sql, n=', len(unique_case_number_from_sql))
    print('Unique case_number - from df_mainframe that are not in df_sql, n=', len(unique_case_number_from_mainframe_not_in_sql))
    print('Examples:', unique_case_number_from_mainframe_not_in_sql[0:10])
    print('Unique case_number - from df_sql that are not in df_mainframe, n=', len(unique_case_number_from_sql_not_in_mainframe))
    print('Examples:', unique_case_number_from_sql_not_in_mainframe[0:10])

    print('/////')
    print(f'// Target year {select_year} //')
    print('// Inner join //')
    print(len(df_mainframe_yr_df_sql_yr_inner_join_on_case_number_year))
    print(df_mainframe_yr_df_sql_yr_inner_join_on_case_number_year.head())
    print('Unique case_number, n=', len(unique_case_number_from_inner_join_yr))
    print('//')
    print('Unique case_number - from df_mainframe_yr, n=', len(unique_case_number_from_mainframe_yr))
    print('Unique case_number - from df_sql_yr, n=', len(unique_case_number_from_sql_yr))
    print('Unique case_number - from df_mainframe_yr that are not in df_sql_yr, n=', len(unique_case_number_from_mainframe_not_in_sql_yr))
    print('Examples:', unique_case_number_from_mainframe_not_in_sql_yr[0:10])
    print('Unique case_number - from df_sql_yr that are not in df_mainframe_yr, n=', len(unique_case_number_from_sql_not_in_mainframe_yr))
    print('Examples:', unique_case_number_from_sql_not_in_mainframe_yr[0:10])
    
if save_all_year_output_switch:
    # For outputting discrepency of unique case_number
    output_folder = "output"
    os.makedirs(output_folder, exist_ok=True)
    
    unique_case_number_var_list = [
        (unique_case_number_from_mainframe_not_in_sql, f'unique_case_number_from_mainframe_not_in_sql_allYearSwitch{all_year_switch}.csv'),
        (unique_case_number_from_sql_not_in_mainframe, f'unique_case_number_from_sql_not_in_mainframe_allYearSwitch{all_year_switch}.csv'),
    ]
    
    for unique_case_number_list in unique_case_number_var_list:
        df_temp = pd.DataFrame(unique_case_number_list[0], columns=['unique_case_number'])
        csv_file_path = os.path.join(output_folder, unique_case_number_list[1])
        df_temp.to_csv(csv_file_path, index=False, header=False)
    
    # For outputting duplicates by certain column
    df_mainframe_dup_case_number = get_sorted_duplicates(df_mainframe, 'case_number')
    df_sql_dup_case_nbr = get_sorted_duplicates(df_sql, 'CASE_NBR')
    
    output_path_mainframe_dup_case_number = os.path.join(output_folder, f"df_mainframe_dup_case_number_allYearSwitch{all_year_switch}.csv")
    output_path_sql_dup_case_nbr = os.path.join(output_folder, f"df_sql_dup_case_nbr_allYearSwitch{all_year_switch}.csv")

    # Save DataFrames to CSV
    df_mainframe_dup_case_number.to_csv(output_path_mainframe_dup_case_number, index=False, header=True)
    df_sql_dup_case_nbr.to_csv(output_path_sql_dup_case_nbr, index=False, header=True)

if save_select_year_output_switch:
    # For outputting discrepency of unique case_number
    output_folder = "output"
    os.makedirs(output_folder, exist_ok=True)
    
    unique_case_number_var_list = [
        (unique_case_number_from_mainframe_not_in_sql_yr, f'unique_case_number_from_mainframe_not_in_sql_{select_year}.csv'),
        (unique_case_number_from_sql_not_in_mainframe_yr, f'unique_case_number_from_sql_not_in_mainframe_{select_year}.csv'),
    ]
    
    for unique_case_number_list in unique_case_number_var_list:
        df_temp = pd.DataFrame(unique_case_number_list[0], columns=['unique_case_number'])
        csv_file_path = os.path.join(output_folder, unique_case_number_list[1])
        df_temp.to_csv(csv_file_path, index=False, header=False)
        
if all_year_switch:
    if save_all_year_output_switch:
        output_folder = "output"
        os.makedirs(output_folder, exist_ok=True)
    
        df_discrepancy = df_mainframe_full[df_mainframe_full['case_number'].isin(unique_case_number_from_mainframe_not_in_sql)]
        csv_file_path = os.path.join(output_folder, 'df_mainframe_case_number_not_in_df_sql.csv')
        df_discrepancy.to_csv(csv_file_path, index=False, header=True)
