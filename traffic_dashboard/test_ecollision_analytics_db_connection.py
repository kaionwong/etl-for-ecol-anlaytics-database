import pyodbc
import pandas as pd
import numpy as np
import os

# control panel
n_row_to_print = 1000
query_city = 'edmonton' # options: 'edmonton', 'calgary'
query_agg = False # options: True, False
print_switch = False

# select the sql query to execute; options below:
base_path = 'M:\\SPE\\OTS\\Stats-OTS\\Kai\\git_repo\\ecollision_analytics_assessment\\ecollision-analytics-assessment\\traffic_dashboard\\'

sql_query_to_execute_edmonton_not_agg = os.path.join(base_path, f'query_ecollision_analytics_city=edmonton_agg=false.sql')
sql_query_to_execute_calgary_not_agg = os.path.join(base_path, f'query_ecollision_analytics_city=calgary_agg=false.sql')
sql_query_to_execute_edmonton_agg = os.path.join(base_path, f'query_ecollision_analytics_city=edmonton_agg=true.sql')
sql_query_to_execute_calgary_agg = os.path.join(base_path, f'query_ecollision_analytics_city=calgary_agg=true.sql')
sql_query_to_execute_simple_test = os.path.join(base_path, f'query_ecollision_analytics_test.sql')

# set up for eCollision Analytics SQL db connection
db_driver = '{SQL Server Native Client 11.0}'
db_server = 'EDM-GOA-SQL-712\\AT51PRD'
db_name = 'eCollisionAnalytics'
db_trusted_connection = 'yes'

conn_str = ''
conn_str += f'Driver={db_driver};'
conn_str += f'Server={db_server};'
conn_str += f'Database={db_name};'
conn_str += f'Trusted_Connection={db_trusted_connection};'

class DB:
    def __init__(self):
        self.conn = pyodbc.connect(conn_str)
        
    def query_with_param(self, query, params=None):
        cursor = self.conn.cursor()
        result = cursor.execute(query, params).fetchall()
        header = [i[0] for i in cursor.description]
        cursor.close()
        return header, result
    
    def query_without_param(self, query):
        cursor = self.conn.cursor()
        result = cursor.execute(query).fetchall()
        header = [i[0] for i in cursor.description]
        cursor.close()
        return header, result
    
    def load_query_from_file(self, file_path):
        with open(file_path, 'r') as file:
            return file.read()
    
    def close_connection(self):
        self.conn.close()

######
# connect to eCollision Analytics SQL db, and create df_edmonton_agg
db = DB()
sql_query_edmonton_agg = db.load_query_from_file(sql_query_to_execute_edmonton_agg)
result_edmonton_agg = db.query_without_param(sql_query_edmonton_agg)
db.close_connection()

# convert the query result to a Pandas DataFrame
header, data = result_edmonton_agg[0], result_edmonton_agg[1]
data_reshaped = np.array(data).reshape(-1, len(header))

df_edmonton_agg = pd.DataFrame(data_reshaped, columns=header)
df_edmonton_agg.rename(columns={'TABLENAME': 'TABLE_NAME', 'TABLEORDER': 'TABLE_ORDER'}, inplace=True)
df_edmonton_agg['CITY'] = 'Edmonton'

# clear variables
del db, header, data

# connect to eCollision Analytics SQL db, and create df_calgary_agg
db = DB()
sql_query_calgary_agg = db.load_query_from_file(sql_query_to_execute_calgary_agg)
result_calgary_agg = db.query_without_param(sql_query_calgary_agg)
db.close_connection()

# convert the query result to a Pandas DataFrame
header, data = result_calgary_agg[0], result_calgary_agg[1]
data_reshaped = np.array(data).reshape(-1, len(header))

df_calgary_agg = pd.DataFrame(data_reshaped, columns=header)
df_calgary_agg.rename(columns={'TABLENAME': 'TABLE_NAME', 'TABLEORDER': 'TABLE_ORDER'}, inplace=True)
df_calgary_agg['CITY'] = 'Calgary'

# mrege df_edmonton_agg and df_calgary_agg
df_agg = pd.concat([df_edmonton_agg, df_calgary_agg], ignore_index=True)
df_agg.reset_index(drop=True, inplace=True)

if __name__ == '__main__':
    print(df_agg.head())
    print(df_agg.tail())