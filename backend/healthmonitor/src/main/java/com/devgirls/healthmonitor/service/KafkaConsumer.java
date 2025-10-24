package com.devgirls.healthmonitor.service;

<<<<<<< HEAD
import com.devgirls.healthmonitor.dto.HealthDataDTO;
import com.devgirls.healthmonitor.entity.HealthData;
import com.devgirls.healthmonitor.entity.User;
import com.devgirls.healthmonitor.repository.HealthDataRepository;
import com.devgirls.healthmonitor.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
=======
>>>>>>> origin/ios-full-restore
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
public class KafkaConsumer {

<<<<<<< HEAD
    private final HealthDataRepository healthDataRepo;
    private final UserRepository userRepo;
    private final ObjectMapper objectMapper;

    @Autowired
    public KafkaConsumer(HealthDataRepository healthDataRepo, UserRepository userRepo, ObjectMapper objectMapper) {
        this.healthDataRepo = healthDataRepo;
        this.userRepo = userRepo;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = "health_data", groupId = "health-group")
    public void consume(String message) {
        try {
            HealthDataDTO dto = objectMapper.readValue(message, HealthDataDTO.class);
            if (dto.getUserId() == null) {
                System.out.println("Получено сообщение без userId: " + message);
                return;
            }

            User user = userRepo.findById(dto.getUserId())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            HealthData healthData = HealthData.builder()
                    .timestamp(dto.getTimestamp())
                    .heartRate(dto.getHeartRate())
                    .steps(dto.getSteps())
                    .calories(dto.getCalories())
                    .sleepHours(dto.getSleepHours())
                    .source(dto.getSource())
                    .user(user)
                    .build();

            healthDataRepo.save(healthData);
            System.out.println("HealthData успешно сохранено для пользователя " + dto.getUserId());
        } catch (Exception e) {
            System.out.println("Ошибка при обработке Kafka-сообщения: " + message);
            e.printStackTrace();
        }
=======
    @KafkaListener(topics = "health_data", groupId = "health-group")
    public void consumeHealthData(String message) {
        System.out.println("Received health_data: " + message);
    }

    @KafkaListener(topics = "alerts", groupId = "health-group")
    public void consumeAlerts(String message) {
        System.out.println("Received alert: " + message);
>>>>>>> origin/ios-full-restore
    }
}