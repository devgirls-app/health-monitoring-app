# Health Monitoring App — Documentation

## 1. Overview
The **Health Monitoring App** is a modular system that collects, processes, and visualizes healthcare data in real time. It integrates multiple components such as a backend service, a machine learning module, an iOS app, and Dockerized infrastructure.

This document describes the project’s setup and development steps up to the point where **Docker and Docker Compose** were added for the full application stack.

---

## 2. Project Structure
health-monitoring-app/
├── backend/ # Spring Boot backend with PostgreSQL and Kafka
├── ios/ # iOS mobile application
├── ml/ # Machine learning module
├── docs/ # Project documentation and diagrams
└── README.md # General overview

---

## 3. Backend Setup (Pre-Docker)
- Initialized a **Spring Boot project** (`healthmonitor`) using Maven.
- Configured `application.yaml` for local development.
- Added entities such as:
  - `User`
  - `HealthData`
  - `HealthTrends`
  - `Recommendations`
  - `KafkaLogs`
- Implemented services for Kafka producer and consumer.
- Added `HomeController` for API testing.

---

## 4. Database Integration
- Configured **PostgreSQL** connection in `application.yaml`.
- Created tables for storing users, health metrics, and ML insights.

---

## 5. Kafka Integration
- Integrated **Apache Kafka** for message streaming between backend modules.
- Added:
  - `KafkaProducer` for publishing messages.
  - `KafkaConsumer` for reading messages.
  - `KafkaTopicConfig` for topic management.

---

## 6. Adding Docker Support
### 6.1 Dockerfile
A `Dockerfile` was created in `backend/healthmonitor/` to containerize the Spring Boot application:
```dockerfile
FROM eclipse-temurin:21-jdk
WORKDIR /app
COPY target/healthmonitor-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
