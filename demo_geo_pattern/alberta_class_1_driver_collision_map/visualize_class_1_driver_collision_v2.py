r"""
Alberta Class 1 Driver Collision Analysis Dashboard
====================================================

This Streamlit application provides interactive visualization and risk analysis
for Class 1 driver collisions across Alberta (April 2024 - September 2025).

HOW TO RUN:
-----------
1. Activate the virtual environment:
   C:\Users\kai.wong\Dev\virtual_env\venv_etl_for_ecol_analytics\Scripts\Activate.ps1

2. Navigate to the directory:
   cd demo_geo_pattern\alberta_class_1_driver_collision_map

3. Run the Streamlit app:
   streamlit run visualize_class_1_driver_collision_v2.py

   OR using full path:
   C:\Users\kai.wong\Dev\virtual_env\venv_etl_for_ecol_analytics\Scripts\streamlit.exe run visualize_class_1_driver_collision_v2.py

4. Open browser to:
   http://localhost:8501

REQUIREMENTS:
-------------
- processed_class_1_driver_collision.csv (in same directory)
- risk_analysis.py (in same directory)
- Python packages: streamlit, pandas, plotly

FEATURES:
---------
Tab 1 - Overview Dashboard:
  - Interactive collision map
  - Filters: date range, severity, driver action, parked vehicle
  - Time series analysis
  - Driver action breakdown
  - Vehicle count distribution

Tab 2 - Risk Analysis:
  - Risk scoring (Vehicles×1 + Injuries×5 + Fatalities×20)
  - Heat map visualization
  - Hexagonal grid risk zones
  - Highway corridor analysis
  - Temporal risk trends
  - Top 20 highest risk locations

For more details, see README.md
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime
import risk_analysis as ra

# Page config
st.set_page_config(
    page_title="Alberta Class 1 Driver Collisions",
    page_icon="🚛",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Load data
@st.cache_data
def load_data():
    df = pd.read_csv('processed_class_1_driver_collision.csv')
    df['OCCURENCE_DATE'] = pd.to_datetime(df['OCCURENCE_TIMESTRING'])
    df['MONTH'] = df['OCCURENCE_DATE'].dt.to_period('M').astype(str)
    df['YEAR_MONTH'] = df['OCCURENCE_DATE'].dt.strftime('%Y-%m')
    # Clean lat/long - remove invalid coordinates
    df = df.dropna(subset=['LOC_GPS_LAT', 'LOC_GPS_LONG'])
    df = df[(df['LOC_GPS_LAT'] >= 49) & (df['LOC_GPS_LAT'] <= 60)]  # Alberta latitude range
    df = df[(df['LOC_GPS_LONG'] >= -120) & (df['LOC_GPS_LONG'] <= -110)]  # Alberta longitude range
    return df

df = load_data()

# Title
st.title("🚛 Alberta Class 1 Driver Collision Analysis")
st.markdown("**Interactive visualization of collision patterns across Alberta (Apr 2024 - Sep 2025)**")

# Create tabs
tab1, tab2 = st.tabs(["📊 Overview Dashboard", "⚠️ Risk Analysis"])

# ============================================================================
# TAB 1: OVERVIEW DASHBOARD
# ============================================================================
with tab1:
    st.header("Overview Dashboard")
    
    # Sidebar filters
    st.sidebar.header("🔍 Tab 1 Filters")
    
    # Date range filter
    min_date = df['OCCURENCE_DATE'].min().date()
    max_date = df['OCCURENCE_DATE'].max().date()
    date_range = st.sidebar.date_input(
        "Date Range",
        value=(min_date, max_date),
        min_value=min_date,
        max_value=max_date,
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
    
    # Driver Action filter
    driver_action_options = ['All'] + sorted(df['DRIVER_ACTION_ID'].dropna().unique().tolist())
    selected_driver_action = st.sidebar.multiselect(
        "Driver Action ID",
        options=driver_action_options,
        default=['All'],
        key="tab1_driver"
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
    df_filtered = df.copy()
    
    # Date filter
    if len(date_range) == 2:
        start_date, end_date = date_range
        df_filtered = df_filtered[
            (df_filtered['OCCURENCE_DATE'].dt.date >= start_date) &
            (df_filtered['OCCURENCE_DATE'].dt.date <= end_date)
        ]
    
    # Severity filter
    if 'All' not in selected_severity and len(selected_severity) > 0:
        df_filtered = df_filtered[df_filtered['COLLISION_SEVERITY'].isin(selected_severity)]
    
    # Driver action filter
    if 'All' not in selected_driver_action and len(selected_driver_action) > 0:
        df_filtered = df_filtered[df_filtered['DRIVER_ACTION_ID'].isin(selected_driver_action)]
    
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
        st.warning("⚠️ No data matches the selected filters. Please adjust your filter criteria.")
    else:
        # Map visualization
        st.subheader("📍 Collision Map")
        
        # Create color mapping for severity
        df_filtered['SIZE'] = 5 + (df_filtered['FATALITIES_NBR'] * 10)
        df_filtered['HOVER_TEXT'] = (
            "Case: " + df_filtered['CASE_NBR'].astype(str) + "<br>" +
            "Severity: " + df_filtered['COLLISION_SEVERITY'].astype(str) + "<br>" +
            "Vehicles: " + df_filtered['VEHICLES_NBR'].astype(str) + "<br>" +
            "Injured: " + df_filtered['INJURED_NBR'].astype(str) + "<br>" +
            "Fatalities: " + df_filtered['FATALITIES_NBR'].astype(str) + "<br>" +
            "Date: " + df_filtered['OCCURENCE_TIMESTRING'].astype(str)
        )
        
        fig_map = px.scatter_mapbox(
            df_filtered,
            lat='LOC_GPS_LAT',
            lon='LOC_GPS_LONG',
            color='COLLISION_SEVERITY',
            size='SIZE',
            hover_name='HOVER_TEXT',
            zoom=5,
            height=600,
            opacity=0.7,
            color_discrete_sequence=px.colors.qualitative.Vivid
        )
        
        fig_map.update_layout(
            mapbox_style="open-street-map",
            mapbox=dict(
                center=dict(lat=53.5, lon=-115),
                zoom=5
            ),
            margin={"r":0,"t":0,"l":0,"b":0}
        )
        
        st.plotly_chart(fig_map, use_container_width=True)
        
        # Secondary visualizations
        st.markdown("---")
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("📈 Collisions Over Time")
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
            st.subheader("⚠️ Collision Severity Distribution")
            severity_counts = df_filtered['COLLISION_SEVERITY'].value_counts().reset_index()
            severity_counts.columns = ['Severity', 'Count']
            fig_severity = px.pie(
                severity_counts,
                names='Severity',
                values='Count',
                height=400
            )
            st.plotly_chart(fig_severity, use_container_width=True)
        
        col3, col4 = st.columns(2)
        
        with col3:
            st.subheader("🚗 Top 10 Driver Actions")
            driver_action_counts = df_filtered['DRIVER_ACTION_ID'].value_counts().head(10).reset_index()
            driver_action_counts.columns = ['Driver Action ID', 'Count']
            fig_driver = px.bar(
                driver_action_counts,
                x='Count',
                y='Driver Action ID',
                orientation='h',
                height=400
            )
            fig_driver.update_layout(yaxis={'categoryorder':'total ascending'})
            st.plotly_chart(fig_driver, use_container_width=True)
        
        with col4:
            st.subheader("🚙 Vehicles Involved")
            vehicle_counts = df_filtered['VEHICLES_NBR'].value_counts().sort_index().reset_index()
            vehicle_counts.columns = ['Number of Vehicles', 'Count']
            fig_vehicles = px.bar(
                vehicle_counts,
                x='Number of Vehicles',
                y='Count',
                height=400
            )
            st.plotly_chart(fig_vehicles, use_container_width=True)
        
        # Data table
        st.markdown("---")
        st.subheader("📊 Detailed Data")
        st.dataframe(
            df_filtered[[
                'CASE_NBR', 'CASE_YEAR', 'COLLISION_SEVERITY', 'DRIVER_ACTION_ID',
                'FLAG_PARKED_VEHICLE', 'VEHICLES_NBR', 'INJURED_NBR', 'FATALITIES_NBR',
                'OCCURENCE_TIMESTRING', 'LOC_GPS_LAT', 'LOC_GPS_LONG'
            ]].sort_values('OCCURENCE_TIMESTRING', ascending=False),
            use_container_width=True,
            height=400
        )
        
        # Download button
        csv = df_filtered.to_csv(index=False).encode('utf-8')
        st.download_button(
            label="📥 Download Filtered Data as CSV",
            data=csv,
            file_name=f"filtered_collisions_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
            mime="text/csv",
        )

# ============================================================================
# TAB 2: RISK ANALYSIS
# ============================================================================
with tab2:
    st.header("⚠️ High-Risk Collision Analysis")
    st.markdown("**Analyzing collisions with ≥2 vehicles AND (injuries ≥1 OR fatalities ≥1)**")
    st.markdown("**Risk Score Formula**: Vehicles × 1 + Injuries × 5 + Fatalities × 20")
    
    # Risk analysis settings in sidebar
    st.sidebar.markdown("---")
    st.sidebar.header("🎛️ Risk Analysis Settings")
    hex_size = st.sidebar.slider(
        "Hex Grid Size (km)",
        min_value=0.5,
        max_value=5.0,
        value=2.0,
        step=0.5,
        key="hex_size"
    )
    
    # Prepare risk analysis data
    with st.spinner("Calculating risk scores and aggregating data..."):
        df_high_risk, hex_agg, temporal_risk = ra.prepare_risk_analysis_data(df, hex_size)
    
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
    st.subheader("🔥 Risk Heat Map")
    
    fig_heat = px.density_mapbox(
        df_high_risk,
        lat='LOC_GPS_LAT',
        lon='LOC_GPS_LONG',
        z='risk_score',
        radius=15,
        center=dict(lat=53.5, lon=-115),
        zoom=5,
        mapbox_style="open-street-map",
        height=600,
        color_continuous_scale='Turbo',
        labels={'risk_score': 'Risk Score'}
    )
    
    fig_heat.update_layout(margin={"r":0,"t":0,"l":0,"b":0})
    st.plotly_chart(fig_heat, use_container_width=True)
    
    st.markdown("---")
    
    # Risk Choropleth (Hex Grid)
    st.subheader("🗺️ Risk Zones (Hexagonal Grid)")
    
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
        zoom=5,
        height=600,
        labels={'total_risk_score': 'Total Risk Score'}
    )
    
    fig_hex.update_layout(
        mapbox_style="open-street-map",
        mapbox=dict(center=dict(lat=53.5, lon=-115), zoom=5),
        margin={"r":0,"t":0,"l":0,"b":0}
    )
    
    st.plotly_chart(fig_hex, use_container_width=True)
    
    st.markdown("---")
    
    # Time Analysis and Highway Breakdown
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📅 Risk Over Time")
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
        st.subheader("🛣️ Risk by Highway Corridor")
        highway_risk = df_high_risk.groupby('highway_corridor').agg({
            'risk_score': 'sum',
            'CASE_NBR': 'count'
        }).reset_index().sort_values('risk_score', ascending=False)
        highway_risk.columns = ['Highway', 'Total Risk', 'Collisions']
        
        fig_highway = px.bar(
            highway_risk,
            x='Total Risk',
            y='Highway',
            orientation='h',
            labels={'Total Risk': 'Total Risk Score'},
            height=400,
            color='Total Risk',
            color_continuous_scale='Reds'
        )
        fig_highway.update_layout(yaxis={'categoryorder':'total ascending'})
        st.plotly_chart(fig_highway, use_container_width=True)
    
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
        label="📥 Download High-Risk Collision Data",
        data=risk_csv,
        file_name=f"high_risk_collisions_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
        mime="text/csv",
    )
