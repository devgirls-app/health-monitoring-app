package com.devgirls.healthmonitor.kafka.consumer;

import com.devgirls.healthmonitor.dto.HealthDataDTO;
import com.devgirls.healthmonitor.entity.HealthData;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.HealthDataRepository;
import com.devgirls.healthmonitor.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Service
@RequiredArgsConstructor
@Slf4j
public class HealthDataKafkaConsumer {

    private final HealthDataRepository healthDataRepo;
    private final UserRepository userRepo;
    private final ObjectMapper objectMapper;

    @KafkaListener(topics = "health_data", groupId = "health-group")
    public void consume(String message) {
        try {
            HealthDataDTO dto = objectMapper.readValue(message, HealthDataDTO.class);

            if (dto.getUserId() == null) {
                log.warn("Received health_data message without userId: {}", message);
                return;
            }

            User user = userRepo.findById(dto.getUserId())
                    .orElseThrow(() -> new RuntimeException("User not found with id " + dto.getUserId()));

            HealthData healthData = HealthData.builder()
                    .timestamp(dto.getTimestamp())
                    .heartRate(dto.getHeartRate())
                    .steps(dto.getSteps())
                    .calories(dto.getCalories() != null ? BigDecimal.valueOf(dto.getCalories()) : null)
                    .sleepHours(dto.getSleepHours() != null ? BigDecimal.valueOf(dto.getSleepHours()) : null)
                    .source(dto.getSource())
                    .user(user)
                    .build();

            healthDataRepo.save(healthData);
            log.info("HealthData saved from Kafka for user {} at {}", dto.getUserId(), dto.getTimestamp());
        } catch (Exception e) {
            log.error("Error processing Kafka health_data message: {}", message, e);
        }
    }
}