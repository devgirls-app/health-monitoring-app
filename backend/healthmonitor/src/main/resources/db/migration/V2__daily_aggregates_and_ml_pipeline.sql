-- ==========================================================
-- V2 Script: Daily Aggregates and ML Pipeline
-- ✅ ИСПРАВЛЕНО: Таблицы в snake_case, Колонки в CamelCase, ID в BIGSERIAL/BIGINT
-- ==========================================================

CREATE TABLE IF NOT EXISTS daily_aggregates (
                                                agg_id BIGSERIAL PRIMARY KEY,
                                                user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
                                                date DATE NOT NULL,
                                                steps_total INT,
                                                calories_total DECIMAL(10,2),
                                                hr_mean DECIMAL(6,2),
                                                hr_max INT,
                                                sleep_hours_total DECIMAL(5,2),
                                                z_hr_mean DECIMAL(6,3),
                                                z_steps DECIMAL(6,3),
                                                d_steps_7d DECIMAL(10,2),
                                                d_sleep_7d DECIMAL(6,2),
                                                created_at TIMESTAMP DEFAULT NOW(),
                                                updated_at TIMESTAMP DEFAULT NOW(),
                                                UNIQUE(user_id, date)
);

CREATE TABLE IF NOT EXISTS user_stats (
                                          user_id BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
                                          hr_mean_baseline DECIMAL(6,2),
                                          hr_mean_std DECIMAL(6,2),
                                          steps_baseline DECIMAL(10,2),
                                          steps_std DECIMAL(10,2),
                                          updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS day_labels (
                                          label_id BIGSERIAL PRIMARY KEY,
                                          user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
                                          date DATE NOT NULL,
                                          stress_label SMALLINT,
                                          fatigue_label SMALLINT,
                                          note TEXT,
                                          UNIQUE(user_id, date)
);

CREATE TABLE IF NOT EXISTS model_registry (
                                              model_id BIGSERIAL PRIMARY KEY,
                                              name VARCHAR(100) NOT NULL,
                                              version VARCHAR(50) NOT NULL,
                                              path VARCHAR(500) NOT NULL,
                                              is_active BOOLEAN DEFAULT FALSE,
                                              created_at TIMESTAMP DEFAULT NOW(),
                                              UNIQUE(name, version)
);

ALTER TABLE ml_insights
    ADD COLUMN IF NOT EXISTS agg_id BIGINT NULL REFERENCES daily_aggregates(agg_id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS probability DECIMAL(6,5),
    ADD COLUMN IF NOT EXISTS model_id BIGINT NULL REFERENCES model_registry(model_id);

ALTER TABLE recommendations
    ADD COLUMN IF NOT EXISTS severity VARCHAR(20) DEFAULT 'advisory';

ALTER TABLE recommendations
    ADD CONSTRAINT recommendations_severity_chk
        CHECK (severity IN ('advisory','warning','critical'));

-- ✅ ИСПРАВЛЕНО: Имена таблиц и колонок в индексах
CREATE INDEX IF NOT EXISTS idx_healthdata_user_ts ON health_data(user_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_dailyaggregates_user_date ON daily_aggregates(user_id, date);
CREATE INDEX IF NOT EXISTS idx_mlinsights_agg ON ml_insights(agg_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_user_created ON recommendations(user_id, created_at);