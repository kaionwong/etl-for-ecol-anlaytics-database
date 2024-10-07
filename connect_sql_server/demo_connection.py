import cx_Oracle
from dotenv import load_dotenv
import os

# load secrets
load_dotenv()
username = os.getenv('ECOLLISION_ORACLE_SQL_USERNAME')
user_password = os.getenv('ECOLLISION_ORACLE_SQL_PASSWORD')

# control panel
n_row_to_print = 10

# set up for Oracle SQL db connection
oracle_instant_client_dir = 'C:\\Users\\first_name.last_name\\_local_dev\\oracle_instant_client\\instantclient-basic-windows.x64-23.1.2.33.55\\instantclient_23_8'
cx_Oracle.init_oracle_client(lib_dir=oracle_instant_client_dir)

db_host = 'database.hostname'
db_port = 1234
db_service_name = 'database.service_name'

conn_info = {
    'host': db_host,
    'port': db_port,
    'user': username,
    'psw': user_password,
    'service': db_service_name
}

conn_str = '{user}/{psw}@//{host}:{port}/{service}'.format(**conn_info)

sql_query = '''
    select
        *
    from
        ecrdba.cl_status_history
    where 1=1
        and id > 9010000
'''

class DB:
    def __init__(self):
        self.conn = cx_Oracle.connect(conn_str)

    def query_with_param(self, query, params=None):
        cursor = self.conn.cursor()
        result = cursor.execute(query, params).fetchall()
        cursor.close()
        return result
    
    def query_without_param(self, query):
        cursor = self.conn.cursor()
        result = cursor.execute(query).fetchall()
        cursor.close()
        return result
    
    def close_connection(self):
        self.conn.close()
    
db = DB()
result = db.query_without_param(sql_query)

row_count = 0
for row in result:
    if row_count <= n_row_to_print:
        print (row)
        row_count += 1

print('Finished!')

db.close_connection()