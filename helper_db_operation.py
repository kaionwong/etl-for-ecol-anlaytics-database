import cx_Oracle
import pyodbc
import pandas as pd
import numpy as np
from dotenv import load_dotenv
import os

############
############
############
# eCollision Oracle database
# load secrets
load_dotenv()
username = os.getenv('ECOLLISION_ORACLE_SQL_USERNAME')
user_password = os.getenv('ECOLLISION_ORACLE_SQL_PASSWORD')
oracle_host = os.getenv('ECOLLISION_ORACLE_SQL_HOST_NAME')
oracle_port = os.getenv('ECOLLISION_ORACLE_SQL_PORT')
oracle_service = os.getenv('ECOLLISION_ORACLE_SQL_SERVICE_NAME')

conn_info = {
    'host': oracle_host,
    'port': oracle_port,
    'user': username,
    'psw': user_password,
    'service': oracle_service
}

conn_str_oracle = '{user}/{psw}@//{host}:{port}/{service}'.format(**conn_info)

# set up for eCollision Oracle SQL db connection
oracle_instant_client_dir = os.getenv('ORACLE_INSTANT_CLIENT_DIR')
cx_Oracle.init_oracle_client(lib_dir=oracle_instant_client_dir)

class eCollisionOracleDB:
    def __init__(self):
        self.conn = cx_Oracle.connect(conn_str_oracle)

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

############
############
############
# eCollision Analytics database
# set up for eCollision Analytics SQL db connection
db_driver = os.getenv('ECOLLISION_ANALYTICS_SQL_DRIVER')
db_server = os.getenv('ECOLLISION_ANALYTICS_SQL_SERVER').replace('\\\\', '\\')
db_name = os.getenv('ECOLLISION_ANALYTICS_SQL_DATABASE_NAME')
db_trusted_connection = os.getenv('ECOLLISION_ANALYTICS_SQL_TRUSTED_CONNECTION')

conn_str_analytics = ''
conn_str_analytics += f'Driver={db_driver};'
conn_str_analytics += f'Server={db_server};'
conn_str_analytics += f'Database={db_name};'
conn_str_analytics += f'Trusted_Connection={db_trusted_connection};'

class eCollisionAnalyticsDB:
    def __init__(self):
        self.conn = pyodbc.connect(conn_str_analytics)
        
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

if __name__ == '__main__':
    # Determine the base path dynamically based on the script location
    base_path = os.path.dirname(os.path.abspath(__file__))    
    
    #############
    #############
    #############
    # For eCollision Oracle db
    # Select the SQL query to execute; options below:
    # sql_oracle_test_query = os.path.join(base_path, 'extract_ecollision_oracle_with_upload_pending_or_uploaded_on_cutoff_date.sql')
    
    # db_oracle = eCollisionOracleDB()
    # oracle_query = db_oracle.load_query_from_file(sql_oracle_test_query)
    # oracle_query_result = db_oracle.query_without_param(oracle_query)
    # db_oracle.close_connection()
    
    # # convert the query result to a Pandas DataFrame
    # header_oracle, data_oracle = oracle_query_result[0], oracle_query_result[1]
    # data_reshaped_oracle = np.array(data_oracle).reshape(-1, len(header_oracle))
    
    # df_oracle = pd.DataFrame(data_reshaped_oracle, columns=header_oracle)
    
    # print(df_oracle.head())

    #############
    #############
    #############
    # For eCollision Analytics db
    # Select the SQL query to execute; options below:
    # sql_oracle_test_query = os.path.join(base_path, 'extract_main_ecollision_analytics_data.sql')
    
    # db_analytics = eCollisionAnalyticsDB()
    # analytics_query = db_analytics.load_query_from_file(sql_oracle_test_query)
    # analytics_query_result = db_analytics.query_without_param(analytics_query)
    # db_analytics.close_connection()
    
    # # convert the query result to a Pandas DataFrame
    # header_analytics, data_analytics = analytics_query_result[0], analytics_query_result[1]
    # data_reshaped_analytics = np.array(data_analytics).reshape(-1, len(header_analytics))
    
    # df_analytics = pd.DataFrame(data_reshaped_analytics, columns=header_analytics)
    
    # print(df_analytics.head())
    
    pass