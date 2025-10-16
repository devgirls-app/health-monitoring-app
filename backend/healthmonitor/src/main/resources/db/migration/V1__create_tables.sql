-- ==========================================================
-- PostgreSQL Schema: Health Monitoring Application
-- ==========================================================

-- Drop tables if they already exist (in reverse dependency order)
DROP TABLE IF EXISTS KafkaLogs CASCADE;
DROP TABLE IF EXISTS Recommendations CASCADE;
DROP TABLE IF EXISTS MLInsights CASCADE;
DROP TABLE IF EXISTS HealthTrends CASCADE;
DROP TABLE IF EXISTS HealthData CASCADE;
DROP TABLE IF EXISTS Device CASCADE;
DROP TABLE IF EXISTS "User" CASCADE;

-- ==========================================================
-- Table: User
-- ==========================================================
CREATE TABLE "User" (
                        user_id SERIAL PRIMARY KEY,
                        name VARCHAR(255),
                        age INT,
                        gender VARCHAR(50),
                        height DECIMAL(5,2),
                        weight DECIMAL(5,2),
                        created_at TIMESTAMP DEFAULT NOW(),
                        updated_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================================
-- Table: Device
-- ==========================================================
CREATE TABLE Device (
                        device_id SERIAL PRIMARY KEY,
                        user_id INT REFERENCES "User"(user_id) ON DELETE CASCADE,
                        type VARCHAR(100),
                        os_version VARCHAR(100),
                        created_at TIMESTAMP DEFAULT NOW(),
                        updated_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================================
-- Table: HealthData
-- ==========================================================
CREATE TABLE HealthData (
                            data_id SERIAL PRIMARY KEY,
                            user_id INT REFERENCES "User"(user_id) ON DELETE CASCADE,
                            timestamp TIMESTAMP NOT NULL,
                            heart_rate INT,
                            steps INT,
                            calories DECIMAL(10,2),
                            sleep_hours DECIMAL(4,2),
                            source VARCHAR(50), -- e.g. iphone, kafka, manual
                            created_at TIMESTAMP DEFAULT NOW(),
                            updated_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================================
-- Table: HealthTrends
-- ==========================================================
CREATE TABLE HealthTrends (
                              trend_id SERIAL PRIMARY KEY,
                              user_id INT REFERENCES "User"(user_id) ON DELETE CASCADE,
                              avg_heart_rate DECIMAL(5,2),
                              daily_steps INT,
                              trend_label VARCHAR(255),
                              date DATE,
                              created_at TIMESTAMP DEFAULT NOW(),
                              updated_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================================
-- Table: MLInsights
-- ==========================================================
CREATE TABLE MLInsights (
                            insight_id SERIAL PRIMARY KEY,
                            trend_id INT REFERENCES HealthTrends(trend_id) ON DELETE CASCADE,
                            prediction_type VARCHAR(100), -- e.g. "stress_level", "activity_risk"
                            confidence_score DECIMAL(5,2),
                            result_description TEXT,
                            created_at TIMESTAMP DEFAULT NOW(),
                            updated_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================================
-- Table: Recommendations
-- ==========================================================
CREATE TABLE Recommendations (
                                 rec_id SERIAL PRIMARY KEY,
                                 user_id INT REFERENCES "User"(user_id) ON DELETE CASCADE,
                                 recommendation_text TEXT,
                                 source VARCHAR(50), -- e.g. "ML", "doctor", "system"
                                 created_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================================
-- Table: KafkaLogs
-- ==========================================================
CREATE TABLE KafkaLogs (
                           log_id SERIAL PRIMARY KEY,
                           topic_name VARCHAR(255),
                           message_id VARCHAR(255),
                           timestamp TIMESTAMP DEFAULT NOW(),
                           status VARCHAR(50),
                           created_at TIMESTAMP DEFAULT NOW()
);

-- ==========================================================
-- Indexes for performance (optional)
-- ==========================================================
CREATE INDEX idx_healthdata_user_id ON HealthData(user_id);
CREATE INDEX idx_healthtrends_user_id ON HealthTrends(user_id);
CREATE INDEX idx_mlinsights_trend_id ON MLInsights(trend_id);
CREATE INDEX idx_recommendations_user_id ON Recommendations(user_id);
CREATE INDEX idx_dev_user_id ON Device(user_id);