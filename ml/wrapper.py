#!/usr/bin/env python
# coding: utf-8

# In[30]:


# wrapper.ipynb - Cell 1

import sys
from pathlib import Path

# Добавляем путь к папке models
CURRENT_DIR = Path(__file__).parent
MODELS_DIR = CURRENT_DIR / "models"
sys.path.append(str(MODELS_DIR))
import pandas as pd
import joblib

# Imports from your models (assuming .py files)
from models.fatigue_risk_model import create_fatigue_model_dataset, train_fatigue_model
from models.activity_anomaly_model import prepare_activity_data, train_activity_anomaly_model
from models.activity_index import compute_activity_index

# Paths
CSV_PATH = "health_fitness_dataset.csv"  # Path to your CSV
EXPORT_DIR = Path("export")
EXPORT_DIR.mkdir(exist_ok=True)


# In[31]:


# wrapper.ipynb - Cell 2
print("=== Preparing data for fatigue risk model ===")
df_fatigue = create_fatigue_model_dataset(CSV_PATH)
df_fatigue.head()


# In[32]:


# wrapper.ipynb - Cell 3
print("=== Training fatigue risk model ===")
fatigue_model, fatigue_metrics = train_fatigue_model(data_csv_path=CSV_PATH, model_export_dir=EXPORT_DIR)

print("\nFatigue model metrics:")
for k, v in fatigue_metrics.items():
    print(f"{k}: {v:.4f}")


# In[33]:


# wrapper.ipynb - Cell 4
print("=== Preparing data for activity anomaly model ===")
df_anomaly = prepare_activity_data(CSV_PATH)
df_anomaly.head()


# In[ ]:


# wrapper.ipynb - Cell 5
print("=== Training activity anomaly model ===")
df_anomaly, anomaly_model_path = train_activity_anomaly_model(df_anomaly, EXPORT_DIR)


# In[35]:


# wrapper.ipynb - Cell 6
print("=== Computing Activity Index ===")
df_index = compute_activity_index(df_anomaly)
df_index[['user_id', 'date', 'steps_total', 'sleep_hours_total', 'activity_index']].head()


# In[41]:


# === wrapper.ipynb - Cell 7 (final fixed version) ===
print("=== Example predictions (first 5 rows) ===")

FEATURES = [
    'steps_total', 'calories_total', 'sleep_hours_total',
    'age', 'gender_numeric', 'height_cm', 'weight_kg',
    'd_sleep_7d', 'd_steps_7d'
]

# --- Step 1: Ensure we have a valid 'date' column ---
if 'date' not in df_fatigue.columns or df_fatigue['date'].isna().all():
    print("⚠️ 'date' column missing — generating synthetic date ranges per user...")

    df_fatigue = df_fatigue.sort_values('user_id').reset_index(drop=True)
    synthetic_dates = []

    # Create smaller date ranges per user to prevent overflow
    for uid, group in df_fatigue.groupby('user_id'):
        n = len(group)
        start_date = pd.Timestamp("2024-01-01") + pd.Timedelta(days=int(uid))
        user_dates = pd.date_range(start=start_date, periods=n, freq='D')
        synthetic_dates.extend(user_dates)

    df_fatigue['date'] = synthetic_dates

# --- Step 2: Example predictions ---
for i, row in df_fatigue.head(5).iterrows():
    X_sample = row[FEATURES].values.reshape(1, -1)
    fatigue_pred = fatigue_model.predict(X_sample)[0]
    fatigue_proba = fatigue_model.predict_proba(X_sample)[0, 1]

    # Safely get anomaly and index if they exist
    anomaly_flag = df_index.iloc[i]['activity_anomaly'] if 'activity_anomaly' in df_index.columns else None
    activity_score = df_index.iloc[i]['activity_index'] if 'activity_index' in df_index.columns else None


    # Convert to proper date format
    date_value = pd.to_datetime(row['date']).date()

    print(f"User: {int(row['user_id'])} | Date: {date_value}")
    print(f"  Fatigue Risk: {fatigue_pred} (prob: {fatigue_proba:.2f})")
    if anomaly_flag is not None:
        print(f"  Activity Anomaly: {anomaly_flag}")
    if activity_score is not None:
        print(f"  Activity Index: {activity_score:.2f}")
    print("---")



# In[49]:


# === Cell 8: Combine all model results into a unified report ===

import pandas as pd

print("=== Generating unified daily health report ===")

# --- 0️⃣ Safety checks ---
if 'df_fatigue' not in locals():
    raise ValueError("❌ df_fatigue not found — run the preprocessing cell first.")
if 'fatigue_model' not in locals():
    raise ValueError("❌ fatigue_model not found — please train it before running this cell.")
if 'df_index' not in locals():
    raise ValueError("❌ df_index not found — please compute activity index first.")

FEATURES = [
    'steps_total', 'calories_total', 'sleep_hours_total',
    'age', 'gender_numeric', 'height_cm', 'weight_kg',
    'd_sleep_7d', 'd_steps_7d'
]

# --- 1️⃣ Predict fatigue ---
df_fatigue = df_fatigue.copy()
df_fatigue['fatigue_pred'] = fatigue_model.predict(df_fatigue[FEATURES])
df_fatigue['fatigue_proba'] = fatigue_model.predict_proba(df_fatigue[FEATURES])[:, 1]

# --- 2️⃣ Keep essential columns only ---
df_fatigue_slim = df_fatigue[['user_id', 'date', 'fatigue_pred', 'fatigue_proba']].reset_index(drop=True)

# --- 3️⃣ Align df_index and df_fatigue by row order or by user/date if available ---
if 'user_id' in df_index.columns and 'date' in df_index.columns:
    df_index_slim = df_index[['user_id', 'date', 'activity_index', 'activity_anomaly']].reset_index(drop=True)
    # Merge by both user_id and date
    df_report = pd.merge(df_fatigue_slim, df_index_slim, on=['user_id', 'date'], how='inner')
else:
    # fallback: align by index if date missing
    df_report = pd.concat([df_fatigue_slim, df_index[['activity_index', 'activity_anomaly']].reset_index(drop=True)], axis=1)

# --- 4️⃣ Clean and format ---
df_report['fatigue_label'] = df_report['fatigue_pred'].map({0: 'Normal', 1: 'Fatigued'})
df_report['fatigue_proba'] = df_report['fatigue_proba'].round(2)
df_report['activity_index'] = df_report['activity_index'].round(2)

# --- 5️⃣ Preview and export ---
print("\n=== Health Report Preview (first 10 days) ===")
print(df_report.head(10).to_string(index=False))

report_path = EXPORT_DIR / "daily_health_report.csv"
df_report.to_csv(report_path, index=False)
print(f"\n✅ Unified report saved to: {report_path.resolve()}")


# In[50]:


# === Cell 9: Visualization of fatigue and activity index over time ===

import matplotlib.pyplot as plt
import pandas as pd

print("=== Visualizing fatigue and activity trends ===")

# --- 1️⃣ Ensure df_report is available ---
if 'df_report' not in locals():
    raise ValueError("❌ df_report not found — run previous cells first (e.g., Cell 8).")

# --- 2️⃣ Remove duplicate columns safely ---
if df_report.columns.duplicated().any():
    print("⚠️ Duplicate columns detected — keeping first occurrence of each.")
    df_report = df_report.loc[:, ~df_report.columns.duplicated()]

# --- 3️⃣ Handle missing, duplicated, or invalid date columns ---
date_cols = [col for col in df_report.columns if col.startswith("date")]
if len(date_cols) > 1:
    print(f"⚠️ Found multiple date columns: {date_cols} — keeping only '{date_cols[0]}'")
    df_report = df_report.drop(columns=date_cols[1:], errors="ignore")

if 'date' not in df_report.columns:
    print("⚠️ 'date' column missing — generating synthetic date sequence per user...")
    if 'user_id' not in df_report.columns:
        raise ValueError("❌ 'user_id' column is missing — cannot generate synthetic dates.")
    df_report = df_report.sort_values('user_id').reset_index(drop=True)

    synthetic_dates = []
    for user_id, group in df_report.groupby('user_id'):
        n = len(group)
        start_date = pd.Timestamp("2024-01-01") + pd.Timedelta(days=int(user_id))
        user_dates = pd.date_range(start=start_date, periods=n, freq='D')
        synthetic_dates.extend(user_dates)
    df_report['date'] = synthetic_dates
else:
    df_report['date'] = pd.to_datetime(df_report['date'], errors='coerce')

    all_nan = bool(df_report['date'].isna().all())
    if all_nan:
        print("⚠️ All 'date' values are NaN — regenerating synthetic dates...")
        synthetic_dates = []
        for user_id, group in df_report.groupby('user_id'):
            n = len(group)
            start_date = pd.Timestamp("2024-01-01") + pd.Timedelta(days=int(user_id))
            user_dates = pd.date_range(start=start_date, periods=n, freq='D')
            synthetic_dates.extend(user_dates)
        df_report['date'] = synthetic_dates

# --- 4️⃣ Select one user for visualization ---
if 'user_id' not in df_report.columns:
    raise ValueError("❌ 'user_id' column missing in df_report after cleaning!")

user_id = df_report['user_id'].iloc[0]
df_user = df_report[df_report['user_id'] == user_id].copy()

if df_user.empty:
    raise ValueError(f"❌ No data found for user {user_id}.")

# --- 5️⃣ Plot activity index and fatigue markers ---
plt.figure(figsize=(12, 6))
plt.plot(df_user['date'], df_user['activity_index'], label='Activity Index', color='blue', linewidth=2)

fatigue_days = df_user[df_user['fatigue_pred'] == 1]
if not fatigue_days.empty:
    plt.scatter(
        fatigue_days['date'],
        fatigue_days['activity_index'],
        color='red', s=70, label='Fatigue Risk', zorder=5
    )

# --- 6️⃣ Final styling ---
plt.title(f"User {int(user_id)} — Fatigue Risk vs Activity Index", fontsize=14)
plt.xlabel("Date", fontsize=12)
plt.ylabel("Activity Index", fontsize=12)
plt.ylim(0, 1.1)
plt.grid(True, linestyle='--', alpha=0.5)
plt.legend()
plt.tight_layout()

# ✅ Save plot instead of blocking execution
plot_path = EXPORT_DIR / f"user_{int(user_id)}_fatigue_activity_trend.png"
plt.savefig(plot_path, dpi=300)
plt.close()

print(f"✅ Visualization saved to: {plot_path.resolve()}")