import streamlit as st
from create_df_from_sql_connection import df_agg

# Title of the app
st.title('Collision Data Analysis')

# Display the DataFrame
st.write("### Data Overview")
st.dataframe(df_agg)

# # Filter options
# st.sidebar.header("Filter Options")
# selected_year = st.sidebar.selectbox('Select Year', df_agg['CASE_YEAR'].unique())
# selected_city = st.sidebar.selectbox('Select City', df_agg['CITY'].unique())

# # Filter DataFrame based on user input
# filtered_df = df_agg[(df_agg['CASE_YEAR'] == selected_year) & (df_agg['CITY'] == selected_city)]

# # Display the filtered DataFrame
# st.write(f"### Data for {selected_year} in {selected_city}")
# st.dataframe(filtered_df)

# # Plotting (Optional)
# st.write("### Plotting")
# st.bar_chart(filtered_df.groupby('CATEGORY')['COUNT'].sum())