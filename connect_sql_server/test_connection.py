import oracledb
from dotenv import load_dotenv
import os

# load secrets
load_dotenv()
username = os.getenv('ECOLLISION_ORACLE_SQL_USERNAME')
user_password = os.getenv('ECOLLISION_ORACLE_SQL_PASSWORD')
oracle_host = os.getenv('ECOLLISION_ORACLE_SQL_HOST_NAME')
oracle_port = os.getenv('ECOLLISION_ORACLE_SQL_PORT')
oracle_service = os.getenv('ECOLLISION_ORACLE_SQL_SERVICE_NAME')

# control panel
n_row_to_print = 10

# set up for Oracle SQL db connection
oracle_instant_client_dir = r'C:\Users\kai.wong\_local_dev\oracle_instant_client\instantclient-basic-windows.x64-23.5.0.24.07\instantclient_23_5'
# If you have the Instant Client installed, init it; otherwise oracledb will run in thin mode.
try:
    if os.path.isdir(oracle_instant_client_dir):
        oracledb.init_oracle_client(lib_dir=oracle_instant_client_dir)
    else:
        print('Oracle Instant Client not found at', oracle_instant_client_dir, '- using thin mode (no Instant Client required).')
except Exception as e:
    print('Could not initialize Oracle Instant Client:', e)

conn_info = {
    'host': oracle_host,
    'port': oracle_port,
    'user': username,
    'psw': user_password,
    'service': oracle_service
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
        # oracledb.connect accepts the same connection string format as cx_Oracle
        self.conn = oracledb.connect(conn_str)

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