#!/usr/bin/env python
# coding: utf-8

# In[ ]:


import pandas as pd
import numpy as np
from pathlib import Path
from sklearn.ensemble import IsolationForest
import joblib

# Import utilities (optional, if available)
from prepare_data import compute_rolling_features, clean_data
from utils import save_model


# In[ ]:


def _zscore(series: pd.Series, window=7, min_periods=3) -> pd.Series:
    """Compute rolling z-score for a time series."""
    mean = series.rolling(window, min_periods=min_periods).mean()
    std = series.rolling(window, min_periods=min_periods).std()
    std = std.replace(0, np.nan)
    return (series - mean) / std


def _delta_from_mean(series: pd.Series, window=7, min_periods=3) -> pd.Series:
    """Compute deviation from rolling mean."""
    mean = series.rolling(window, min_periods=min_periods).mean()
    return series - mean


# In[ ]:


def prepare_activity_data(csv_path: str) -> pd.DataFrame:
    """
    Load and preprocess user activity data for anomaly detection.
    Includes feature engineering (rolling z-scores and deltas).
    """
    print(f"--- Loading dataset from {csv_path} ---")
    df = pd.read_csv(csv_path)

    # Standardize column names
    df = df.rename(columns={
        'participant_id': 'user_id',
        'daily_steps': 'steps_total',
        'hours_sleep': 'sleep_hours_total',
        'calories_burned': 'calories_total'
    })

    # Convert types and sort
    df['date'] = pd.to_datetime(df['date'], errors='coerce')
    df['gender_numeric'] = df['gender'].map({'M': 1, 'F': 0})
    df = df.sort_values(['user_id', 'date']).reset_index(drop=True)

    # Compute 7-day z-scores and deltas
    print("Computing rolling statistics...")
    df['z_steps_7d'] = df.groupby('user_id', group_keys=False)['steps_total'].apply(_zscore)
    df['z_sleep_7d'] = df.groupby('user_id', group_keys=False)['sleep_hours_total'].apply(_zscore)
    df['d_steps_7d'] = df.groupby('user_id', group_keys=False)['steps_total'].apply(_delta_from_mean)
    df['d_sleep_7d'] = df.groupby('user_id', group_keys=False)['sleep_hours_total'].apply(_delta_from_mean)

    # Clean invalid values
    df.replace([np.inf, -np.inf], np.nan, inplace=True)
    df_cleaned = df.dropna(subset=['z_steps_7d', 'z_sleep_7d', 'd_steps_7d', 'd_sleep_7d'])
    print(f"✅ Data prepared: {len(df_cleaned)} rows after cleaning.")
    return df_cleaned


# In[ ]:


def train_activity_anomaly_model(df: pd.DataFrame, export_dir: Path):
    """
    Train IsolationForest to detect abnormal activity patterns.
    """
    FEATURES = ['steps_total', 'sleep_hours_total', 'calories_total', 'd_steps_7d', 'd_sleep_7d']
    X = df[FEATURES].fillna(0.0).values

    model = IsolationForest(
        n_estimators=200,
        contamination=0.05,   # Expect ~5% anomalies
        random_state=42,
        n_jobs=-1
    )
    model.fit(X)

    # Predict anomalies: -1 = anomaly, 1 = normal
    df['activity_anomaly'] = (model.predict(X) == -1).astype(int)

    print("\n--- Anomaly Balance ---")
    print(df['activity_anomaly'].value_counts(normalize=True))

    # Save model
    export_dir.mkdir(exist_ok=True)
    model_path = export_dir / "activity_anomaly_model.pkl"
    joblib.dump(model, model_path)
    print(f"✅ Model saved to: {model_path.resolve()}")

    return df, model_path


# In[ ]:


def compute_activity_index(df: pd.DataFrame, steps_goal=10000, sleep_goal=8.0):
    """
    Compute an overall Activity Index based on steps and sleep balance.
    The index is clipped between 0 and 1.
    """
    df['activity_index'] = (
        0.6 * (df['steps_total'] / steps_goal) +
        0.4 * (df['sleep_hours_total'] / sleep_goal)
    ).clip(upper=1.0)

    print("✅ Activity Index calculated for each record.")
    return df


# In[ ]:


if __name__ == "__main__":
    # --- Configuration ---
    CSV_PATH = "health_fitness_dataset.csv"
    EXPORT_DIR = Path("export")

    print("=== Step 1: Data Preparation ===")
    df_ready = prepare_activity_data(CSV_PATH)

    print("\n=== Step 2: Train Isolation Forest Model ===")
    df_ready, model_path = train_activity_anomaly_model(df_ready, EXPORT_DIR)

    print("\n=== Step 3: Compute Activity Index ===")
    df_ready = compute_activity_index(df_ready)

    print("\n=== Step 4: Preview Results ===")
    display(df_ready[['user_id', 'date', 'steps_total', 'sleep_hours_total',
                      'activity_anomaly', 'activity_index']].head(10))

