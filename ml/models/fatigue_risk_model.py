#!/usr/bin/env python
# coding: utf-8

# In[5]:


import pandas as pd
import numpy as np
import json
from pathlib import Path

# --- ML imports ---
from sklearn.model_selection import GroupShuffleSplit
from sklearn.metrics import (
    accuracy_score, f1_score, roc_auc_score, precision_score, recall_score
)
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier

# --- ONNX export (optional) ---
try:
    from skl2onnx import convert_sklearn
    from skl2onnx.common.data_types import FloatTensorType
except ImportError:
    print("⚠️ Warning: 'skl2onnx' not installed. Run 'pip install skl2onnx' to enable ONNX export.")

# --- Project imports ---
from prepare_data import prepare_full_dataset
from utils import save_model, save_json, compute_metrics, print_metrics


# In[ ]:


def _zscore(series: pd.Series, window=7, min_periods=3) -> pd.Series:
    """Compute rolling z-score."""
    mean = series.rolling(window, min_periods=min_periods).mean()
    std = series.rolling(window, min_periods=min_periods).std()
    std = std.replace(0, np.nan)
    return (series - mean) / std


def _delta_from_mean(series: pd.Series, window=7, min_periods=3) -> pd.Series:
    """Compute deviation from rolling mean."""
    mean = series.rolling(window, min_periods=min_periods).mean()
    return series - mean


# In[ ]:


def create_fatigue_model_dataset(csv_path: str) -> pd.DataFrame:
    """
    Load raw health data and create engineered features + fatigue target label.
    """
    print(f"--- Loading dataset from {csv_path} ---")
    try:
        df = pd.read_csv(csv_path)
    except FileNotFoundError:
        print(f"❌ ERROR: File not found at {csv_path}")
        return pd.DataFrame()

    # Standardize column names
    df = df.rename(columns={
        'participant_id': 'user_id',
        'daily_steps': 'steps_total',
        'hours_sleep': 'sleep_hours_total',
        'calories_burned': 'calories_total'
    })

    # Ensure consistent format
    df['date'] = pd.to_datetime(df['date'], errors='coerce')
    df['gender_numeric'] = df['gender'].map({'M': 1, 'F': 0})
    df = df.sort_values(['user_id', 'date'])

    print("Calculating rolling z-scores and deltas...")
    df['z_sleep_7d'] = df.groupby('user_id', group_keys=False)['sleep_hours_total'].apply(_zscore)
    df['z_steps_7d'] = df.groupby('user_id', group_keys=False)['steps_total'].apply(_zscore)
    df['d_sleep_7d'] = df.groupby('user_id', group_keys=False)['sleep_hours_total'].apply(_delta_from_mean)
    df['d_steps_7d'] = df.groupby('user_id', group_keys=False)['steps_total'].apply(_delta_from_mean)

    # Clean missing values
    features_to_check = ['z_sleep_7d', 'z_steps_7d', 'd_sleep_7d', 'd_steps_7d']
    before = len(df)
    df.replace([np.inf, -np.inf], np.nan, inplace=True)
    df_clean = df.dropna(subset=features_to_check)
    print(f"Removed {before - len(df_clean)} rows with NaNs (initial z-score warm-up).")

    # Create binary fatigue target
    df_clean['y_target_fatigue'] = (
        (df_clean['z_sleep_7d'] < -1.0) |   # Poor sleep
        (df_clean['z_steps_7d'] > 1.5)      # Overactive day
    ).astype(int)

    print("\n--- Fatigue label distribution ---")
    print(df_clean['y_target_fatigue'].value_counts(normalize=True))
    print("-------------------------------------------------")

    # Final dataset columns
    cols = [
        'user_id', 'date', 'y_target_fatigue',
        'steps_total', 'calories_total', 'sleep_hours_total',
        'age', 'gender_numeric', 'height_cm', 'weight_kg',
        'z_sleep_7d', 'z_steps_7d', 'd_sleep_7d', 'd_steps_7d'
    ]
    cols = [c for c in cols if c in df_clean.columns]

    df_final = df_clean[cols].copy()
    print(f"✅ Dataset ready: {len(df_final)} rows, {len(cols)} columns")
    return df_final


# In[ ]:


def train_fatigue_model(data_csv_path, model_export_dir):
    """
    Train the fatigue prediction model, evaluate, and export results.
    """
    # Paths
    export_dir = Path(model_export_dir) 
    export_dir.mkdir(exist_ok=True)
    
    onnx_path = export_dir / "fatigue_model_v1.onnx"
    features_json = export_dir / "fatigue_model_v1_features.json"
    metrics_json = export_dir / "fatigue_model_v1_metrics.json"

    print("=== Step 1: Data preparation ===")
    df_ready = create_fatigue_model_dataset(data_csv_path)
    if df_ready.empty:
        print("❌ Dataset is empty. Cannot continue.")
        return None, {}

    print("\n=== Step 2: Define X, y, groups ===")
    FEATURES = [
        'steps_total', 'calories_total', 'sleep_hours_total',
        'age', 'gender_numeric', 'height_cm', 'weight_kg',
        'd_sleep_7d', 'd_steps_7d'
    ]
    X = df_ready[FEATURES].fillna(0.0).values
    y = df_ready['y_target_fatigue'].values
    groups = df_ready['user_id'].values
    print(f"Features ready: {len(FEATURES)} total")

    print("\n=== Step 3: Train/test split ===")
    gss = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
    train_idx, test_idx = next(gss.split(X, y, groups=groups))
    X_train, X_test = X[train_idx], X[test_idx]
    y_train, y_test = y[train_idx], y[test_idx]
    print(f"Train: {len(X_train)} | Test: {len(X_test)}")

    print("\n=== Step 4: Model training ===")
    models = {}

    # --- Logistic Regression ---
    logreg = Pipeline([
        ("scaler", StandardScaler()),
        ("clf", LogisticRegression(max_iter=2000, class_weight="balanced", random_state=42))
    ])
    logreg.fit(X_train, y_train)
    proba_lr = logreg.predict_proba(X_test)[:, 1]
    pred_lr = (proba_lr >= 0.5).astype(int)
    models["logreg"] = {
        "model": logreg,
        "metrics": compute_metrics(y_test, pred_lr, proba_lr)
    }

    # --- Random Forest ---
    rf = RandomForestClassifier(
        n_estimators=100, min_samples_leaf=5,
        random_state=42, n_jobs=-1, class_weight="balanced_subsample"
    )
    rf.fit(X_train, y_train)
    proba_rf = rf.predict_proba(X_test)[:, 1]
    pred_rf = (proba_rf >= 0.5).astype(int)
    models["rf"] = {
        "model": rf,
        "metrics": compute_metrics(y_test, pred_rf, proba_rf)
    }

    # --- Select best model by AUC ---
    best_name = max(models, key=lambda k: models[k]["metrics"]["auc"])
    best = models[best_name]
    print(f"\n🎯 Best model: {best_name.upper()}")
    print_metrics(best["metrics"])

    print("\n=== Step 5: Export ===")
    try:
        initial_type = [('input', FloatTensorType([None, len(FEATURES)]))]
        onx = convert_sklearn(best["model"], initial_types=initial_type, options={'zipmap': False})
        with open(onnx_path, "wb") as f:
            f.write(onx.SerializeToString())
        print(f"✅ Model exported to {onnx_path}")
    except Exception as e:
        print(f"⚠️ ONNX export failed: {e}")

    # Save metadata
    save_json({"features": FEATURES}, features_json)
    save_json(best["metrics"], metrics_json)

    # Also export model in .pkl format for backend
    save_model(best["model"], export_dir / "fatigue_model_v1.pkl")

    print("✅ Export complete.")
    return best["model"], best["metrics"]


# In[ ]:


if __name__ == "__main__":
    model, metrics = train_fatigue_model(
        data_csv_path="health_fitness_dataset.csv",
        model_export_dir="export"
    )
    print("\n✅ Model training finished successfully.")
    