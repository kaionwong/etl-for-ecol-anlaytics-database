import pyodbc
import pandas as pd
import numpy as np
import os

# control panel
n_row_to_print = 1000
print_switch = False

# select the sql query to execute; options below:
base_path = 'M:\\SPE\\OTS\\Stats-OTS\\Kai\\git_repo\\ecollision_analytics_assessment\\ecollision-analytics-assessment\\traffic_dashboard\\'

db_driver = '{SQL Server Native Client 11.0}'
db_server = 'C-GOA-SQL-10113'
db_name = 'OTS_Fiscal'
db_trusted_connection = 'yes'

conn_str = ''
conn_str += f'Driver={db_driver};'
conn_str += f'Server={db_server};'
conn_str += f'Database={db_name};'
conn_str += f'Trusted_Connection={db_trusted_connection};'

print(conn_str)

conn = pyodbc.connect(conn_str)

cursor = conn.cursor()
cursor.execute('SELECT TOP 10 * FROM dbo.PYYEO01')

for row in cursor:
    print('row = %r' % (row,))





#######
# control panel
n_row_to_print = 1000
print_switch = False

# select the sql query to execute; options below:
base_path = 'M:\\SPE\\OTS\\Stats-OTS\\Kai\\git_repo\\ecollision_analytics_assessment\\ecollision-analytics-assessment\\traffic_dashboard\\'

# sql_query_to_execute


# set up for eCollision Analytics SQL db connection
db_driver = '{SQL Server Native Client 11.0}'
db_server = 'C-GOA-SQL-10113'
db_name = 'OTS_Fiscal'
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