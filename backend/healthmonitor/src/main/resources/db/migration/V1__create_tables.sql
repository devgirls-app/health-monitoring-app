-- Drop tables if they already exist
DROP TABLE IF EXISTS kafka_logs CASCADE;
DROP TABLE IF EXISTS recommendations CASCADE;
DROP TABLE IF EXISTS ml_insights CASCADE;
DROP TABLE IF EXISTS health_trends CASCADE;
DROP TABLE IF EXISTS health_data CASCADE;
DROP TABLE IF EXISTS device CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ==========================================================
CREATE TABLE users (
                       user_id BIGSERIAL PRIMARY KEY,
                       name VARCHAR(255),
                       age INT,
                       gender VARCHAR(50),
                       height DECIMAL(5,2),
                       weight DECIMAL(5,2),
                       created_at TIMESTAMP DEFAULT NOW(),
                       updated_at TIMESTAMP DEFAULT NOW()
);
-- ==========================================================
CREATE TABLE device (
                        device_id BIGSERIAL PRIMARY KEY,
                        user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
                        type VARCHAR(100),
                        os_version VARCHAR(100),
                        created_at TIMESTAMP DEFAULT NOW(),
                        updated_at TIMESTAMP DEFAULT NOW()
);
-- ==========================================================
CREATE TABLE health_data (
                             data_id BIGSERIAL PRIMARY KEY,
                             user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
                             timestamp TIMESTAMP NOT NULL,
                             heart_rate INT,
                             steps INT,
                             calories DECIMAL(10,2),
                             sleep_hours DECIMAL(4,2),
                             source VARCHAR(50),
                             created_at TIMESTAMP DEFAULT NOW(),
                             updated_at TIMESTAMP DEFAULT NOW()
);
-- ==========================================================
CREATE TABLE health_trends (
                               trend_id BIGSERIAL PRIMARY KEY,
                               user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
                               avg_heart_rate DECIMAL(5,2),
                               daily_steps INT,
                               trend_label VARCHAR(255),
                               date DATE,
                               created_at TIMESTAMP DEFAULT NOW(),
                               updated_at TIMESTAMP DEFAULT NOW()
);
-- ==========================================================
CREATE TABLE ml_insights (
                             insight_id BIGSERIAL PRIMARY KEY,
                             trend_id BIGINT REFERENCES health_trends(trend_id) ON DELETE CASCADE,
                             prediction_type VARCHAR(100),
                             confidence_score DECIMAL(5,2),
                             result_description TEXT,
                             created_at TIMESTAMP DEFAULT NOW(),
                             updated_at TIMESTAMP DEFAULT NOW()
);
-- ==========================================================
CREATE TABLE recommendations (
                                 rec_id BIGSERIAL PRIMARY KEY,
                                 user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
                                 recommendation_text TEXT,
                                 source VARCHAR(50),
                                 created_at TIMESTAMP DEFAULT NOW()
);
-- ==========================================================
CREATE TABLE kafka_logs (
                            log_id BIGSERIAL PRIMARY KEY,
                            topic_name VARCHAR(255),
                            message_id VARCHAR(255),
                            timestamp TIMESTAMP DEFAULT NOW(),
                            status VARCHAR(50),
                            created_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================================

CREATE INDEX idx_healthdata_user_id ON health_data(user_id);
CREATE INDEX idx_healthtrends_user_id ON health_trends(user_id);
CREATE INDEX idx_mlinsights_trend_id ON ml_insights(trend_id);
CREATE INDEX idx_recommendations_user_id ON recommendations(user_id);
CREATE INDEX idx_dev_user_id ON device(user_id);