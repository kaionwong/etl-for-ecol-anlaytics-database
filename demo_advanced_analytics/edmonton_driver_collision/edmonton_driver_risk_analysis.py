"""
Risk Analysis Module for Edmonton Driver Collisions
Provides risk scoring, geographical aggregation, and highway identification
"""

import pandas as pd
import numpy as np
from typing import Tuple, Dict, List
import math


def calculate_risk_score(row: pd.Series) -> float:
    """
    Calculate risk score using weighted formula (Option A)
    Risk = (Vehicles × 1) + (Injuries × 5) + (Fatalities × 20)
    
    Args:
        row: DataFrame row with VEHICLES_NBR, INJURED_NBR, FATALITIES_NBR
    
    Returns:
        float: Risk score
    """
    vehicles = row.get('VEHICLES_NBR', 0) or 0
    injuries = row.get('INJURED_NBR', 0) or 0
    fatalities = row.get('FATALITIES_NBR', 0) or 0
    
    return (vehicles * 1) + (injuries * 5) + (fatalities * 20)


def filter_high_risk_collisions(df: pd.DataFrame) -> pd.DataFrame:
    """
    Filter collisions with ≥2 vehicles AND (injuries ≥1 OR fatalities ≥1)
    
    Args:
        df: Input DataFrame
    
    Returns:
        Filtered DataFrame with high-risk collisions only
    """
    return df[
        (df['VEHICLES_NBR'] >= 2) &
        ((df['INJURED_NBR'] >= 1) | (df['FATALITIES_NBR'] >= 1))
    ].copy()


def lat_lon_to_hex(lat: float, lon: float, hex_size_km: float = 2.0) -> str:
    """
    Convert lat/lon to a hexagonal grid cell ID (simple implementation)
    Uses a rectangular grid approximation for simplicity
    
    Args:
        lat: Latitude
        lon: Longitude
        hex_size_km: Size of hex cell in kilometers (default 2km)
    
    Returns:
        Hex cell ID string
    """
    # Approximate degrees per km (at Edmonton's latitude ~53.5°)
    km_per_lat = 111.0
    km_per_lon = 111.0 * math.cos(math.radians(53.5))
    
    # Convert to grid coordinates
    grid_lat = int(lat / (hex_size_km / km_per_lat))
    grid_lon = int(lon / (hex_size_km / km_per_lon))
    
    return f"hex_{grid_lat}_{grid_lon}"


def aggregate_by_hex_grid(df: pd.DataFrame, hex_size_km: float = 2.0) -> pd.DataFrame:
    """
    Aggregate collisions by hexagonal grid cells
    
    Args:
        df: DataFrame with collision data including risk scores
        hex_size_km: Size of hex cells in kilometers
    
    Returns:
        DataFrame with aggregated risk metrics per hex cell
    """
    # Assign hex cell IDs
    df['hex_id'] = df.apply(
        lambda row: lat_lon_to_hex(row['LOC_GPS_LAT'], row['LOC_GPS_LONG'], hex_size_km),
        axis=1
    )
    
    # Aggregate by hex cell
    hex_agg = df.groupby('hex_id').agg({
        'CASE_NBR': 'count',
        'risk_score': 'sum',
        'VEHICLES_NBR': 'sum',
        'INJURED_NBR': 'sum',
        'FATALITIES_NBR': 'sum',
        'LOC_GPS_LAT': 'mean',
        'LOC_GPS_LONG': 'mean'
    }).reset_index()
    
    hex_agg.columns = [
        'hex_id', 'collision_count', 'total_risk_score', 
        'total_vehicles', 'total_injuries', 'total_fatalities',
        'center_lat', 'center_lon'
    ]
    
    # Calculate average risk per collision
    hex_agg['avg_risk_per_collision'] = (
        hex_agg['total_risk_score'] / hex_agg['collision_count']
    )
    
    # Sort by total risk score
    hex_agg = hex_agg.sort_values('total_risk_score', ascending=False)
    
    return hex_agg


def identify_edmonton_zones(lat: float, lon: float) -> str:
    """
    Identify which major Edmonton zone/corridor a collision belongs to
    Based on approximate lat/lon ranges for Edmonton city boundaries
    
    Args:
        lat: Latitude
        lon: Longitude
    
    Returns:
        Zone name or 'Other'
    """
    # Downtown Edmonton
    # Approximate: 53.52 to 53.56 lat, -113.5 to -113.47 lon
    if 53.50 < lat < 53.58 and -113.52 < lon < -113.45:
        return 'Downtown Edmonton'
    
    # Northeast Edmonton (Fort Road, 97 Street)
    if 53.50 < lat < 53.65 and -113.40 < lon < -113.25:
        return 'Northeast Edmonton'
    
    # Southeast Edmonton (Gateway Boulevard, 82 Street)
    if 53.35 < lat < 53.50 and -113.45 < lon < -113.25:
        return 'Southeast Edmonton'
    
    # Southwest Edmonton (Whyte Avenue, 104 Street)
    if 53.35 < lat < 53.50 and -113.60 < lon < -113.45:
        return 'Southwest Edmonton'
    
    # Northwest Edmonton (St. Albert, 127 Street)
    if 53.58 < lat < 53.75 and -113.70 < lon < -113.45:
        return 'Northwest Edmonton'
    
    # Highway 16 (Yellowhead) - East/West corridor through Edmonton
    if 53.50 < lat < 53.60 and -113.80 < lon < -113.20:
        return 'Highway 16 (Yellowhead)'
    
    # Highway 2 South (Gateway Boulevard, Whitemud Drive area)
    if 53.30 < lat < 53.45 and -113.60 < lon < -113.30:
        return 'Gateway Corridor'
    
    # Sherwood Park area (East)
    if 53.42 < lat < 53.55 and -113.25 < lon < -113.10:
        return 'Sherwood Park Area'
    
    # St. Albert area (North)
    if 53.65 < lat < 53.80 and -113.65 < lon < -113.40:
        return 'St. Albert Area'
    
    return 'Other Zones'


def add_edmonton_zones(df: pd.DataFrame) -> pd.DataFrame:
    """
    Add Edmonton zone identification to DataFrame
    
    Args:
        df: DataFrame with LOC_GPS_LAT and LOC_GPS_LONG
    
    Returns:
        DataFrame with 'edmonton_zone' column added
    """
    df['edmonton_zone'] = df.apply(
        lambda row: identify_edmonton_zones(row['LOC_GPS_LAT'], row['LOC_GPS_LONG']),
        axis=1
    )
    return df


def get_risk_level_category(risk_score: float, percentiles: Dict[str, float]) -> str:
    """
    Categorize risk score into levels based on percentiles
    
    Args:
        risk_score: Risk score value
        percentiles: Dict with percentile values (25, 50, 75, 90)
    
    Returns:
        Risk level category string
    """
    if risk_score >= percentiles[90]:
        return 'Critical'
    elif risk_score >= percentiles[75]:
        return 'High'
    elif risk_score >= percentiles[50]:
        return 'Medium'
    elif risk_score >= percentiles[25]:
        return 'Low'
    else:
        return 'Very Low'


def calculate_temporal_risk(df: pd.DataFrame) -> pd.DataFrame:
    """
    Calculate risk metrics over time (by month)
    
    Args:
        df: DataFrame with OCCURENCE_DATE and risk_score
    
    Returns:
        DataFrame with temporal risk aggregation
    """
    temporal = df.groupby('YEAR_MONTH').agg({
        'CASE_NBR': 'count',
        'risk_score': ['sum', 'mean'],
        'INJURED_NBR': 'sum',
        'FATALITIES_NBR': 'sum'
    }).reset_index()
    
    temporal.columns = [
        'month', 'collision_count', 'total_risk', 'avg_risk',
        'total_injuries', 'total_fatalities'
    ]
    
    return temporal


def get_top_risk_locations(hex_agg: pd.DataFrame, top_n: int = 20) -> pd.DataFrame:
    """
    Get top N highest risk locations
    
    Args:
        hex_agg: Aggregated hex grid DataFrame
        top_n: Number of top locations to return
    
    Returns:
        DataFrame with top risk locations
    """
    top_locations = hex_agg.head(top_n).copy()
    top_locations['rank'] = range(1, len(top_locations) + 1)
    
    return top_locations[[
        'rank', 'hex_id', 'collision_count', 'total_risk_score',
        'total_vehicles', 'total_injuries', 'total_fatalities',
        'avg_risk_per_collision', 'center_lat', 'center_lon'
    ]]


def prepare_risk_analysis_data(df: pd.DataFrame, hex_size_km: float = 2.0) -> Tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """
    Main function to prepare all risk analysis data
    
    Args:
        df: Input DataFrame with collision data
        hex_size_km: Hexagon size in kilometers
    
    Returns:
        Tuple of (filtered_df with risk scores, hex_aggregated, temporal_risk)
    """
    # Filter high-risk collisions
    df_high_risk = filter_high_risk_collisions(df)
    
    # Calculate risk scores
    df_high_risk['risk_score'] = df_high_risk.apply(calculate_risk_score, axis=1)
    
    # Add Edmonton zones
    df_high_risk = add_edmonton_zones(df_high_risk)
    
    # Aggregate by hex grid
    hex_agg = aggregate_by_hex_grid(df_high_risk, hex_size_km)
    
    # Calculate temporal risk
    temporal_risk = calculate_temporal_risk(df_high_risk)
    
    return df_high_risk, hex_agg, temporal_risk
