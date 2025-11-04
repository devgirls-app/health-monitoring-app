# ===============================================
# utils.py
# ===============================================
"""
Utility functions for logging, metrics, and file I/O.
Used across ML models and backend integration.
"""

import json
import joblib
from sklearn.metrics import accuracy_score, f1_score, roc_auc_score, precision_score, recall_score

# ------------------------------------------------
# 1️⃣ Model I/O
# ------------------------------------------------
def save_model(model, path):
    """Save model using joblib."""
    joblib.dump(model, path)
    print(f"✅ Model saved to {path}")


def load_model(path):
    """Load model from joblib file."""
    model = joblib.load(path)
    print(f"✅ Model loaded from {path}")
    return model


# ------------------------------------------------
# 2️⃣ Metrics
# ------------------------------------------------
def compute_metrics(y_true, y_pred, y_proba):
    """Return a dictionary of standard binary classification metrics."""
    metrics = {
        "acc": accuracy_score(y_true, y_pred),
        "f1": f1_score(y_true, y_pred),
        "auc": roc_auc_score(y_true, y_proba),
        "precision": precision_score(y_true, y_pred),
        "recall": recall_score(y_true, y_pred)
    }
    return metrics


def print_metrics(metrics_dict):
    """Nicely print model performance."""
    print("\nModel metrics:")
    for k, v in metrics_dict.items():
        print(f"  {k}: {v:.4f}")


# ------------------------------------------------
# 3️⃣ JSON I/O
# ------------------------------------------------
def save_json(data, path):
    """Save dictionary to JSON."""
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"✅ JSON saved to {path}")


def load_json(path):
    """Load JSON file."""
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    return data


# ------------------------------------------------
# 4️⃣ Notifications / Logging
# ------------------------------------------------
def notify_user(user_id, message):
    """Simulate sending a notification to a user."""
    print(f"📩 Notification → User {user_id}: {message}")
