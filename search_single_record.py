import pandas as pd
import helper

helper.pandas_output_setting()

def single_collision_record_search(df, test_input, varname=None):
    if varname:
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
    
    else: # if 'varname is None':
        # Initialize an empty list to store masks for each column
        column_masks = []

        # Iterate over each column in the DataFrame
        for column in df.columns:
            # Apply a mask to check if the column values contain the test_input as a substring
            column_mask = df[column].astype(str).str.contains(test_input, na=False)
            # Append the column mask to the list
            column_masks.append(column_mask)

        # Combine all column masks using logical OR to retain rows where any column contains the substring
        combined_mask = pd.concat(column_masks, axis=1).any(axis=1)

        # Filter the DataFrame using the combined mask
        record = df[combined_mask]

        return record

filename_2001_xx_xx = 'mainframe_extract_collisions_2001.csv'
filename_2024_03_xx = 'main_extract_ecollision_analytics_data_2000-2021_snapshot_from_2024-03-xx.csv'
filename_2024_03_28 = 'main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-03-28.csv'
filename_2024_04_02 = 'main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-04-02.csv'
filename_2024_04_07 = 'main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-04-07.csv'
filename_2024_04_09 = 'main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-04-09.csv'
filename_2024_04_19 = 'main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-04-19.csv'
filename_2024_04_24 = 'main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-04-24.csv'
filename_2024_04_25 = 'main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-04-25.csv'

test_var = 'COLLISION_ID' # None; 'case_number'; 'CASE_NBR'; 'COLLISION_ID'; 'PFN_FILE_NBR'
test_string = '2690043'
used_filename = filename_2024_03_28 # select data file to load

df = pd.read_csv(used_filename)

# print(df.head())
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
