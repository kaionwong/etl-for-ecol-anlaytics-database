import oracledb
import pandas as pd
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
n_row_to_print = 1000
query_city = 'edmonton' # options: 'edmonton', 'calgary'
query_agg = False # options: True, False
print_switch = False

# select the sql query to execute; options below:
base_path = os.path.dirname(os.path.abspath(__file__))

# sql_query_to_execute = 'traffic_dashboard/test_query.sql'
# sql_query_to_execute = f'traffic_dashboard/test_ecollision_oracle_for_analytics_v5_city={query_city}_agg={str(query_agg).lower()}.sql'
sql_query_to_execute_edmonton_not_agg = os.path.join(base_path, f'query_ecollision_oracle_for_analytics_v5_city=edmonton_agg=false.sql')
sql_query_to_execute_calgary_not_agg = os.path.join(base_path, f'query_ecollision_oracle_for_analytics_v5_city=calgary_agg=false.sql')
sql_query_to_execute_edmonton_agg = os.path.join(base_path, f'query_ecollision_oracle_for_analytics_v5_city=edmonton_agg=true.sql')
sql_query_to_execute_calgary_agg = os.path.join(base_path, f'query_ecollision_oracle_for_analytics_v5_city=calgary_agg=true.sql')

# set up for Oracle SQL db connection (using oracledb thin mode - no Instant Client required)
# If you need thick mode with Instant Client, uncomment:
# oracle_instant_client_dir = 'C:\\Users\\kai.wong\\_local_dev\\oracle_instant_client\\instantclient-basic-windows.x64-23.5.0.24.07\\instantclient_23_5'
# oracledb.init_oracle_client(lib_dir=oracle_instant_client_dir)

conn_info = {
    'host': oracle_host,
    'port': oracle_port,
    'user': username,
    'psw': user_password,
    'service': oracle_service
}

conn_str = '{user}/{psw}@//{host}:{port}/{service}'.format(**conn_info)

class DB:
    def __init__(self):
        self.conn = oracledb.connect(user=username, password=user_password, 
                                      host=oracle_host, port=int(oracle_port), 
                                      service_name=oracle_service)

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
# Attempt to connect to Oracle SQL db
# Fallback to sample data if environment variables are missing or connection fails

def create_sample_df():
    """Create a sample DataFrame for testing when DB is unavailable."""
    sample_data = {
        'CASE_YEAR': [2020, 2021, 2022, 2023, 2024, 2020, 2021, 2022, 2023, 2024],
        'CATEGORY': ['Type A', 'Type A', 'Type A', 'Type A', 'Type A', 'Type B', 'Type B', 'Type B', 'Type B', 'Type B'],
        'COUNT': [150, 175, 200, 180, 210, 100, 120, 140, 130, 155],
        'TABLE_NAME': ['Analytics', 'Analytics', 'Analytics', 'Analytics', 'Analytics', 'Oracle', 'Oracle', 'Oracle', 'Oracle', 'Oracle'],
        'TABLE_ORDER': [1, 1, 1, 1, 1, 2, 2, 2, 2, 2],
        'CITY': ['Edmonton', 'Edmonton', 'Edmonton', 'Edmonton', 'Edmonton', 'Calgary', 'Calgary', 'Calgary', 'Calgary', 'Calgary']
    }
    return pd.DataFrame(sample_data)

try:
    # Check if all required environment variables are set
    if not all([username, user_password, oracle_host, oracle_port, oracle_service]):
        print("⚠️  Warning: Missing Oracle environment variables. Using sample data.")
        raise ValueError("Incomplete Oracle credentials")
    
    # connect to Oracle SQL db, and create df_edmonton_agg
    db = DB()
    sql_query_edmonton_agg = db.load_query_from_file(sql_query_to_execute_edmonton_agg)
    result_edmonton_agg = db.query_without_param(sql_query_edmonton_agg)
    db.close_connection()

    # convert the query result to a Pandas DataFrame
    header, data = result_edmonton_agg[0], result_edmonton_agg[1]
    df_edmonton_agg = pd.DataFrame(data, columns=header)
    df_edmonton_agg.rename(columns={'TABLENAME': 'TABLE_NAME', 'TABLEORDER': 'TABLE_ORDER'}, inplace=True)
    df_edmonton_agg['CITY'] = 'Edmonton'

    # connect to Oracle SQL db, and create df_calgary_agg
    db = DB()
    sql_query_calgary_agg = db.load_query_from_file(sql_query_to_execute_calgary_agg)
    result_calgary_agg = db.query_without_param(sql_query_calgary_agg)
    db.close_connection()

    # convert the query result to a Pandas DataFrame
    header, data = result_calgary_agg[0], result_calgary_agg[1]
    df_calgary_agg = pd.DataFrame(data, columns=header)
    df_calgary_agg.rename(columns={'TABLENAME': 'TABLE_NAME', 'TABLEORDER': 'TABLE_ORDER'}, inplace=True)
    df_calgary_agg['CITY'] = 'Calgary'

    # merge df_edmonton_agg and df_calgary_agg
    df_agg = pd.concat([df_edmonton_agg, df_calgary_agg], ignore_index=True)
    df_agg.reset_index(drop=True, inplace=True)
    
except Exception as e:
    print(f"⚠️  Failed to connect to Oracle database: {e}")
    print("    Using sample data instead. Set environment variables to connect to the real database.")
    df_agg = create_sample_df()

if __name__ == '__main__':
    print(df_agg.head())
    print(df_agg.tail())
    