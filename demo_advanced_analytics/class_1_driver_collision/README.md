# Alberta Class 1 Driver Collision Analysis Dashboard

Interactive geospatial analysis dashboard for Class 1 driver collision data across Alberta, Canada (April 2024 - September 2025).

## 📋 Overview

This project demonstrates advanced geographical visualization capabilities for collision data analysis, designed for leadership presentations and internal analytics. The dashboard provides two complementary views:

1. **Overview Dashboard** - General exploration and filtering of collision data
2. **Risk Analysis** - Advanced risk scoring and hotspot identification

## 🚀 Quick Start

### Prerequisites

- Python 3.11+ (virtual environment: `venv_etl_for_ecol_analytics`)
- Required data file: `processed_class_1_driver_collision.csv`
- Installed packages: `streamlit`, `pandas`, `plotly`

### Installation

```powershell
# Activate virtual environment
C:\Users\kai.wong\Dev\virtual_env\venv_etl_for_ecol_analytics\Scripts\Activate.ps1

# Navigate to project directory
cd C:\Users\kai.wong\OneDrive - Government of Alberta\_work\project\etl_for_ecol_analytics_database\etl-for-ecol-anlaytics-database\demo_geo_pattern

# Install missing dependencies (if needed)
pip install plotly
```

### Running the Dashboard

```powershell
# Method 1: Using streamlit command (if in PATH)
streamlit run visualize_class_1_driver_collision_v2.py

# Method 2: Using full path to streamlit executable
C:\Users\kai.wong\Dev\virtual_env\venv_etl_for_ecol_analytics\Scripts\streamlit.exe run visualize_class_1_driver_collision_v2.py
```

The dashboard will automatically open in your default browser at `http://localhost:8501`

## 📊 Features

### Tab 1: Overview Dashboard

**Interactive Map**
- Scatter plot visualization of all collisions across Alberta
- Color-coded by collision severity
- Point size reflects fatality count
- Hover details: case number, severity, vehicles, injuries, fatalities, date

**Filters (Sidebar)**
- Date range picker
- Collision severity (multi-select)
- Driver action ID (multi-select)
- Parked vehicle involvement (Yes/No/All)
- Multi-vehicle with casualties toggle (≥3 vehicles + injuries/fatalities)

**Analytics Charts**
- Time series: Collisions by month
- Severity distribution: Pie chart breakdown
- Top 10 driver actions: Horizontal bar chart
- Vehicle count distribution: Bar chart

**Data Export**
- Downloadable CSV of filtered results
- Real-time metrics: total collisions, injuries, fatalities

### Tab 2: Risk Analysis

**Risk Scoring Methodology**
```
Risk Score = (Vehicles × 1) + (Injuries × 5) + (Fatalities × 20)

High-Risk Criteria:
- 2 or more vehicles involved AND
- At least 1 injury OR 1 fatality
```

**Visualizations**

1. **🔥 Risk Heat Map**
   - Density visualization showing collision concentration
   - Color scale: Blue → Green → Yellow → Red (Turbo palette)
   - Adjustable radius: 15 pixels

2. **🗺️ Risk Zones (Hexagonal Grid)**
   - Geographical aggregation using hexagonal cells
   - Bubble size: proportional to total risk score
   - Color intensity: risk level (Plasma palette)
   - Adjustable grid size: 0.5km - 5.0km

3. **📅 Risk Over Time**
   - Line chart showing monthly risk trends
   - Identifies seasonal patterns
   - Total risk score per month

4. **🛣️ Risk by Highway Corridor**
   - Bar chart comparing major routes
   - Identified corridors:
     - QE2 (Highway 2) - Calgary to Edmonton
     - Highway 1 (Trans-Canada)
     - Highway 16 (Yellowhead)
     - Calgary Metro
     - Edmonton Metro
     - Highway 2 North
     - Red Deer Area
     - Other Roads

5. **📊 Top 20 Highest Risk Locations**
   - Ranked table of most dangerous hex zones
   - Columns: Rank, Collisions, Total Risk, Vehicles, Injuries, Fatalities, Avg Risk, Latitude, Longitude
   - Sortable and exportable

**Settings**
- Hex grid size slider (sidebar)
- Real-time recalculation on adjustment

## 📁 Project Structure

```
alberta_class_1_driver_collision_map/
├── README.md                                    # This file
├── visualize_class_1_driver_collision_v2.py    # Main dashboard application
├── class_1_driver_risk_analysis.py              # Risk scoring and analysis module
├── process_class_1_driver_collision.py         # Data preprocessing script
├── processed_class_1_driver_collision.csv      # Input data file (12,342 rows)
├── alberta_collision_2024-2025.csv             # Raw Alberta data (455,996 rows)
└── output_collision_class_1_*.csv              # Class 1 driver filter data
```

## 🔧 Data Processing Pipeline

### Step 1: Add Headers to Raw CSV Files
```powershell
python add_header_to_alberta_csv.py
```
- Adds 78 column headers to raw CSV files
- Validates existing headers before modification
- Files: `alberta_collision_2024-2025.csv`

### Step 2: Process and Aggregate Collision Data
```powershell
python process_class_1_driver_collision.py
```

**Processing Steps:**
1. Load `alberta_collision_2024-2025.csv` (455,996 rows)
2. Aggregate by unique `CASE_NBR` (188,963 unique cases)
   - Retain first row for most columns
   - Special handling: `Flag_ParkedVehicle` = 'Y' if any related row has 'Y'
3. Load `output_collision_class_1_*.csv` (35,848 rows → 12,342 unique cases)
4. Merge on `CASE_NBR` (inner join)
5. Output: `processed_class_1_driver_collision.csv` (12,342 rows, 11 columns)

**Output Columns:**
- `CASE_NBR`, `DRIVER_ACTION_ID`, `CASE_YEAR`, `COLLISION_SEVERITY`
- `LOC_GPS_LAT`, `LOC_GPS_LONG`, `FLAG_PARKED_VEHICLE`
- `VEHICLES_NBR`, `INJURED_NBR`, `FATALITIES_NBR`, `OCCURENCE_TIMESTRING`

### Step 3: Run Dashboard
```powershell
streamlit run visualize_class_1_driver_collision_v2.py
```

## 📖 Module Documentation

### `class_1_driver_risk_analysis.py`

Core functions for risk calculation and geographical analysis.

**Key Functions:**

- `calculate_risk_score(row)` - Weighted risk scoring formula
- `filter_high_risk_collisions(df)` - Apply high-risk criteria
- `lat_lon_to_hex(lat, lon, hex_size_km)` - Convert coordinates to hex grid ID
- `aggregate_by_hex_grid(df, hex_size_km)` - Aggregate collisions by hex cells
- `identify_highway_corridor(lat, lon)` - Map coordinates to highway names
- `add_highway_corridors(df)` - Bulk corridor identification
- `calculate_temporal_risk(df)` - Monthly risk aggregation
- `get_top_risk_locations(hex_agg, top_n)` - Rank highest risk zones
- `prepare_risk_analysis_data(df, hex_size_km)` - Main orchestration function

**Highway Corridor Identification Logic:**

Uses lat/lon bounding boxes to identify major routes:
- QE2: `lon ∈ [-114.2, -113.0]`, `lat ∈ [51.0, 53.6]`
- Highway 1: `lat ∈ [50.8, 51.2]`, `lon ∈ [-114.5, -110.0]`
- Highway 16: `lat ∈ [53.3, 53.7]`, `lon ∈ [-117.0, -110.0]`
- Calgary Metro: `lat ∈ [50.9, 51.2]`, `lon ∈ [-114.3, -113.9]`
- Edmonton Metro: `lat ∈ [53.4, 53.7]`, `lon ∈ [-113.7, -113.3]`

## 🎯 Use Cases

### For Leadership Demos
1. Start with Tab 1 to show overall collision patterns
2. Apply filters to demonstrate real-time interactivity
3. Switch to Tab 2 to highlight risk analysis capabilities
4. Show heat map to identify geographical hotspots
5. Display Top 20 table to prioritize intervention zones
6. Adjust hex grid size to show analytical flexibility

### For Policy Analysis
- Identify high-risk corridors for infrastructure improvements
- Compare risk levels between urban and highway locations
- Analyze seasonal trends in collision severity
- Evaluate impact of parked vehicles on collision risk

### For Operational Planning
- Prioritize enforcement resources to top-risk zones
- Schedule seasonal safety campaigns based on temporal patterns
- Target specific driver actions with highest collision frequency

## 📈 Technical Specifications

**Data Volume:**
- Total collisions analyzed: 12,342
- Date range: April 1, 2024 - September 30, 2025
- Geographic coverage: Alberta, Canada
- Coordinate range: Lat [49°, 60°], Lon [-120°, -110°]

**Performance:**
- Data loading: ~1-2 seconds (cached after first run)
- Risk analysis calculation: ~2-3 seconds
- Dashboard responsiveness: Real-time filtering

**Color Palettes:**
- Overview map: Vivid (qualitative)
- Risk heat map: Turbo (sequential, blue→red)
- Risk zones: Plasma (sequential, purple→yellow)
- Highway risk: Reds (sequential)

## 🔍 Troubleshooting

### Dashboard won't start
```powershell
# Check Python environment
python --version

# Verify Streamlit installation
pip show streamlit

# Re-install if needed
pip install --upgrade streamlit plotly pandas
```

### "Module not found: class_1_driver_risk_analysis"
- Ensure `class_1_driver_risk_analysis.py` is in the same directory as the dashboard script
- Check current working directory: `Get-Location`

### "File not found: processed_class_1_driver_collision.csv"
- Run preprocessing script first: `python process_class_1_driver_collision.py`
- Verify file exists in current directory: `ls *.csv`

### Map not displaying
- Check internet connection (OpenStreetMap tiles require online access)
- Try alternative mapbox style in code if needed

### Slow performance
- Reduce hex grid size (smaller number = fewer cells to calculate)
- Apply stricter filters to reduce data points
- Clear Streamlit cache: `streamlit cache clear`

## 📝 Development Notes

**Created:** January 30-31, 2026  
**Purpose:** Leadership demo for geographical analytics capability  
**Data Source:** eCollision Analytics database  
**Target Audience:** Government of Alberta leadership and policy analysts

**Design Decisions:**
- Two-tab structure for separation of concerns
- Hex grid over H3 library for simplicity and portability
- Fixed highway corridors vs. dynamic routing for demo speed
- Weighted risk scoring prioritizes fatalities (20×) over injuries (5×) and vehicles (1×)

**Future Enhancements:**
- Integration with live database feeds
- Predictive modeling for risk forecasting
- Export to PDF report generation
- Multi-year trend comparison
- Weather condition overlay
- Time-of-day heatmaps

## 📧 Contact

For questions or issues, contact the Data Analytics team at Government of Alberta.

---

**Last Updated:** January 31, 2026  
**Version:** 2.0  
**Status:** Production-ready for leadership demo
