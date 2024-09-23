import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

import helper

# Helper functions
def value_count_as_percent(df, col):
    print(df[col].value_counts(normalize=True).mul(100).round(1).astype(str) + '%')

helper.pandas_output_setting(max_rows=500)

# Control panel
print_switch = True
graph_switch = True

# Specify the output folder and CSV file name
output_folder = "output"
csv_file_name = "df_mainframe_case_number_not_in_df_sql.csv"

# Get the current working directory
current_directory = os.getcwd()

# Create the full path to the CSV file by joining the current directory, output folder, and file name
csv_file_path = os.path.join(current_directory, output_folder, csv_file_name)

# Read the CSV file into a DataFrame
df = pd.read_csv(csv_file_path)

# Data processing
df['occurrence_date'] = pd.to_datetime(df['occurrence_date'], errors='coerce')

# Create a new column 'year_month' with the desired format
df['year_month'] = df['occurrence_date'].dt.to_period('M')

if print_switch:
    # Display the first few rows of the DataFrame
    print(df.head())
    print(len(df))
    print(df['case_year'].value_counts())
    value_count_as_percent(df, 'case_year')
    print(df['occurrence_month'].value_counts())
    value_count_as_percent(df, 'occurrence_month')
    print(df['occurrence_day_of_week'].value_counts())
    value_count_as_percent(df, 'occurrence_day_of_week')
    print(df['year_month'].value_counts())
    value_count_as_percent(df, 'year_month')
    print(df['collision_severity'].value_counts())
    value_count_as_percent(df, 'collision_severity')
    print(df['municipality'].value_counts())
    value_count_as_percent(df, 'municipality')
    print(df['police_service_code'].value_counts())
    value_count_as_percent(df, 'police_service_code')

if graph_switch:
    # Explore temporal trends in discrepancies
    plt.figure(figsize=(10, 6))
    sns.countplot(x='case_year', data=df, order=df['case_year'].unique().sort())
    plt.title('Temporal Trends in Discrepancies')
    plt.xlabel('Year')
    plt.ylabel('Number of Discrepancies')
    plt.show()

    plt.figure(figsize=(10, 6))
    sns.countplot(x='occurrence_month', data=df, order=df['occurrence_month'].unique().sort())
    plt.title('Temporal Trends in Discrepancies')
    plt.xlabel('Year')
    plt.ylabel('Number of Discrepancies')
    plt.show()

    plt.figure(figsize=(10, 6))
    sns.countplot(x='year_month', data=df, order=df['year_month'])
    plt.title('Temporal Trends in Discrepancies')
    plt.xlabel('Year')
    plt.ylabel('Number of Discrepancies')
    plt.show()

if print_switch:
    # Check data quality for the year 2003
    print('\nFor 2003 only')
    df_2003 = df[df['case_year'] == 2003]

    