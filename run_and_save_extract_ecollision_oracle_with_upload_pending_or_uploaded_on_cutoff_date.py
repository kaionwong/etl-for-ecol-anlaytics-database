import pandas as pd
import numpy as np
import os
from datetime import datetime

from helper_db_operation import eCollisionOracleDB

# Control panel
save_switch = True # WARNING: this may overwrite existing file if they are run within the same date

if __name__ == '__main__':
    # Determine the base path dynamically based on the script location
    base_path = os.path.dirname(os.path.abspath(__file__))    

    # Get today's date in yyyy-mm-dd format
    current_date = datetime.now().strftime('%Y-%m-%d')

    # For eCollision Oracle db
    # Select the SQL query to execute; options below:
    sql_oracle_test_query = os.path.join(base_path, 'extract_ecollision_oracle_with_upload_pending_or_uploaded_on_cutoff_date.sql')
    
    db_oracle = eCollisionOracleDB()
    oracle_query = db_oracle.load_query_from_file(sql_oracle_test_query)
    oracle_query_result = db_oracle.query_without_param(oracle_query)
    db_oracle.close_connection()
    
    # convert the query result to a Pandas DataFrame
    header_oracle, data_oracle = oracle_query_result[0], oracle_query_result[1]
    data_reshaped_oracle = np.array(data_oracle).reshape(-1, len(header_oracle))
    
    df_oracle = pd.DataFrame(data_reshaped_oracle, columns=header_oracle)
    
    print(df_oracle.head())
    
    if save_switch:
        # Create the output directory if it doesn't exist
        output_dir = os.path.join(base_path, 'data')
        os.makedirs(output_dir, exist_ok=True)

        # Save the DataFrame to a CSV file with the current date in the filename
        oracle_filename = os.path.join(output_dir, f'extract_collision_oracle_with_upload_pending_or_uploaded_on_cutoff_date_{current_date}.csv')
        df_oracle.to_csv(oracle_filename, index=False)

        print(f"Data saved to {oracle_filename}")
