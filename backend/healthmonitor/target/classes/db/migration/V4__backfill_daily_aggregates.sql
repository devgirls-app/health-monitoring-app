WITH daily_raw_aggregates AS (
    SELECT
        hd.user_id,
        (hd.timestamp AT TIME ZONE 'UTC')::date AS date,
        SUM(COALESCE(hd.steps, 0)) AS steps_total,
        SUM(COALESCE(hd.calories, 0)) AS calories_total,
        AVG(NULLIF(hd.heart_rate, 0)) AS hr_mean,
        MAX(hd.heart_rate) AS hr_max,
        SUM(COALESCE(hd.sleep_hours, 0)) AS sleep_hours_total
    FROM health_data hd
    GROUP BY hd.user_id, (hd.timestamp AT TIME ZONE 'UTC')::date
),
calculated_deltas AS (
    SELECT
        *,
        AVG(steps_total) OVER (
            PARTITION BY user_id
            ORDER BY date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS avg_7d_steps,

        AVG(sleep_hours_total) OVER (
            PARTITION BY user_id
            ORDER BY date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS avg_7d_sleep

        FROM daily_raw_aggregates
)

INSERT INTO daily_aggregates (
    user_id,
    date,
    steps_total,
    calories_total,
    hr_mean,
    hr_max,
    sleep_hours_total,
    d_steps_7d,
    d_sleep_7d,
    created_at,
    updated_at
)
SELECT
    user_id,
    date,
    steps_total,
    calories_total,
    hr_mean,
    hr_max,
    sleep_hours_total,

    (steps_total - avg_7d_steps) AS d_steps_7d,
    (sleep_hours_total - avg_7d_sleep) AS d_sleep_7d,

    NOW(),
    NOW()
FROM calculated_deltas
ON CONFLICT (user_id, date) DO UPDATE SET
    steps_total = EXCLUDED.steps_total,
    calories_total = EXCLUDED.calories_total,
    hr_mean = EXCLUDED.hr_mean,
    hr_max = EXCLUDED.hr_max,
    sleep_hours_total = EXCLUDED.sleep_hours_total,
    d_steps_7d = EXCLUDED.d_steps_7d,
    d_sleep_7d = EXCLUDED.d_sleep_7d,
    updated_at = NOW();