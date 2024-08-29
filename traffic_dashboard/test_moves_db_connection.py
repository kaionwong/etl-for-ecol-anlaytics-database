import pyodbc
import pandas as pd
from dotenv import load_dotenv
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
