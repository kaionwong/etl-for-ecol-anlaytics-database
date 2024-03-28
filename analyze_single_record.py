import pandas as pd
import helper

helper.pandas_output_setting()

filename = 'main_extract_ecollision_analytics_data_2000-2021_snapshot_from_2024.csv'
filename2 = 'main_extract_ecollision_analytics_data_2000-2024_snapshot_from_2024-03-28.csv'
test_string = '1446991'

df = pd.read_csv(filename2)

print(df.head())
print(df.tail())
print(len(df))
print(df['CASE_YEAR'].value_counts())
print()

record = df[df['CASE_NBR'].str.contains(test_string, na=False)]
print(record)

