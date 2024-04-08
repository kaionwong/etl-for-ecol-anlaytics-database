import pandas as pd
import helper

helper.pandas_output_setting()

def single_collision_record_search(df, varname, test_input):
    """
    Search for a single collision record based on the given test input.

    Parameters:
    - df (pandas.DataFrame): DataFrame containing collision records.
    - varname (str): Name of the variable/column to search in.
    - test_input (str or numeric): Value to search for.

    Returns:
    pandas.DataFrame: DataFrame containing the matched records.
    """
    if isinstance(test_input, (int, float)):
        # If test_input is numeric, perform direct equality check
        record = df[df[varname] == test_input]
    elif isinstance(test_input, str):
        # If test_input is a string, perform substring matching
        record = df[df[varname].astype(str).str.contains(test_input, na=False)]
    else:
        # Invalid test_input type
        raise ValueError("Invalid test_input type. Must be either string or numeric.")

    return record
        
filename0 = 'mainframe_extract_collisions_2001.csv'
filename = 'main_extract_ecollision_analytics_data_2000-2021_snapshot_from_2024-03-xx.csv'
filename2 = 'main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-03-28.csv'
filename3 = 'main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-04-02.csv'
filename4 = 'main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-04-07.csv'

test_var = 'CASE_NBR' # 'case_number'; 'CASE_NBR'
test_string = '1406432'
used_filename = filename4 # select data file to load

df = pd.read_csv(used_filename)

print(df.head())
# print(df.tail())
# print(len(df))
# print(df['CASE_YEAR'].value_counts())
# print()

print()
print(f'Used filename: {used_filename}')
print(f'Number of rows in df: {len(df)}')
print(f'Test var: {test_var}; test string: {test_string}')
print(single_collision_record_search(
    df=df,
    varname=test_var,
    test_input=test_string
))
