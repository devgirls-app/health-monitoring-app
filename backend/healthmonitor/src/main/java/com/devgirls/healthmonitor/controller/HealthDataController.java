package com.devgirls.healthmonitor.controller;

import com.devgirls.healthmonitor.dto.HealthDataDTO;
import com.devgirls.healthmonitor.kafka.producer.HealthDataProducer; // Предполагаем, что это ваш правильный продюсер
import com.devgirls.healthmonitor.service.HealthDataService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/healthdata")
public class HealthDataController {

    // --- ПРАВИЛЬНЫЕ ЗАВИСИМОСТИ ---
    // Контроллеру нужен только сервис, продюсер и маппер
    private final HealthDataService healthDataService;
    private final HealthDataProducer healthDataProducer;
    private final ObjectMapper objectMapper;

    @Autowired
    public HealthDataController(HealthDataService healthDataService, HealthDataProducer healthDataProducer, ObjectMapper objectMapper) {
        this.healthDataService = healthDataService;
        this.healthDataProducer = healthDataProducer;
        this.objectMapper = objectMapper;
    }

    @PostMapping
    public ResponseEntity<String> createData(@RequestBody HealthDataDTO dto) {
        try {
            // Преобразуем DTO в JSON-строку
            String jsonMessage = objectMapper.writeValueAsString(dto);

            // Отправляем JSON в Kafka
            healthDataProducer.sendHealthData(jsonMessage);

            // Возвращаем осмысленный ответ об успехе
            return ResponseEntity.status(HttpStatus.ACCEPTED).body("Health data accepted and sent for processing.");

        } catch (Exception e) {
            e.printStackTrace(); // Оставляем для логов на сервере
            // Возвращаем клиенту ошибку 500
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Error processing health data.");
        }
    }

    @GetMapping
    public ResponseEntity<List<HealthDataDTO>> getAllHealthData() {
        // Этот метод у вас был написан правильно
        List<HealthDataDTO> data = healthDataService.findAllHealthData();
        return ResponseEntity.ok(data);
    }
}