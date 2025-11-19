package com.devgirls.healthmonitor.controller;

import com.devgirls.healthmonitor.dto.HealthDataDTO;
import com.devgirls.healthmonitor.kafka.producer.HealthDataKafkaProducer;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/ingest")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class IngestController {

    private final HealthDataKafkaProducer producer;
    private final ObjectMapper objectMapper;

    @PostMapping("/health-data")
    public ResponseEntity<?> ingest(@RequestBody HealthDataDTO dto) {
        try {
            if (dto.getUserId() == null) {
                return ResponseEntity.badRequest().body("userId must not be null");
            }

            String json = objectMapper.writeValueAsString(dto);
            producer.sendHealthData(json);

            log.info("Received health data from phone for user {} and sent to Kafka", dto.getUserId());

            return ResponseEntity.accepted().body(
                    java.util.Map.of(
                            "status", "sent_to_kafka",
                            "topic", "health_data",
                            "userId", dto.getUserId()
                    )
            );
        } catch (Exception e) {
            log.error("Failed to process phone health data", e);
            return ResponseEntity.internalServerError().body("Failed to send health data to Kafka");
        }
    }
}