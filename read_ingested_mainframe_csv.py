# This script is to export information about the column name so it can be compared directly with the possible matching column in eCollision Analytics SQL server.

import pandas as pd

mainframe_category = 'collisions'
mainframe_year = '2000'
varname = 'highway_legal_class'

filename = f'mainframe_extract_{mainframe_category}_{mainframe_year}.csv'

df = pd.read_csv(filename, header=0, delimiter=',')

print(df.head())

if varname:
    print('/////')
    print('year ', mainframe_year)
    print('/////')
    print(df[varname].head())
    print(df[varname].tail())
    print('/////')
    print(df[varname].info())
    print('/////')
    print('unique value count   ', df[varname].nunique())
    try:
        print('mode value           ', df[varname].mode().iloc[0])
    except:
        print('mode value           Null')
    print(df[varname].describe())
    
    # Additional output for top 5 most frequently occurring values
    print('/////')
    print('Top 5 Values:')
    print(df[varname].value_counts().head())
    print('Least 5 Values:')
    print(df[varname].value_counts().tail())