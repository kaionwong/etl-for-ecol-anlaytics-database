import pandas as pd

# Helper function
def pandas_output_setting(max_rows=500):
    """Set pandas output display setting"""
    pd.set_option('display.max_rows', max_rows)
    pd.set_option('display.max_columns', None)
    ##pd.set_option('display.max_columns', 500)
    pd.set_option('display.width', 160)
    pd.set_option('display.max_colwidth', None)
    pd.options.mode.chained_assignment = None  # default='warn'
    