package com.devgirls.healthmonitor.kafka.consumer;

import com.devgirls.healthmonitor.dto.HealthDataDTO;
import com.devgirls.healthmonitor.entity.HealthData;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.HealthDataRepository;
import com.devgirls.healthmonitor.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Service
public class HealthDataConsumer {

    private final HealthDataRepository healthDataRepo;
    private final UserRepository userRepo;
    private final ObjectMapper objectMapper;

    @Autowired
    public HealthDataConsumer(HealthDataRepository healthDataRepo, UserRepository userRepo, ObjectMapper objectMapper) {
        this.healthDataRepo = healthDataRepo;
        this.userRepo = userRepo;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "health_data", groupId = "health-group")
    public void consume(String message) {
        try {
            // Convert JSON to HealthDataDTO
            HealthDataDTO dto = objectMapper.readValue(message, HealthDataDTO.class);

            User user = userRepo.findById(dto.getUserId())
                    .orElseThrow(() -> new RuntimeException("User not found"));

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
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
