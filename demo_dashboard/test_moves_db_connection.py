import pyodbc
import pandas as pd
import numpy as np
import os

# control panel
n_row_to_print = 1000
print_switch = False

# select the sql query to execute; options below:
base_path = os.getenv('DEMO_DASHBOARD_BASE_PATH')

# sql_query_to_execute
sql_query_to_execute_test = os.path.join(base_path, f'query_moves_test.sql')

# set up for eCollision Analytics SQL db connection
db_driver = os.getenv('MOVES_SQL_DRIVER')
db_server = os.getenv('MOVES_SQL_SERVER').replace('\\\\', '\\')
db_name = os.getenv('MOVES_SQL_DATABASE_NAME')
db_trusted_connection = os.getenv('MOVES_SQL_TRUSTED_CONNECTION')

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
sql_query = db.load_query_from_file(sql_query_to_execute_test)
result = db.query_without_param(sql_query)
db.close_connection()

# convert the query result to a Pandas DataFrame
header, data = result[0], result[1]
data_reshaped = np.array(data).reshape(-1, len(header))

df = pd.DataFrame(data_reshaped, columns=header)

if __name__ == '__main__':
    print(df.head())
    print(df.tail())