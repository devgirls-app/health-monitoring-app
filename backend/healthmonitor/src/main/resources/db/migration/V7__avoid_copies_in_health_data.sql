ALTER TABLE health_data
    ADD COLUMN day DATE;

UPDATE health_data
SET day = timestamp::date
WHERE day IS NULL;

DELETE FROM health_data h
    USING health_data h2
WHERE
    h.data_id < h2.data_id
  AND h.user_id = h2.user_id
  AND h.day = h2.day
  AND (h.source IS NOT DISTINCT FROM h2.source OR (h.source IS NULL AND h2.source IS NULL));

ALTER TABLE health_data
    ADD CONSTRAINT ux_health_data_user_day_source
        UNIQUE (user_id, day, source);