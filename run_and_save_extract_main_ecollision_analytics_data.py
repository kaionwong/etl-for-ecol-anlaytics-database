import pandas as pd
import numpy as np
import os
from datetime import datetime

from helper_db_operation import eCollisionAnalyticsDB

# Control panel
save_switch = True # WARNING: this may overwrite existing file if they are run within the same date

if __name__ == '__main__':
    # Determine the base path dynamically based on the script location
    base_path = os.path.dirname(os.path.abspath(__file__))    

    # Get today's date in yyyy-mm-dd format
    current_date = datetime.now().strftime('%Y-%m-%d')

    # For eCollision Analtyics db
    # Select the SQL query to execute; options below:
    sql_analytics_test_query = os.path.join(base_path, 'extract_main_ecollision_analytics_data.sql')
    
    db_analytics = eCollisionAnalyticsDB()
    analytics_query = db_analytics.load_query_from_file(sql_analytics_test_query)
    analytics_query_result = db_analytics.query_without_param(analytics_query)
    db_analytics.close_connection()
    
    # convert the query result to a Pandas DataFrame
    header_analytics, data_analytics = analytics_query_result[0], analytics_query_result[1]
    data_reshaped_analytics = np.array(data_analytics).reshape(-1, len(header_analytics))
    
    df_analytics = pd.DataFrame(data_reshaped_analytics, columns=header_analytics)
    
    print(df_analytics.head())
    
    if save_switch:
        # Create the output directory if it doesn't exist
        output_dir = os.path.join(base_path, 'data')
        os.makedirs(output_dir, exist_ok=True)

        # Save the DataFrame to a CSV file with the current date in the filename
        analytics_filename = os.path.join(output_dir, f'main_extract_ecollision_analytics_data_2000_onward_snapshot_from_{current_date}.csv')
        df_analytics.to_csv(analytics_filename, index=False)

        print(f"Data saved to {analytics_filename}")