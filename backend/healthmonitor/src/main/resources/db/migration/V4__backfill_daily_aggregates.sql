
INSERT INTO daily_aggregates (user_id, date, steps_total, calories_total, hr_mean, hr_max, sleep_hours_total, created_at, updated_at)
SELECT
    hd.user_id,
    (hd.timestamp AT TIME ZONE 'UTC')::date AS date,
  SUM(COALESCE(hd.steps,0)) AS steps_total,
  SUM(COALESCE(hd.calories,0)) AS calories_total,
  AVG(NULLIF(hd.heart_rate,0)) AS hr_mean,
  MAX(hd.heart_rate) AS hr_max,
  SUM(COALESCE(hd.sleep_hours,0)) AS sleep_hours_total,
  NOW(), NOW()
FROM health_data hd
GROUP BY hd.user_id, (hd.timestamp AT TIME ZONE 'UTC')::date
ON CONFLICT (user_id, date) DO NOTHING;