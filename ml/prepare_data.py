# ===============================================
# prepare_data.py
# ===============================================
"""
Data loading and preprocessing utilities for the health monitoring system.
Used by:
- fatigue_risk_model.py
- activity_anomaly_model.py
- activity_index.py
"""

import pandas as pd
import numpy as np

# ------------------------------------------------
# 1️⃣ Load dataset
# ------------------------------------------------
def load_dataset(csv_path: str) -> pd.DataFrame:
    """Load CSV dataset and ensure correct types."""
    print(f"--- Loading dataset from {csv_path} ---")
    df = pd.read_csv(csv_path)

    # Basic sanity checks
    if 'user_id' not in df.columns:
        raise ValueError("❌ Missing 'user_id' column in dataset")

    # Convert date
    if 'date' in df.columns:
        df['date'] = pd.to_datetime(df['date'], errors='coerce')
    else:
        print("⚠️ No 'date' column found — will generate synthetic later.")

    # Map gender if available
    if 'gender' in df.columns and 'gender_numeric' not in df.columns:
        df['gender_numeric'] = df['gender'].map({'M': 1, 'F': 0}).fillna(0)

    # Sort by user and date
    if 'date' in df.columns:
        df = df.sort_values(['user_id', 'date'])
    else:
        df = df.sort_values(['user_id'])

    df = df.reset_index(drop=True)
    print(f"✅ Dataset loaded: {len(df)} rows, {len(df.columns)} columns")
    return df


# ------------------------------------------------
# 2️⃣ Compute rolling statistics (7-day z-scores)
# ------------------------------------------------
def compute_rolling_features(df: pd.DataFrame, cols=None, window=7) -> pd.DataFrame:
    """Add 7-day z-score and delta features for selected columns."""
    if cols is None:
        cols = ['steps_total', 'sleep_hours_total']

    df = df.copy()

    for col in cols:
        if col not in df.columns:
            print(f"⚠️ Column {col} missing, skipping...")
            continue

        df[f'z_{col}_7d'] = (
            df.groupby('user_id')[col]
            .transform(lambda x: (x - x.rolling(window, min_periods=1).mean()) /
                                (x.rolling(window, min_periods=1).std()))
        )

        df[f'd_{col}_7d'] = df.groupby('user_id')[col].diff()

    print(f"✅ Rolling features added: {cols}")
    return df


# ------------------------------------------------
# 3️⃣ Clean up NaN and invalid data
# ------------------------------------------------
def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    """Remove invalid or incomplete rows."""
    before = len(df)
    df = df.dropna(subset=['steps_total', 'sleep_hours_total'], how='any')
    df = df.replace([np.inf, -np.inf], np.nan).dropna()
    removed = before - len(df)
    print(f"✅ Cleaned data — removed {removed} rows with NaNs or inf values.")
    return df


# ------------------------------------------------
# 4️⃣ High-level pipeline
# ------------------------------------------------
def prepare_full_dataset(csv_path: str) -> pd.DataFrame:
    """End-to-end data preparation pipeline."""
    df = load_dataset(csv_path)
    df = compute_rolling_features(df)
    df = clean_data(df)
    return df
