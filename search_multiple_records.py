import pandas as pd
import helper_generic

helper_generic.pandas_output_setting()

def multiple_collision_record_search(df, varname, test_input):
    """
    Search for collision records based on the given list of test input values.

    Parameters:
    - df (pandas.DataFrame): DataFrame containing collision records.
    - varname (str): Name of the variable/column to search in.
    - test_input (list): List of values to search for.

    Returns:
    pandas.DataFrame: DataFrame containing the matched records.
    """
    if isinstance(test_input, list):
        # Initialize an empty DataFrame to store matched records
        matched_records = pd.DataFrame()

        for value in test_input:
            if isinstance(value, (int, float)):
                # If value is numeric, perform direct equality check
                record = df[df[varname] == value]
            elif isinstance(value, str):
                # If value is a string, perform substring matching
                record = df[df[varname].astype(str).str.contains(value, na=False)]
            else:
                # Invalid value type
                raise ValueError("Invalid value type in test_input. Must be either string or numeric.")

            # Append matched records to the result DataFrame
            matched_records = pd.concat([matched_records, record])

        return matched_records
    else:
        # Invalid test_input type
        raise ValueError("Invalid test_input type. Must be a list.")
        
filename0 = 'data/mainframe_extract_collisions_2001.csv'
filename = 'data/main_extract_ecollision_analytics_data_2000-2021_snapshot_from_2024-03-xx.csv'
filename2 = 'data/main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-03-28.csv'
filename3 = 'data/main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-04-02.csv'
filename4 = 'data/main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-04-07.csv'

test_var = 'CASE_NBR' # 'case_number'; 'CASE_NBR'; 'COLLISION_ID'; 'PFN_FILE_NBR'
test_strings =  ['1414785', '1447500', '1434165', '1441250', '1406432', '1447195', '1446310', '1448726']
used_filename = filename # select data file to load

df = pd.read_csv(used_filename)

# print(df.head())
# print(df.tail())
# print(len(df))
# print(df['CASE_YEAR'].value_counts())
# print()

print()
print(f'Used filename: {used_filename}')
print(f'Number of rows in df: {len(df)}')
print(f'Test var: {test_var}; test string: {test_strings}')
print(multiple_collision_record_search(
    df=df,
    varname=test_var,
    test_input=test_strings
))
