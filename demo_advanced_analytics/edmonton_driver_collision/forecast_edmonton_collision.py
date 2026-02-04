"""
Edmonton Collision Forecasting - SARIMA Only
=============================================

Fast forecasting using SARIMA with walk-forward cross-validation
for 2026 projections with 85% prediction intervals.
"""

import pandas as pd
import numpy as np
import warnings
from datetime import datetime
from statsmodels.tsa.statespace.sarimax import SARIMAX
from pmdarima.arima import auto_arima
import scipy.stats as stats

warnings.filterwarnings('ignore')

print("=" * 80)
print("Edmonton Collision Forecasting - SARIMA Only")
print("=" * 80)

# ============================================================================
# STEP 1: LOAD AND AGGREGATE DATA
# ============================================================================
print("\n[Step 1] Loading and aggregating data...")
df = pd.read_csv('processed_edmonton_driver_collision.csv', low_memory=False)
df['OCCURENCE_DATE'] = pd.to_datetime(df['OCCURENCE_TIMESTRING'], errors='coerce', format='%Y/%m/%d')
df = df.dropna(subset=['OCCURENCE_DATE'])

# Aggregate to monthly counts
monthly_collisions = df.groupby(df['OCCURENCE_DATE'].dt.to_period('M')).size().reset_index(name='collision_count')
monthly_collisions['month'] = monthly_collisions['OCCURENCE_DATE'].dt.to_timestamp()
monthly_collisions = monthly_collisions[['month', 'collision_count']].sort_values('month')

# Filter to complete years only (2021-2025)
monthly_collisions = monthly_collisions[
    (monthly_collisions['month'] >= pd.Timestamp('2021-01-01')) & 
    (monthly_collisions['month'] < pd.Timestamp('2026-01-01'))
]
monthly_collisions = monthly_collisions.reset_index(drop=True)

print(f"  - Monthly data points: {len(monthly_collisions)}")
print(f"  - Date range: {monthly_collisions['month'].min().date()} to {monthly_collisions['month'].max().date()}")
print(f"  - Mean monthly collisions: {monthly_collisions['collision_count'].mean():.0f}")

# ============================================================================
# STEP 2: AUTO-DETECT SARIMA PARAMETERS
# ============================================================================
print("\n[Step 2] Auto-detecting optimal SARIMA parameters...")

y_all = monthly_collisions['collision_count'].values

try:
    auto_model = auto_arima(
        y_all,
        seasonal=True,
        m=12,  # Yearly seasonality
        stepwise=True,
        trace=False,
        max_p=5, max_q=5, max_P=2, max_Q=2,
        error_action='ignore',
        suppress_warnings=True,
        n_jobs=-1  # Use all CPU cores
    )
    
    sarima_order = auto_model.order
    sarima_seasonal_order = auto_model.seasonal_order
    print(f"  - Optimal ARIMA order: {sarima_order}")
    print(f"  - Optimal Seasonal order: {sarima_seasonal_order}")
except Exception as e:
    print(f"  - Auto-detection error: {e}")
    print(f"  - Using default: SARIMA(1,1,1)x(1,1,1,12)")
    sarima_order = (1, 1, 1)
    sarima_seasonal_order = (1, 1, 1, 12)

# ============================================================================
# STEP 3: WALK-FORWARD CROSS-VALIDATION
# ============================================================================
print("\n[Step 3] Running walk-forward cross-validation (12 iterations)...")

train_window = 12
n_iterations = 12
rmse_scores = []
predictions_cv = []
actuals_cv = []

for i in range(n_iterations):
    start_idx = max(0, len(y_all) - train_window - (n_iterations - i))
    end_idx = start_idx + train_window
    
    if end_idx < len(y_all):
        y_train = y_all[start_idx:end_idx]
        y_test = y_all[end_idx:end_idx + 1]
        
        try:
            model = SARIMAX(
                y_train,
                order=sarima_order,
                seasonal_order=sarima_seasonal_order,
                enforce_stationarity=False,
                enforce_invertibility=False
            ).fit(disp=False, maxiter=200)
            
            pred = model.forecast(steps=1)[0]
            rmse = np.sqrt((pred - y_test[0]) ** 2)
            
            rmse_scores.append(rmse)
            predictions_cv.append(pred)
            actuals_cv.append(y_test[0])
            
            print(f"  - Fold {i+1:2d}: RMSE = {rmse:6.2f}, Predicted = {pred:6.0f}, Actual = {y_test[0]:6.0f}")
        except Exception as e:
            print(f"  - Fold {i+1} failed: {str(e)[:40]}")

avg_rmse = np.mean(rmse_scores) if rmse_scores else 0
print(f"\n  ✓ Average CV RMSE: {avg_rmse:.2f}")

# ============================================================================
# STEP 4: TRAIN FINAL MODEL AND FORECAST 2026
# ============================================================================
print("\n[Step 4] Training final SARIMA model...")

try:
    final_model = SARIMAX(
        y_all,
        order=sarima_order,
        seasonal_order=sarima_seasonal_order,
        enforce_stationarity=False,
        enforce_invertibility=False
    ).fit(disp=False, maxiter=200)
    
    print("  ✓ Model trained successfully")
except Exception as e:
    print(f"  - Training error: {e}")

# Forecast 2026
print("\nForecasting 2026 (12 months)...")
forecast_steps = 12
forecast_result = final_model.get_forecast(steps=forecast_steps)
forecast_mean = forecast_result.predicted_mean
if hasattr(forecast_mean, 'values'):
    forecast_mean = forecast_mean.values
forecast_ci = forecast_result.conf_int(alpha=0.15)  # 85% confidence interval
if isinstance(forecast_ci, pd.DataFrame):
    forecast_lower = forecast_ci.iloc[:, 0].values
    forecast_upper = forecast_ci.iloc[:, 1].values
else:
    forecast_lower = forecast_ci[:, 0]
    forecast_upper = forecast_ci[:, 1]

# Generate 2026 dates
forecast_months = pd.date_range(start='2026-01-01', end='2026-12-31', freq='MS')

# Ensure non-negative predictions
forecast_mean = np.maximum(forecast_mean, 0)
forecast_lower = np.maximum(forecast_lower, 0)

print(f"  - Mean forecast: {forecast_mean.mean():.0f} collisions/month")
print(f"  - Range: [{forecast_mean.min():.0f}, {forecast_mean.max():.0f}]")

# ============================================================================
# STEP 5: CREATE OUTPUT DATAFRAME
# ============================================================================
print("\n[Step 5] Compiling results...")

# Historical data
df_historical = monthly_collisions.copy()
df_historical.columns = ['month', 'predicted_count']
df_historical['actual_count'] = df_historical['predicted_count']
df_historical['lower_bound'] = df_historical['predicted_count']
df_historical['upper_bound'] = df_historical['predicted_count']
df_historical['model_used'] = 'Actual'

# 2026 forecast
df_forecast = pd.DataFrame({
    'month': forecast_months,
    'actual_count': np.nan,
    'predicted_count': forecast_mean,
    'lower_bound': forecast_lower,
    'upper_bound': forecast_upper,
    'model_used': 'SARIMA'
})

# Combine
df_output = pd.concat([df_historical, df_forecast], ignore_index=True)
df_output['month'] = df_output['month'].dt.strftime('%Y-%m-%d')

# Save
output_file = 'edmonton_collision_forecast_2026.csv'
df_output.to_csv(output_file, index=False)
print(f"  ✓ Saved to {output_file}")

# ============================================================================
# SUMMARY
# ============================================================================
print("\n" + "=" * 80)
print("FORECAST SUMMARY - 2026 (SARIMA)")
print("=" * 80)
print(f"Model: SARIMA{sarima_order}x{sarima_seasonal_order}")
print(f"CV RMSE: {avg_rmse:.2f}")
print(f"\n2026 Forecast:")
print(f"  - Average: {forecast_mean.mean():.0f} collisions/month")
print(f"  - Min: {forecast_mean.min():.0f} (Month {forecast_mean.argmin() + 1})")
print(f"  - Max: {forecast_mean.max():.0f} (Month {forecast_mean.argmax() + 1})")
print(f"  - 85% CI: [{forecast_lower.mean():.0f}, {forecast_upper.mean():.0f}]")
print(f"\nHistorical (2021-{datetime.now().year}):")
print(f"  - Average: {y_all.mean():.0f} collisions/month")
print(f"  - Std Dev: {y_all.std():.0f}")

print("\n✓ Forecast complete!")
