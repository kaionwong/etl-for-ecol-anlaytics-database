r"""
Edmonton Driver Collision Analysis Dashboard
=============================================

This Streamlit application provides interactive visualization and risk analysis
for driver collisions across Edmonton (2000-2026).

HOW TO RUN:
-----------
1. Activate the virtual environment:
   C:\Users\kai.wong\Dev\virtual_env\venv_etl_for_ecol_analytics\Scripts\Activate.ps1

2. Navigate to the directory:
   cd demo_advanced_analytics\edmonton_driver_collision

3. Run the Streamlit app:
   streamlit run visualize_edmonton_driver_collision.py

   OR using full path:
   C:\Users\kai.wong\Dev\virtual_env\venv_etl_for_ecol_analytics\Scripts\streamlit.exe run visualize_edmonton_driver_collision.py

4. Open browser to:
   http://localhost:8501

REQUIREMENTS:
-------------
- processed_edmonton_driver_collision.csv (in same directory)
- edmonton_driver_risk_analysis.py (in same directory)
- Python packages: streamlit, pandas, plotly

FEATURES:
---------
Tab 1 - Overview Dashboard:
  - Interactive collision map
  - Filters: date range, severity, parked vehicle
  - Time series analysis
  - Severity breakdown
  - Vehicle count distribution

Tab 2 - Risk Analysis:
  - Risk scoring (Vehicles×1 + Injuries×5 + Fatalities×20)
  - Heat map visualization
  - Hexagonal grid risk zones
  - Edmonton zone analysis
  - Temporal risk trends
  - Top 20 highest risk locations

For more details, see README.md
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime
import edmonton_driver_risk_analysis as ra

# Page config
st.set_page_config(
    page_title="Edmonton Driver Collisions",
    page_icon="🚗",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Load data
@st.cache_data(ttl=3600)
def load_data():
    df = pd.read_csv('processed_edmonton_driver_collision.csv', low_memory=False)
    df['OCCURENCE_DATE'] = pd.to_datetime(df['OCCURENCE_TIMESTRING'], errors='coerce', format='%Y/%m/%d')
    # Remove rows with invalid dates
    df = df.dropna(subset=['OCCURENCE_DATE'])
    df['MONTH'] = df['OCCURENCE_DATE'].dt.to_period('M').astype(str)
    df['YEAR_MONTH'] = df['OCCURENCE_DATE'].dt.strftime('%Y-%m')
    # Clean lat/long - remove invalid coordinates
    df = df.dropna(subset=['LOC_GPS_LAT', 'LOC_GPS_LONG'])
    df = df[(df['LOC_GPS_LAT'] >= 53.3) & (df['LOC_GPS_LAT'] <= 53.8)]  # Edmonton latitude range
    df = df[(df['LOC_GPS_LONG'] >= -113.8) & (df['LOC_GPS_LONG'] <= -113.1)]  # Edmonton longitude range
    return df

df = load_data()

# Title
st.title("Edmonton Driver Collision Analysis")
st.markdown("**Interactive visualization of collision patterns across Edmonton (2000-2026)**")

# Create tabs
tab1, tab2 = st.tabs(["Overview Dashboard", "Risk Analysis"])

# ============================================================================
# TAB 1: OVERVIEW DASHBOARD
# ============================================================================
with tab1:
    st.header("Overview Dashboard")
    
    # Sidebar filters
    st.sidebar.header("🔍 Filters")
    
    # Date range filter - Default from 2021-01-01 to latest date
    all_min_date = df['OCCURENCE_DATE'].min().date()
    all_max_date = df['OCCURENCE_DATE'].max().date()
    
    # Set default to 2021-01-01 or earliest available, whichever is later
    default_min = max(all_min_date, pd.Timestamp('2021-01-01').date())
    default_max = all_max_date
    
    date_range = st.sidebar.date_input(
        "Select Date Range",
        value=(default_min, default_max),
        min_value=all_min_date,
        max_value=all_max_date,
        key="tab1_date"
    )
    
    # Severity filter
    severity_options = ['All'] + sorted(df['COLLISION_SEVERITY'].dropna().unique().tolist())
    selected_severity = st.sidebar.multiselect(
        "Collision Severity",
        options=severity_options,
        default=['All'],
        key="tab1_severity"
    )
    
    # Parked vehicle filter
    parked_vehicle = st.sidebar.selectbox(
        "Parked Vehicle Involved",
        options=['All', 'Yes (Y)', 'No (N)'],
        key="tab1_parked"
    )
    
    # Multi-vehicle with injury/fatality filter
    multi_vehicle_injury = st.sidebar.checkbox(
        "Multi-Vehicle (≥3) with Injury/Fatality",
        value=False,
        key="tab1_multi"
    )
    
    # Apply filters
    if len(date_range) == 2:
        start_date, end_date = date_range
    else:
        start_date, end_date = default_min, default_max
        
    df_filtered = df[
        (df['OCCURENCE_DATE'].dt.date >= start_date) &
        (df['OCCURENCE_DATE'].dt.date <= end_date)
    ]
    
    # Severity filter
    if 'All' not in selected_severity and len(selected_severity) > 0:
        df_filtered = df_filtered[df_filtered['COLLISION_SEVERITY'].isin(selected_severity)]
    
    # Parked vehicle filter
    if parked_vehicle == 'Yes (Y)':
        df_filtered = df_filtered[df_filtered['FLAG_PARKED_VEHICLE'] == 'Y']
    elif parked_vehicle == 'No (N)':
        df_filtered = df_filtered[df_filtered['FLAG_PARKED_VEHICLE'] == 'N']
    
    # Multi-vehicle with injury/fatality filter
    if multi_vehicle_injury:
        df_filtered = df_filtered[
            (df_filtered['VEHICLES_NBR'] >= 3) &
            ((df_filtered['INJURED_NBR'] >= 1) | (df_filtered['FATALITIES_NBR'] >= 1))
        ]
    
    # Display metrics
    st.sidebar.markdown("---")
    st.sidebar.metric("Total Collisions", f"{len(df_filtered):,}")
    st.sidebar.metric("Total Injuries", f"{df_filtered['INJURED_NBR'].sum():,.0f}")
    st.sidebar.metric("Total Fatalities", f"{df_filtered['FATALITIES_NBR'].sum():,.0f}")
    
    # Main content
    if len(df_filtered) == 0:
        st.warning("No data matches the selected filters. Please adjust your filter criteria.")
    else:
        # Map visualization
        st.subheader("Collision Map")
        
        # Prepare data for map without creating intermediate columns
        map_data = df_filtered.assign(
            SIZE=5 + (df_filtered['FATALITIES_NBR'] * 10),
            HOVER_TEXT=(
                "Case: " + df_filtered['CASE_NBR'].astype(str) + "<br>" +
                "Severity: " + df_filtered['COLLISION_SEVERITY'].astype(str) + "<br>" +
                "Vehicles: " + df_filtered['VEHICLES_NBR'].astype(str) + "<br>" +
                "Injured: " + df_filtered['INJURED_NBR'].astype(str) + "<br>" +
                "Fatalities: " + df_filtered['FATALITIES_NBR'].astype(str) + "<br>" +
                "Date: " + df_filtered['OCCURENCE_TIMESTRING'].astype(str)
            )
        )
        
        fig_map = px.scatter_mapbox(
            map_data,
            lat='LOC_GPS_LAT',
            lon='LOC_GPS_LONG',
            color='COLLISION_SEVERITY',
            size='SIZE',
            hover_name='HOVER_TEXT',
            zoom=10,
            height=600,
            opacity=0.7,
            color_discrete_sequence=px.colors.qualitative.Vivid
        )
        
        fig_map.update_layout(
            mapbox_style="open-street-map",
            mapbox=dict(
                center=dict(lat=53.5, lon=-113.5),
                zoom=10
            ),
            margin={"r":0,"t":0,"l":0,"b":0}
        )
        
        st.plotly_chart(fig_map, use_container_width=True)
        
        # Secondary visualizations
        st.markdown("---")
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("Collisions Over Time")
            time_series = df_filtered.groupby('YEAR_MONTH').size().reset_index(name='Count')
            fig_time = px.bar(
                time_series,
                x='YEAR_MONTH',
                y='Count',
                labels={'YEAR_MONTH': 'Month', 'Count': 'Number of Collisions'},
                height=400
            )
            fig_time.update_layout(xaxis_tickangle=-45)
            st.plotly_chart(fig_time, use_container_width=True)
        
        with col2:
            st.subheader("Collision Severity Distribution")
            severity_counts = df_filtered['COLLISION_SEVERITY'].value_counts().reset_index()
            severity_counts.columns = ['Severity', 'Count']
            fig_severity = px.bar(
                severity_counts,
                x='Severity',
                y='Count',
                height=400,
                labels={'Severity': 'Collision Severity', 'Count': 'Number of Collisions'}
            )
            fig_severity.update_layout(xaxis_tickangle=-45)
            st.plotly_chart(fig_severity, use_container_width=True)
        
        st.subheader("Vehicles Involved")
        vehicle_counts = df_filtered['VEHICLES_NBR'].value_counts().sort_index().reset_index()
        vehicle_counts.columns = ['Number of Vehicles', 'Count']
        fig_vehicles = px.bar(
            vehicle_counts,
            x='Number of Vehicles',
            y='Count',
            height=400
        )
        st.plotly_chart(fig_vehicles, use_container_width=True)
        
        # 2026 Forecast Section
        st.markdown("---")
        st.subheader("2026 Monthly Collision Forecast (SARIMA)")
        
        try:
            # Load forecast data
            forecast_df = pd.read_csv('edmonton_collision_forecast_2026.csv', low_memory=False)
            forecast_df['month'] = pd.to_datetime(forecast_df['month'])
            
            # Separate historical and forecast
            historical_df = forecast_df[forecast_df['model_used'] == 'Actual'].copy()
            forecast_2026 = forecast_df[forecast_df['month'].dt.year == 2026].copy()
            
            if len(forecast_2026) > 0:
                # Create forecast chart with confidence intervals
                fig_forecast = go.Figure()
                
                # Add historical actual data (no bands)
                if len(historical_df) > 0:
                    fig_forecast.add_trace(go.Scatter(
                        x=historical_df['month'],
                        y=historical_df['predicted_count'],
                        mode='lines',
                        name='Historical Actual',
                        line=dict(color='#636EFA', width=2)
                    ))
                
                # Add confidence interval as a shaded area for 2026
                fig_forecast.add_trace(go.Scatter(
                    x=forecast_2026['month'],
                    y=forecast_2026['upper_bound'],
                    fill=None,
                    mode='lines',
                    line_color='rgba(0,0,0,0)',
                    showlegend=False,
                    name='Upper Bound'
                ))
                
                fig_forecast.add_trace(go.Scatter(
                    x=forecast_2026['month'],
                    y=forecast_2026['lower_bound'],
                    fill='tonexty',
                    mode='lines',
                    line_color='rgba(0,0,0,0)',
                    name='85% Confidence Interval',
                    fillcolor='rgba(239, 85, 59, 0.2)'
                ))
                
                # Add 2026 point estimates
                fig_forecast.add_trace(go.Scatter(
                    x=forecast_2026['month'],
                    y=forecast_2026['predicted_count'],
                    mode='lines+markers',
                    name='2026 Forecast',
                    line=dict(color='#EF553B', width=3),
                    marker=dict(size=8)
                ))
                
                fig_forecast.update_layout(
                    title='2026 Monthly Collision Forecast with 85% Confidence Intervals',
                    xaxis_title='Month',
                    yaxis_title='Predicted Number of Collisions',
                    hovermode='x unified',
                    height=500,
                    template='plotly_white'
                )
                
                st.plotly_chart(fig_forecast, use_container_width=True)
                
                # Display forecast statistics
                col_f1, col_f2, col_f3, col_f4 = st.columns(4)
                with col_f1:
                    st.metric("Average Forecast", f"{forecast_2026['predicted_count'].mean():.0f}")
                with col_f2:
                    st.metric("Lowest Month", f"{forecast_2026['predicted_count'].min():.0f}")
                with col_f3:
                    st.metric("Highest Month", f"{forecast_2026['predicted_count'].max():.0f}")
                with col_f4:
                    st.metric("Avg. CI Width", f"±{(forecast_2026['upper_bound'].mean() - forecast_2026['predicted_count'].mean()):.0f}")
            else:
                st.info("2026 forecast data not available yet.")
        except FileNotFoundError:
            st.warning("Forecast file (edmonton_collision_forecast_2026.csv) not found. Run forecast_edmonton_collision.py to generate it.")
        except Exception as e:
            st.error(f"Error loading forecast: {str(e)}")
        
        # Data table
        st.markdown("---")
        st.subheader("📊 Detailed Data")
        st.dataframe(
            df_filtered[[
                'CASE_NBR', 'CASE_YEAR', 'COLLISION_SEVERITY',
                'FLAG_PARKED_VEHICLE', 'VEHICLES_NBR', 'INJURED_NBR', 'FATALITIES_NBR',
                'OCCURENCE_TIMESTRING', 'LOC_GPS_LAT', 'LOC_GPS_LONG'
            ]].sort_values('OCCURENCE_TIMESTRING', ascending=False),
            use_container_width=True,
            height=400
        )
        
        # Download button
        csv = df_filtered.to_csv(index=False).encode('utf-8')
        st.download_button(
            label="Download Filtered Data as CSV",
            data=csv,
            file_name=f"filtered_collisions_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
            mime="text/csv",
        )

# ============================================================================
# TAB 2: RISK ANALYSIS
# ============================================================================
with tab2:
    st.header("High-Risk Collision Analysis")
    st.markdown("**Analyzing collisions with ≥2 vehicles AND (injuries ≥1 OR fatalities ≥1)**")
    st.markdown("**Risk Score Formula**: Vehicles × 1 + Injuries × 5 + Fatalities × 20")
    
    # Risk analysis settings in sidebar
    st.sidebar.markdown("---")
    st.sidebar.header("Risk Analysis Settings")
    hex_size = st.sidebar.slider(
        "Hex Grid Size (km)",
        min_value=0.5,
        max_value=5.0,
        value=2.0,
        step=0.5,
        key="hex_size"
    )
    
    # Apply date range filter from Tab 1 to Risk Analysis data
    df_risk = df[
        (df['OCCURENCE_DATE'].dt.date >= start_date) &
        (df['OCCURENCE_DATE'].dt.date <= end_date)
    ]
    
    # Prepare risk analysis data
    with st.spinner("Calculating risk scores and aggregating data..."):
        df_high_risk, hex_agg, temporal_risk = ra.prepare_risk_analysis_data(df_risk, hex_size)
    
    # Display overview metrics
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("High-Risk Collisions", f"{len(df_high_risk):,}")
    with col2:
        st.metric("Total Risk Score", f"{df_high_risk['risk_score'].sum():,.0f}")
    with col3:
        st.metric("Avg Risk per Collision", f"{df_high_risk['risk_score'].mean():,.1f}")
    with col4:
        st.metric("Risk Zones (Hex Cells)", f"{len(hex_agg):,}")
    
    st.markdown("---")
    
    # Heat Map
    st.subheader("Risk Heat Map")
    
    fig_heat = px.density_mapbox(
        df_high_risk,
        lat='LOC_GPS_LAT',
        lon='LOC_GPS_LONG',
        z='risk_score',
        radius=15,
        center=dict(lat=53.5, lon=-113.5),
        zoom=10,
        mapbox_style="open-street-map",
        height=600,
        color_continuous_scale='Turbo',
        labels={'risk_score': 'Risk Score'}
    )
    
    fig_heat.update_layout(margin={"r":0,"t":0,"l":0,"b":0})
    st.plotly_chart(fig_heat, use_container_width=True)
    
    st.markdown("---")
    
    # Risk Choropleth (Hex Grid)
    st.subheader("Risk Zones (Hexagonal Grid)")
    
    # Create hover text
    hex_agg['hover_text'] = (
        "Risk Score: " + hex_agg['total_risk_score'].astype(str) + "<br>" +
        "Collisions: " + hex_agg['collision_count'].astype(str) + "<br>" +
        "Injuries: " + hex_agg['total_injuries'].astype(str) + "<br>" +
        "Fatalities: " + hex_agg['total_fatalities'].astype(str)
    )
    
    fig_hex = px.scatter_mapbox(
        hex_agg,
        lat='center_lat',
        lon='center_lon',
        size='total_risk_score',
        color='total_risk_score',
        hover_name='hover_text',
        color_continuous_scale='Plasma',
        size_max=30,
        zoom=10,
        height=600,
        labels={'total_risk_score': 'Total Risk Score'}
    )
    
    fig_hex.update_layout(
        mapbox_style="open-street-map",
        mapbox=dict(center=dict(lat=53.5, lon=-113.5), zoom=10),
        margin={"r":0,"t":0,"l":0,"b":0}
    )
    
    st.plotly_chart(fig_hex, use_container_width=True)
    
    st.markdown("---")
    
    # Time Analysis and Zone Breakdown
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Risk Over Time")
        fig_temporal = px.line(
            temporal_risk,
            x='month',
            y='total_risk',
            markers=True,
            labels={'month': 'Month', 'total_risk': 'Total Risk Score'},
            height=400
        )
        fig_temporal.update_layout(xaxis_tickangle=-45)
        st.plotly_chart(fig_temporal, use_container_width=True)
    
    with col2:
        st.subheader("Risk by Edmonton Zone")
        zone_risk = df_high_risk.groupby('edmonton_zone').agg({
            'risk_score': 'sum',
            'CASE_NBR': 'count'
        }).reset_index().sort_values('risk_score', ascending=False)
        zone_risk.columns = ['Zone', 'Total Risk', 'Collisions']
        
        fig_zone = px.bar(
            zone_risk,
            x='Total Risk',
            y='Zone',
            orientation='h',
            labels={'Total Risk': 'Total Risk Score'},
            height=400,
            color='Total Risk',
            color_continuous_scale='Reds'
        )
        fig_zone.update_layout(yaxis={'categoryorder':'total ascending'})
        st.plotly_chart(fig_zone, use_container_width=True)
    
    st.markdown("---")
    
    # Top 20 Risk Locations Table
    st.subheader("📊 Top 20 Highest Risk Locations")
    top_20 = ra.get_top_risk_locations(hex_agg, top_n=20)
    
    # Format for display
    top_20_display = top_20[[
        'rank', 'collision_count', 'total_risk_score',
        'total_vehicles', 'total_injuries', 'total_fatalities',
        'avg_risk_per_collision', 'center_lat', 'center_lon'
    ]].copy()
    
    top_20_display.columns = [
        'Rank', 'Collisions', 'Total Risk',
        'Vehicles', 'Injuries', 'Fatalities',
        'Avg Risk', 'Latitude', 'Longitude'
    ]
    
    st.dataframe(
        top_20_display.style.format({
            'Total Risk': '{:.0f}',
            'Avg Risk': '{:.1f}',
            'Latitude': '{:.4f}',
            'Longitude': '{:.4f}'
        }),
        use_container_width=True,
        height=500
    )
    
    # Download risk analysis data
    risk_csv = df_high_risk.to_csv(index=False).encode('utf-8')
    st.download_button(
        label="Download High-Risk Collision Data",
        data=risk_csv,
        file_name=f"high_risk_collisions_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
        mime="text/csv",
    )
