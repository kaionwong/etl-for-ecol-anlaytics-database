import streamlit as st
import altair as alt
from create_df_from_ecollision_oracle_db import df_agg

# Filter options
st.sidebar.header("Filter Options")
selected_year = st.sidebar.selectbox('Select Year', df_agg['CASE_YEAR'].unique())
selected_city = st.sidebar.selectbox('Select City', df_agg['CITY'].unique())
selected_table = st.sidebar.selectbox('Select Table', df_agg['TABLE_NAME'].unique())

# Title of the app
st.title(f'Traffic Data Analysis in {selected_city}')

# Filter DataFrame for the selected city and table to include all years
time_series_df = df_agg[(df_agg['CITY'] == selected_city) & 
                        (df_agg['TABLE_NAME'] == selected_table)]

# Create the Altair time series chart
time_series_chart = alt.Chart(time_series_df).mark_line(point=True).encode(
    x=alt.X('CASE_YEAR:O', title='Year'),
    y=alt.Y('sum(COUNT):Q', title='Count'),
    color='CATEGORY:N',  # Different colors for different categories
    tooltip=['CASE_YEAR', 'CATEGORY', 'sum(COUNT)']
).properties(
    width=700,
    height=400,
    title=f'Time Series of Counts for {selected_table} in {selected_city}'
).interactive()

# Display the time series chart
st.altair_chart(time_series_chart, use_container_width=True)

# Filter DataFrame based on user input
filtered_df = df_agg[(df_agg['CASE_YEAR'] == selected_year) & (df_agg['CITY'] == selected_city) & (df_agg['TABLE_NAME'] == selected_table)]

# Plotting (Optional)
st.write(f"### Plotting for {selected_year} in {selected_city} for Table {selected_table}")
st.bar_chart(filtered_df.groupby('CATEGORY')['COUNT'].sum())

# Display the filtered DataFrame
st.write(f"### Data for {selected_year} in {selected_city} for Table {selected_table}")
st.dataframe(filtered_df)

# Display the DataFrame
st.write("### Full Data Table")
st.dataframe(df_agg)

