#!/usr/bin/env python
# coding: utf-8

# In[ ]:


import pandas as pd

def compute_activity_index(df: pd.DataFrame, steps_goal: int = 10000, sleep_goal: float = 8.0) -> pd.DataFrame:
    """
    Computes the daily Activity Index for each user record.

    The index represents an overall activity balance between physical
    effort (steps) and recovery (sleep). The final score is normalized
    between 0 and 1.

    Parameters
    ----------
    df : pd.DataFrame
        Input DataFrame containing at least 'steps_total' and 'sleep_hours_total' columns.
    steps_goal : int, optional
        Target daily step count (default = 10,000).
    sleep_goal : float, optional
        Target daily sleep hours (default = 8.0).

    Returns
    -------
    pd.DataFrame
        The same DataFrame with a new column 'activity_index' added.
    """

    if 'steps_total' not in df.columns or 'sleep_hours_total' not in df.columns:
        raise ValueError("❌ Missing required columns: 'steps_total' or 'sleep_hours_total'")

    # Weighted balance between activity and sleep
    df['activity_index'] = (
        0.6 * (df['steps_total'] / steps_goal) +
        0.4 * (df['sleep_hours_total'] / sleep_goal)
    ).clip(upper=1.0)

    print("✅ Activity Index calculated successfully for all records.")
    return df


# In[ ]:


# --- local test run ---
if __name__ == "__main__":
    # Example test data
    data = {
        "user_id": [1, 2, 3],
        "steps_total": [8000, 12000, 4000],
        "sleep_hours_total": [7.5, 8.0, 5.0],
    }

    df_test = pd.DataFrame(data)
    df_result = compute_activity_index(df_test)
    print(df_result)

